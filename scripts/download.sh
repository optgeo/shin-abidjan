#!/usr/bin/env sh
set -eu

# Usage: download.sh [GEOTIFF_FILE] [GEOTIFF_URL] [ARIA_CONNECTIONS]
# If arguments are omitted, sensible defaults are used (matching the Makefile).

GEOTIFF_FILE=${1:-data/5ea338e5c70abb0005869e8f.tif}
GEOTIFF_URL=${2:-https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif}
ARIA_CONNECTIONS=${3:-16}

# Ensure parent dir exists
mkdir -p "$(dirname "$GEOTIFF_FILE")"

if [ -f "$GEOTIFF_FILE" ]; then
  echo "GeoTIFF file already exists. Skipping download.";
  exit 0
fi

if command -v aria2c >/dev/null 2>&1; then
  echo "Using aria2c to download: $GEOTIFF_URL -> $GEOTIFF_FILE"
  echo "aria2 connections: $ARIA_CONNECTIONS"
  aria2c -c -x "$ARIA_CONNECTIONS" -s "$ARIA_CONNECTIONS" -o "$GEOTIFF_FILE" "$GEOTIFF_URL"
elif command -v curl >/dev/null 2>&1; then
  echo "aria2c not found, falling back to curl: $GEOTIFF_URL -> $GEOTIFF_FILE"
  curl -L -o "$GEOTIFF_FILE" "$GEOTIFF_URL"
else
  echo "Error: neither aria2c nor curl is available. Install one to download files." >&2
  exit 1
fi

echo "Download complete: $GEOTIFF_FILE"
