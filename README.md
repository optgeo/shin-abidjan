# shin-abidjan
Maxar 2019 Abidjan Mosaic by Cristiano Giovando in PMTiles

## Overview

このプロジェクトは、OpenAerialMap から提供される Maxar 2019 Abidjan Mosaic の 1.8GB GeoTIFF ファイルを PMTiles 形式に変換するプロジェクトです。

- **データソース**: [OpenAerialMap](https://map.openaerialmap.org/#/-3.98703396320343,5.299799040916992,17/square/033333010030223110/5ea34be6c70abb0005869e90?_k=cir6ty)
- **GeoTIFF URL**: https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
- **ライセンス**: CC BY-NC 4.0
- **作成者**: Cristiano Giovando

## About the Name

The name **shin-abidjan** is a playful combination that reflects the project's goal:

- **shin** (新) evokes the **Shinkansen** (新幹線), Japan's famous bullet train known for its speed, reliability, and high throughput
- **abidjan** refers to the Abidjan mosaic data that forms the core of this project

Together, **shin-abidjan** signals our intent to deliver image tiles as fast and reliably as a bullet train. Just as the Shinkansen revolutionized rail travel with its remarkable performance, this project aims to provide high-performance tile delivery for geospatial data.

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

## What to commit / what to ignore

When working with this repository, keep the git history clean by committing only source and script files. The following items are intentionally ignored (see `.gitignore`):

- `data/` - large downloaded GeoTIFFs. These are resumable and can be recreated with `make download`.
- `output/` - generated PMTiles files; these are build artifacts.
- `tmp/` - temporary working directory used during conversion.
- `*.log`, `*.pid` - runtime logs and PID files created by background runs.
- Python virtual environment directories: `env/`, `venv/`, `.venv/`.

Commit these files (examples):

- `Makefile`, `scripts/*` - build scripts and helpers.
- `README.md`, `LICENSE` - documentation and licensing.
- Source configuration files such as `*.yml`, `*.yaml`, or `Dockerfile` if added.

If you need to share a generated PMTiles file for distribution, do so outside of this repository (for example via rsync or hosting) rather than committing the large binary into git.

## Viewer (docs/index.html)

静的な Web ビューアを `docs/index.html` に用意しています。MapLibre GL JS v5 と pmtiles.js を使い、以下をサポートします。

- TileJSON 経由のラスタタイル表示（WebP 優先、非対応ブラウザは自動で PNG にフォールバック）
- PMTiles の直接参照（`pmtiles://` プロトコル、Range 対応と CORS が必要）
- Protomaps ベースマップからの最小限の注記オーバーレイ（地名ラベル＋POI）
- 既存ズーム・中心位置のハッシュを尊重（URL の `#z/lat/lon` がある場合はオートフィットを抑止）
- 画像と注記の安定したレイヤ順（イメージを下、注記を上）

### 起動方法

- GitHub Pages で `docs/` を公開している場合は、`https://<username>.github.io/<repo>/` で開けます。
- ローカルで開く場合は、簡易な静的サーバ（例: `python -m http.server`）で `docs/` を配信してブラウザでアクセスしてください。

### クエリパラメータ

- `?tilejson=<URL>`: TileJSON の URL（既定: `https://tunnel.optgeo.org/martin/abidjan-2019`）
- `?pmtiles=<URL>`: PMTiles ファイルの URL（例: `https://tunnel.optgeo.org/abidjan-2019.pmtiles`）
  - 指定がある場合は TileJSON の上に上書き適用されます。
- `?protomaps=<URL|none>`: Protomaps ベースマップ TileJSON の URL。`none` で注記オーバーレイを無効化。
  - 既定: `https://tunnel.optgeo.org/martin/protomaps-basemap`

注記オーバーレイのレイヤ:

- `proto-place-labels`: 低ズーム向け地名ラベル（minzoom=5, maxzoom=15）
- `proto-poi-labels`: 高ズーム向け POI（minzoom=14）

備考:

- TileJSON から `minzoom`/`maxzoom` をソースに反映するため、不要な z19/20 へのリクエストを抑止します。
- WebP 非対応ブラウザでは `.webp` → `.png` に自動置換します（サーバ側で PNG が提供されている前提）。
- フォントは MapLibre のデモフォントを使用しています。

## License

The converted data follows the original CC BY-NC 4.0 license from the source material.

This project code itself is licensed under CC0 1.0 Universal.
