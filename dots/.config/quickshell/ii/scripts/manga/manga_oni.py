#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""MangaOni provider for the ii manga tab.

Scrapes manga-oni.com (Spanish manga reader) behind a CLI that speaks JSON,
mirroring the mangadex/mangalib provider interface used by ArchEclipse:

  --popular                 latest updated manga from the homepage
  --search <query>          site search (/buscar/?q=)
  --id <slug>               single manga details
  --chapters --manga-id <slug>           chapter list from /manga/<slug>/
  --pages   --chapter-id <slug>/<id>     page urls from /lector/<slug>/<id>/
  --page <url>              download a single page and report local path/dims

Covers and pages are cached under ~/.cache/ii/manga/manga-oni/{covers,pages}.
"""

from __future__ import annotations

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass
import hashlib
import html as html_module
import json
import os
from pathlib import Path
import re
import sys

import requests
from bs4 import BeautifulSoup
from PIL import Image

BASE_URL = "https://manga-oni.com"
CDN_BASE = "https://oni.ntr-files.online"
CACHE_BASE = Path.home() / ".cache" / "ii" / "manga" / "manga-oni"
COVERS_DIR = CACHE_BASE / "covers"
PAGES_DIR = CACHE_BASE / "pages"

BROWSER_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

TYPE_LABELS = {
    "manga": "Manga",
    "manhua": "Manhua",
    "manhwa": "Manhwa",
    "comic": "Cómic",
    "lector": "Manga",
}


@dataclass
class Manga:
    provider: str
    id: str
    title: str
    description: str
    tags: list
    year: object
    status: str
    cover_url: str = None
    cover_path: str = None
    cover_height: int = None
    cover_width: int = None
    date: str = ""

    def to_json(self) -> dict:
        return asdict(self)


@dataclass
class Chapter:
    id: str
    title: str
    chapter: str = None
    volume: str = None
    pages: int = None
    publish_date: str = None
    user: str = ""

    def to_json(self) -> dict:
        return asdict(self)


@dataclass
class Page:
    url: str
    path: str = None
    height: int = None
    width: int = None

    def to_json(self) -> dict:
        return asdict(self)


class MangaOniProvider:
    name = "manga-oni"

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": BROWSER_UA,
                "Referer": BASE_URL + "/",
                "Accept": "*/*",
            }
        )
        COVERS_DIR.mkdir(parents=True, exist_ok=True)
        PAGES_DIR.mkdir(parents=True, exist_ok=True)

    # ---------- low level ----------

    def _headers(self) -> dict:
        return {
            "User-Agent": BROWSER_UA,
            "Referer": BASE_URL + "/",
            "Accept": "*/*",
        }

    def _fetch(self, path: str, params: dict | None = None) -> str:
        url = path if path.startswith("http") else BASE_URL + path
        r = self.session.get(url, params=params, timeout=25)
        r.raise_for_status()
        return r.text

    def _soup(self, path: str, params: dict | None = None):
        return BeautifulSoup(self._fetch(path, params), "html.parser")

    def _image_ext(self, url: str, content_type: str = "") -> str:
        ext = os.path.splitext(url.split("?")[0])[1].lower()
        if ext in {".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif"}:
            return ext
        if content_type:
            ct = content_type.split(";")[0].lower()
            if "png" in ct:
                return ".png"
            if "webp" in ct:
                return ".webp"
            if "jpeg" in ct or "jpg" in ct:
                return ".jpg"
            if "gif" in ct:
                return ".gif"
        return ".jpg"

    def _download(self, url: str, dest: Path) -> Path | None:
        if dest.exists():
            return dest
        r = requests.get(url, headers=self._headers(), timeout=30)
        r.raise_for_status()
        dest.write_bytes(r.content)
        return dest

    def _img_size(self, path: Path):
        try:
            with Image.open(path) as img:
                return img.size
        except Exception:
            return None, None

    def _cover_local(self, slug: str) -> Path | None:
        for p in COVERS_DIR.glob(slug + ".*"):
            return p
        return None

    def _ensure_cover(self, slug: str, cover_url: str) -> tuple:
        local = self._cover_local(slug)
        if not local and cover_url:
            ext = self._image_ext(cover_url)
            local = self._download(cover_url, COVERS_DIR / (slug + ext))
        if local:
            w, h = self._img_size(local)
            return str(local), w, h
        return None, None, None

    # ---------- scraping ----------

    def _slug(self, url: str) -> str | None:
        m = re.search(r"/(?:lector|manga|manhua|manhwa|comic|oneshot)/([^/?#]+)/", url)
        return m.group(1) if m else None

    def _parse_card(self, card) -> Manga | None:
        a = card.select_one("a[itemprop='url']")
        if a is None:
            return None
        href = a.get("href", "") or ""
        slug = self._slug(href)
        if not slug:
            return None
        kind = re.search(r"/(lector|manga|manhua|manhwa|comic|oneshot)/", href)
        content_type = kind.group(1) if kind else "manga"
        if content_type == "oneshot":
            return None

        img = a.find("img")
        cover_url = ""
        if img:
            cover_url = img.get("data-src") or img.get("src") or ""
            if not img.get("data-src") and cover_url and "default.gif" in cover_url:
                cover_url = ""
        title = (img.get("alt", "") if img else "").strip()

        node = card.select_one("._2uHIS")
        if node:
            title = node.get_text(" ", strip=True) or title

        date = ""
        t = card.select_one(".timeago")
        if t is not None:
            date = t.get("datetime", "") or ""
        if not date:
            date = card.get("datetime", "") or ""

        return Manga(
            provider=self.name,
            id=slug,
            title=title or slug,
            description="",
            tags=[TYPE_LABELS.get(content_type, content_type)],
            year=None,
            status="",
            cover_url=cover_url,
            date=date,
        )

    def _parse_list(self, soup, limit: int) -> list:
        seen = set()
        items = []
        for card in soup.select("div._135yj"):
            if len(items) >= limit:
                break
            item = self._parse_card(card)
            if not item or item.id in seen:
                continue
            seen.add(item.id)
            items.append(item)

        with ThreadPoolExecutor(max_workers=6) as pool:
            results = list(pool.map(self._ensure_cover, (i.id for i in items), (i.cover_url for i in items)))
        for item, (local, w, h) in zip(items, results):
            item.cover_path = local
            item.cover_width = w
            item.cover_height = h
        return items

    # ---------- provider API ----------

    def search(self, query: str, limit: int, offset: int) -> list:
        soup = self._soup("/buscar/", params={"q": query})
        items = self._parse_list(soup, limit + offset)
        return items[offset:]

    def popular(self, limit: int, offset: int) -> list:
        soup = self._soup("/")
        items = self._parse_list(soup, limit + offset)
        return items[offset:]

    def get_by_id(self, slug: str) -> Manga:
        raw = self._fetch("/manga/" + slug + "/")
        soup = BeautifulSoup(raw, "html.parser")

        h1 = soup.find("h1")
        title = h1.get_text(" ", strip=True) if h1 else slug

        cover_url = ""
        img = soup.find(
            "img", src=lambda v: v and "/mangas/" + slug + "/cover" in v
        ) or soup.find(
            "img",
            attrs={"data-src": lambda v: v and "/mangas/" + slug + "/cover" in v},
        )
        if img:
            cover_url = img.get("data-src") or img.get("src")

        desc_node = soup.select_one("#sinopsis")
        description = ""
        if desc_node is not None:
            description = desc_node.get_text(" ", strip=True)
            description = re.sub(r"^Sinopsis\s*", "", description).strip()

        author = year = status = ""
        m = re.search(r"Autor:</strong>\s*(.*?)<", raw)
        if m:
            author = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        m = re.search(r"Fecha:</strong>\s*(.*?)<", raw)
        if m:
            year = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        m = re.search(r"Estado:</strong>(.*?)<br", raw, re.S)
        if m:
            status = re.sub(r"<[^>]+>", " ", m.group(1)).replace("&nbsp;", "").strip()

        tags = []
        for m in re.finditer(r'title="Clic para ver más mangas de ([^"]+)"', raw):
            tag = html_module.unescape(m.group(1)).strip()
            if tag and tag not in tags:
                tags.append(tag)

        local, w, h = self._ensure_cover(slug, cover_url)

        return Manga(
            provider=self.name,
            id=slug,
            title=title,
            description=description,
            tags=tags,
            year=year if year else None,
            status=status,
            cover_url=cover_url,
            cover_path=local,
            cover_width=w,
            cover_height=h,
        )

    def get_chapters(self, manga_id: str) -> list:
        soup = self._soup("/manga/" + manga_id + "/")
        chapters = []
        seen = set()
        for a in soup.select("#c_list a"):
            href = a.get("href", "")
            m = re.search(r"/lector/[^/]+/(\d+)/", href)
            if not m:
                continue
            cid = m.group(1)
            if cid in seen:
                continue
            seen.add(cid)
            span = a.find(class_="timeago")
            title = ""
            h3 = a.find("h3")
            if h3:
                title = h3.get_text(" ", strip=True)
            chapters.append(
                Chapter(
                    id=f"{manga_id}/{cid}",
                    title=title,
                    chapter=span.get("data-num", "") if span else "",
                    publish_date=span.get("datetime", "") if span else "",
                    user=span.get("data-user", "") if span else "",
                )
            )
        return chapters

    def get_pages(self, chapter_id: str) -> list:
        parts = chapter_id.rsplit("/", 1)
        if len(parts) != 2:
            raise ValueError("chapter id must be '<slug>/<id>'")
        slug, cid = parts
        raw = self._fetch(f"/lector/{slug}/{cid}/")
        m = re.search(r"var unicap\s*=\s*['\"]([^'\"]+)['\"]", raw)
        if not m:
            raise ValueError("could not find page data (unicap) in lector page")

        decoded = base64.b64decode(m.group(1)).decode("utf-8", errors="replace")
        fields = decoded.split("||")
        pages_dir = fields[0]
        page_list = fields[1] if len(fields) > 1 else ""
        filenames = (
            page_list.replace('["', "")
            .replace('"]', "")
            .split('","')
            if page_list and page_list != "[]"
            else []
        )
        pages = [Page(url=pages_dir + fn) for fn in filenames if fn]
        if not pages:
            raise ValueError("chapter has no pages")
        return pages

    def get_page(self, page_url: str) -> Page:
        url_hash = hashlib.md5(page_url.encode()).hexdigest()
        ext = self._image_ext(page_url)
        filepath = PAGES_DIR / (url_hash + ext)
        self._download(page_url, filepath)
        w, h = self._img_size(filepath)
        return Page(url=page_url, path=str(filepath), width=w, height=h)


def main():
    parser = argparse.ArgumentParser(description="MangaOni CLI (Quickshell friendly)")
    parser.add_argument("--provider", default="manga-oni")
    parser.add_argument("--search", help="Search manga by title")
    parser.add_argument("--popular", action="store_true", help="Recent manga updates")
    parser.add_argument("--id", help="Get manga details by slug")
    parser.add_argument("--chapters", action="store_true", help="Get chapters")
    parser.add_argument("--manga-id", help="Manga slug for chapters")
    parser.add_argument("--pages", action="store_true", help="Get pages for chapter")
    parser.add_argument("--chapter-id", help="Chapter id '<slug>/<id>' for pages")
    parser.add_argument("--page", help="Download a single page by URL")
    parser.add_argument("--index", help="Page index echoed back into the JSON output")
    parser.add_argument("--limit", type=int, default=12)
    parser.add_argument("--offset", type=int, default=0)
    args = parser.parse_args()

    provider = MangaOniProvider()

    def emit(obj):
        print(json.dumps(obj, ensure_ascii=False))

    try:
        if args.id:
            emit(provider.get_by_id(args.id).to_json())
        elif args.search:
            emit([m.to_json() for m in provider.search(args.search, args.limit, args.offset)])
        elif args.popular:
            emit([m.to_json() for m in provider.popular(args.limit, args.offset)])
        elif args.chapters:
            if not args.manga_id:
                emit({"error": "Manga id required for chapters"})
                sys.exit(1)
            emit([c.to_json() for c in provider.get_chapters(args.manga_id)])
        elif args.pages:
            if not args.chapter_id:
                emit({"error": "Chapter id required for pages"})
                sys.exit(1)
            emit([p.to_json() for p in provider.get_pages(args.chapter_id)])
        elif args.page:
            if not args.page.startswith("http"):
                emit({"error": "Valid page URL required"})
                sys.exit(1)
            data = provider.get_page(args.page).to_json()
            if args.index is not None:
                data["key"] = args.index
            emit(data)
        else:
            emit({"error": "No action provided"})
            sys.exit(1)
    except Exception as e:  # noqa: BLE001
        emit({"error": str(e)})
        sys.exit(2)


if __name__ == "__main__":
    main()