import json
import os
import sys
import time
import requests

WAIT_SECONDS = 2.0


def download_thumbs(base_path: str) -> None:
    with open("internal_research.json") as f:
        entries = json.load(f)

    entries_with_thumb = [e for e in entries if e.get("thumb")]
    total = len(entries_with_thumb)
    print(f"Found {total} entries with a thumb (out of {len(entries)} total)")

    success = 0
    skipped = 0
    failed = 0

    for i, entry in enumerate(entries_with_thumb):
        expo_id = str(entry["id"])
        thumb_url = entry["thumb"]
        dest_dir = os.path.join(base_path, expo_id)
        dest_path = os.path.join(dest_dir, "thumb.png")

        if os.path.exists(dest_path):
            print(f"[{i+1}/{total}] skip  {expo_id} (already exists)")
            skipped += 1
            continue

        os.makedirs(dest_dir, exist_ok=True)

        try:
            response = requests.get(thumb_url, timeout=15)
            response.raise_for_status()
            with open(dest_path, "wb") as f:
                f.write(response.content)
            print(f"[{i+1}/{total}] ok    {expo_id}")
            success += 1
        except Exception as e:
            print(f"[{i+1}/{total}] FAIL  {expo_id}: {e}")
            failed += 1

        time.sleep(WAIT_SECONDS)

    print(f"\nDone. success={success}  skipped={skipped}  failed={failed}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <destination-path>")
        sys.exit(1)

    base_path = sys.argv[1]
    download_thumbs(base_path)
