#!/usr/bin/env sh
set -eu

# Usage: convert.sh INPUT OUTPUT FORMAT TILE_SIZE RIO_WORKERS PMTILES_CO NAME DESCRIPTION ATTRIBUTION
# Any argument can be empty; sensible defaults are used where appropriate.

INPUT=${1:-data/5ea338e5c70abb0005869e8f.tif}
OUTPUT=${2:-output/abidjan-2019.pmtiles}
FORMAT=${3:-WEBP}
TILE_SIZE=${4:-512}
RIO_WORKERS=${5:-}
PMTILES_CO=${6:-}
NAME=${7:-"Maxar 2019 Abidjan Mosaic"}
DESCRIPTION=${8:-"Maxar 2019 Abidjan Mosaic by Cristiano Giovando"}
ATTRIBUTION=${9:-"© Maxar - CC BY-NC 4.0"}

echo "Converting $INPUT -> $OUTPUT"

if [ ! -f "$INPUT" ]; then
  echo "Error: input file not found: $INPUT" >&2
  exit 1
fi

# Count bands if gdalinfo is available
BANDS=0
if command -v gdalinfo >/dev/null 2>&1; then
  BANDS=$(gdalinfo "$INPUT" 2>/dev/null | grep -E "^Band [0-9]+" -c || true)
else
  echo "Warning: gdalinfo not found; skipping band-count check. Proceeding with conversion." >&2
  BANDS=3
fi

if [ -z "$BANDS" ] || [ "$BANDS" -lt 3 ]; then
  echo "Error: input has less than 3 bands ($BANDS). rio pmtiles requires at least 3 bands." >&2
  exit 1
fi

RGBA_FLAG=""
if [ "$BANDS" -ge 4 ]; then
  echo "Input has $BANDS bands; enabling alpha (--rgba)."
  RGBA_FLAG="--rgba"
fi

# Build --co flags
CO_FLAGS=""
if [ -n "$PMTILES_CO" ]; then
  for kv in $PMTILES_CO; do
    CO_FLAGS="$CO_FLAGS --co $kv"
  done
fi

# Build workers flag
WORKERS_FLAG=""
if [ -n "$RIO_WORKERS" ]; then
  WORKERS_FLAG="-j $RIO_WORKERS"
fi

echo "Running: rio pmtiles -f $FORMAT $RGBA_FLAG --tile-size $TILE_SIZE $CO_FLAGS $WORKERS_FLAG"

rio pmtiles "$INPUT" "$OUTPUT" -f "$FORMAT" $RGBA_FLAG --tile-size "$TILE_SIZE" $CO_FLAGS $WORKERS_FLAG \
  --name "$NAME" --description "$DESCRIPTION" --attribution "$ATTRIBUTION"

echo "Conversion finished: $OUTPUT"
