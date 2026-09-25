#!/usr/bin/env python3
"""Read the Lutris local library (pga.db) and emit a JSON list of installed games.

Lutris stores its database at $XDG_DATA_HOME/lutris/pga.db (legacy installs:
~/.config/lutris/pga.db). This script only reads; the DB is opened read-only
so it is safe while Lutris itself is running.
"""
import json
import os
import sqlite3
import sys


def find_data_dir() -> str:
    xdg = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    candidates = [
        os.environ.get("LUTRIS_DIR", ""),
        os.path.join(xdg, "lutris"),
        os.path.expanduser("~/.config/lutris"),
    ]
    for d in candidates:
        if d and os.path.isdir(d):
            return d
    return os.path.join(xdg, "lutris")


def first_existing(base: str, slug: str) -> str:
    for ext in (".jpg", ".png"):
        path = os.path.join(base, slug + ext)
        if os.path.isfile(path):
            return path
    return ""


def main() -> None:
    data_dir = find_data_dir()
    db_path = os.path.join(data_dir, "pga.db")
    cover_dir = os.path.join(data_dir, "coverart")
    banner_dir = os.path.join(data_dir, "banners")
    icon_dir = os.path.join(data_dir, "icons")

    games = []
    if not os.path.isfile(db_path):
        print(json.dumps({"error": "no pga.db found", "dir": data_dir}))
        return

    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT name, slug, runner, platform, installed, playtime, lastplayed,
                   year, directory, executable
            FROM games
            WHERE installed = 1
              AND id NOT IN (
                  SELECT gc.game_id
                  FROM games_categories gc
                  INNER JOIN categories c ON c.id = gc.category_id
                  WHERE c.name = '.hidden' COLLATE NOCASE
              )
            ORDER BY COALESCE(lastplayed, 0) DESC
            """
        ).fetchall()
        for r in rows:
            slug = r["slug"] or ""
            cover = first_existing(cover_dir, slug)
            if not cover:
                cover = first_existing(banner_dir, slug)
            if not cover:
                cover = first_existing(icon_dir, slug)
            banner = first_existing(banner_dir, slug)
            games.append(
                {
                    "name": r["name"] or slug,
                    "slug": slug,
                    "runner": r["runner"] or "",
                    "platform": r["platform"] or "",
                    "playtime": round(r["playtime"] or 0, 1),
                    "lastplayed": r["lastplayed"] or 0,
                    "year": r["year"],
                    "directory": r["directory"] or "",
                    "executable": r["executable"] or "",
                    "cover": cover,
                    "banner": banner,
                }
            )
        conn.close()
    except Exception as exc:  # noqa: BLE001 - report and degrade gracefully
        print(json.dumps({"error": str(exc), "dir": data_dir}))
        return

    print(json.dumps(games))


if __name__ == "__main__":
    main()