#!/usr/bin/env python3
"""Wait until a game window appears after "lutris lutris:rungame/<slug>".

Polls `hyprctl -j clients` every second and prints STARTED <title> as soon as
a client title/class contains the game name (or any of its words with >= 4
characters). If nothing shows up within the timeout it prints TIMEOUT. Exit
code is 0 in both cases so the QML side only needs to read the first token.
"""
import json
import shlex
import subprocess
import sys
import time


def poll_clients() -> str | None:
    try:
        out = subprocess.run(
            ["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=3
        ).stdout
        return out
    except (subprocess.SubprocessError, OSError):
        return None


def main() -> None:
    name = sys.argv[1] if len(sys.argv) > 1 else ""
    timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 25.0

    keywords = []
    if name:
        lowered = name.lower()
        keywords.append(lowered)
        keywords.extend(w for w in lowered.split() if len(w) >= 4)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        raw = poll_clients()
        if raw:
            try:
                clients = json.loads(raw)
            except (ValueError, TypeError):
                clients = []
            for client in clients or []:
                hay = f"{client.get('title') or ''} {client.get('class') or ''}".lower()
                if isinstance(hay, str) and any(k in hay for k in keywords):
                    print(f"STARTED {(client.get('title') or '')[:120]}")
                    return
        time.sleep(1)

    print("TIMEOUT")


if __name__ == "__main__":
    main()