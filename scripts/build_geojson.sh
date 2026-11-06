#!/usr/bin/env bash
# Build data/fatal-crashes.geojson and data/summary.json from the source parquet.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARQUET="${1:-$ROOT/MotorVehicleCollisionsCrashes_201609_202609.parquet}"
OUT="$ROOT/data/fatal-crashes.geojson"
SUMMARY="$ROOT/data/summary.json"
SQL_TEMPLATE="$ROOT/scripts/build_geojson.sql"
WRAPPED="$ROOT/data/.fatal-crashes.wrapped.json"

if [[ ! -f "$PARQUET" ]]; then
  echo "Parquet not found: $PARQUET" >&2
  exit 1
fi

mkdir -p "$ROOT/data"
SQL="$(mktemp)"
sed \
  -e "s|__PARQUET__|${PARQUET}|g" \
  -e "s|__OUT__|${WRAPPED}|g" \
  "$SQL_TEMPLATE" > "$SQL"

duckdb -c ".read $SQL"
rm -f "$SQL"

python3 - "$WRAPPED" "$OUT" "$SUMMARY" << 'PY'
import json
import sys

wrapped_path, out_path, summary_path = sys.argv[1:4]
with open(wrapped_path) as handle:
    wrapped = json.load(handle)

collection = wrapped["collection"]
features = collection["features"]
if not features:
    raise SystemExit("No fatal crashes were exported.")

counts = {"pedestrian": 0, "cyclist": 0, "motorist": 0, "other": 0}
killed = 0
dates = []
for feature in features:
    props = feature["properties"]
    victim = props["victim"]
    if victim not in counts:
        raise SystemExit(f"Unexpected victim class: {victim}")
    counts[victim] += 1
    killed += props["killed"]
    dates.append(props["date"])
    lon, lat = feature["geometry"]["coordinates"]
    if not (-74.3 <= lon <= -73.6 and 40.4 <= lat <= 41.0):
        raise SystemExit(f"Coordinate outside New York City: {lon}, {lat}")

summary = {
    "crashes": len(features),
    "killed": killed,
    "from": min(dates),
    "to": max(dates),
    "by_victim": counts,
    "filter": "persons_killed >= 1",
    "source": "NYC Open Data, Motor Vehicle Collisions — Crashes",
}

with open(out_path, "w") as handle:
    json.dump(collection, handle, separators=(",", ":"))
    handle.write("\n")
with open(summary_path, "w") as handle:
    json.dump(summary, handle, indent=2)
    handle.write("\n")

print(
    f"Wrote {len(features)} crashes, {killed} people killed, "
    f"{summary['from']} to {summary['to']}"
)
print(counts)
PY

rm -f "$WRAPPED"
