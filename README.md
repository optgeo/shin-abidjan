# shin-abidjan
Maxar 2019 Abidjan Mosaic by Cristiano Giovando in PMTiles

## Overview

このプロジェクトは、OpenAerialMap から提供される Maxar 2019 Abidjan Mosaic の 1.8GB GeoTIFF ファイルを PMTiles 形式に変換するプロジェクトです。

- **データソース**: [OpenAerialMap](https://map.openaerialmap.org/#/-3.98703396320343,5.299799040916992,17/square/033333010030223110/5ea34be6c70abb0005869e90?_k=cir6ty)
- **GeoTIFF URL**: https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
- **ライセンス**: CC BY-NC 4.0
- **作成者**: Cristiano Giovando

## Requirements

- `aria2c` or `curl` for downloading (the project prefers `aria2c` for resumable, parallel downloads; `curl` is used as a fallback)
- `rio-pmtiles` for conversion (install via `pip install rio-pmtiles`)
- `gdalinfo` (optional, used by the Makefile to validate input bands before conversion)

Note: On macOS you can install missing tools with Homebrew, e.g. `brew install aria2 gdal`.

## Installation

```bash
pip install rio-pmtiles
```

## Usage

### Download the GeoTIFF file

The Makefile's `download` target calls `scripts/download.sh`, which uses `aria2c` when available and falls back to `curl`.

To download (resume-capable):

```bash
make download
```

If a previous download was interrupted, re-running `make download` will resume with `aria2c` (because `-c` is used). If you prefer to run the script directly:

```bash
./scripts/download.sh data/5ea338e5c70abb0005869e8f.tif https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
```

If you see an error about missing tools, install `aria2c` or `curl` as noted above.

### Convert to PMTiles format

The conversion uses `rio pmtiles`. The Makefile will perform a light validation of the input bands using `gdalinfo` if available:

- If the source has at least 3 bands the conversion proceeds (RGB).
- If the source has 4 or more bands the Makefile will automatically add `--rgba` and use WebP (`-f WEBP`) as the tile image format.

Default tile size is 512 (the Makefile passes `--tile-size 512`). To convert:

```bash
make convert
```

If you want to customize format, quality, or other creation options, edit the Makefile or run `rio pmtiles` manually. The `rio pmtiles --help` output is included in the project notes and explains options such as `--co QUALITY=90` or `--co LOSSLESS=TRUE` for WEBP/PNG creation options.

### Upload to server

> **Prerequisite:** This step requires SSH access to `pod@pod.local` and a valid destination path. You may need to configure these to match your environment.
```bash
make upload
```

This will execute (where `$(PMTILES_FILE)` resolves to `output/abidjan-2019.pmtiles`):
```bash
rsync --progress -av $(PMTILES_FILE) pod@pod.local:/home/pod/x-24b/data/shin-abidjan.pmtiles
```

### Run all steps

```bash
make all
```

## Directory Structure

```
shin-abidjan/
├── data/          # Downloaded GeoTIFF files
├── output/        # Generated PMTiles files
├── Makefile       # Build automation
└── README.md      # This file
```

## License

The converted data follows the original CC BY-NC 4.0 license from the source material.

This project code itself is licensed under CC0 1.0 Universal.
