#!/usr/bin/env python3
"""Snapshot GitHub Release asset download counts for this chart repository.

Writes, under OUT_DIR:
  daily/<YYYY-MM-DD>.csv   one row per release asset (cumulative counts)
  summary.csv              one row per chart per day, appended (date,chart,downloads,delta)

Prints a Markdown report to stdout for the job summary.

GitHub only exposes cumulative counts per asset, so daily downloads are the
difference between consecutive snapshots. Counts are not attributable to users.
"""

import csv
import datetime as dt
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

REPO = os.environ.get("GITHUB_REPOSITORY", "nirmata/kyverno-charts")
OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else "stats"
TAG_RE = re.compile(r"^(?P<chart>.+?)-(?P<version>v?\d.*)$")


def fetch_releases():
    out = subprocess.run(
        ["gh", "api", "--paginate", "--jq", ".[]", f"repos/{REPO}/releases?per_page=100"],
        check=True, capture_output=True, text=True,
    ).stdout
    return [json.loads(line) for line in out.splitlines() if line]


def main():
    today = dt.datetime.now(dt.timezone.utc).date().isoformat()
    rows = []
    for rel in fetch_releases():
        m = TAG_RE.match(rel["tag_name"])
        chart, version = (m["chart"], m["version"]) if m else (rel["tag_name"], "")
        for asset in rel["assets"]:
            rows.append({
                "date": today,
                "chart": chart,
                "version": version,
                "prerelease": rel["prerelease"],
                "asset": asset["name"],
                "downloads": asset["download_count"],
            })

    os.makedirs(os.path.join(OUT_DIR, "daily"), exist_ok=True)
    with open(os.path.join(OUT_DIR, "daily", f"{today}.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)

    totals = defaultdict(int)
    for r in rows:
        totals[r["chart"]] += r["downloads"]

    summary_path = os.path.join(OUT_DIR, "summary.csv")
    previous, history = {}, []
    if os.path.exists(summary_path):
        with open(summary_path, newline="") as f:
            history = [r for r in csv.DictReader(f) if r["date"] != today]
        last_date = max((r["date"] for r in history), default=None)
        previous = {r["chart"]: int(r["downloads"]) for r in history if r["date"] == last_date}

    new_rows = [
        {
            "date": today,
            "chart": chart,
            "downloads": total,
            "delta": total - previous[chart] if chart in previous else "",
        }
        for chart, total in sorted(totals.items())
    ]
    with open(summary_path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["date", "chart", "downloads", "delta"])
        w.writeheader()
        w.writerows(history + new_rows)

    print(f"## Release downloads — {today}\n")
    print("| Chart | Total | Since last snapshot |")
    print("|---|---:|---:|")
    for r in sorted(new_rows, key=lambda r: -r["downloads"]):
        print(f"| {r['chart']} | {r['downloads']:,} | {r['delta'] if r['delta'] != '' else '—'} |")


if __name__ == "__main__":
    main()
