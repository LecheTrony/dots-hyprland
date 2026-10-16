#!/usr/bin/env python3
import sys
import time
import re
import urllib.request
import urllib.parse
import json

API = "https://lrclib.net/api"
USER_AGENT = "dots-hyprland-quickshell-lyrics/1.0 (https://github.com/end-4/dots-hyprland)"
TIMEOUT = 10
ATTEMPTS = 2
DURATION_TOLERANCE = 5.0
DEADLINE = time.time() + 25.0


def _http_json(url):
    for attempt in range(ATTEMPTS):
        if time.time() > DEADLINE:
            return None
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            time.sleep(0.7 * (attempt + 1))
        except Exception:
            time.sleep(0.7 * (attempt + 1))
    return None


def _parse_lrc(lrc_text):
    lines = []
    tag_re = re.compile(r"\[(\d+):(\d+(?:\.\d+)?)\]")
    for raw in lrc_text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        tags = tag_re.findall(raw)
        if not tags:
            continue
        text = tag_re.sub("", raw).strip()
        for mins, secs in tags:
            try:
                timestamp = int(mins) * 60 + float(secs)
            except Exception:
                continue
            lines.append({"time": timestamp, "text": text})
    lines.sort(key=lambda x: x["time"])
    return lines


def _plain_to_lines(plain_text):
    lines = []
    for raw in plain_text.splitlines():
        lines.append({"time": -1.0, "text": raw.strip()})
    return lines


def _norm(s):
    return (s or "").strip().lower()


def _similar(query, candidate):
    q = _norm(query)
    c = _norm(candidate)
    if not q or not c:
        return False
    if q == c or q in c or c in q:
        return True
    words = [w for w in re.split(r"\s+", q) if len(w) > 2]
    return any(w in c for w in words)


def _dur_diff(a, b):
    try:
        a = float(a)
        b = float(b)
    except Exception:
        return None
    if a <= 0 or b <= 0:
        return None
    return abs(a - b)


def _candidate_queries(title, artist, duration):
    q = urllib.parse.quote
    d = int(duration) if duration and duration > 0 else 0
    queries = []
    if d:
        queries.append(f"{API}/get?track_name={q(title)}&artist_name={q(artist)}&duration={d}")
    queries.append(f"{API}/search?track_name={q(title)}&artist_name={q(artist)}")
    queries.append(f"{API}/search?track_name={q(title)}")
    if artist:
        queries.append(f"{API}/search?q={q(title + ' ' + artist)}")
    queries.append(f"{API}/search?q={q(title)}")
    return queries


def _pick(candidates, title, artist, duration, require_artist):
    best = None
    best_score = -1
    for d in candidates:
        if not isinstance(d, dict):
            continue
        title_ok = _similar(title, d.get("trackName"))
        artist_ok = _similar(artist, d.get("artistName")) if artist else True
        diff = _dur_diff(duration, d.get("duration"))
        dur_ok = diff is not None and diff <= DURATION_TOLERANCE
        if require_artist and not (title_ok and artist_ok):
            continue
        if not title_ok and not dur_ok:
            continue
        if not d.get("syncedLyrics") and not d.get("plainLyrics"):
            continue
        score = (2 if title_ok else 0) + (1 if artist_ok else 0)
        if dur_ok:
            score += 2 - (diff / max(DURATION_TOLERANCE, 1))
        if score > best_score:
            best_score = score
            best = d
    return best


def fetch_lrclib(title, artist, duration):
    for i, url in enumerate(_candidate_queries(title, artist, duration)):
        data = _http_json(url)
        if data is None:
            continue
        if isinstance(data, dict):
            data = [data] if data else []
        if not isinstance(data, list):
            continue
        require_artist = i <= 1
        d = _pick(data, title, artist, duration, require_artist)
        if not d:
            continue
        if d.get("syncedLyrics"):
            lines = _parse_lrc(d["syncedLyrics"])
            if lines:
                return lines
        if d.get("plainLyrics"):
            lines = _plain_to_lines(d["plainLyrics"])
            if lines:
                return lines
    return []


def main():
    if len(sys.argv) < 4:
        print("no_info", flush=True)
        sys.exit(0)
    title = sys.argv[1]
    artist = sys.argv[2]
    try:
        duration = float(sys.argv[3])
    except Exception:
        duration = 0.0
    if not title or not artist:
        print("no_info", flush=True)
        sys.exit(0)
    lines = fetch_lrclib(title, artist, duration)
    if not lines:
        print("not_found", flush=True)
        sys.exit(0)
    synced = lines[0]["time"] >= 0
    parts = []
    for line in lines:
        parts.append(str(line["time"]))
        parts.append(line["text"].replace("§", ""))
    parts.append("ok" if synced else "plain")
    print("§".join(parts), flush=True)


if __name__ == "__main__":
    main()
