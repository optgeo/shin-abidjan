# shin-abidjan
Maxar 2019 Abidjan Mosaic by Cristiano Giovando in PMTiles

## Overview

このプロジェクトは、OpenAerialMap から提供される Maxar 2019 Abidjan Mosaic の 1.8GB GeoTIFF ファイルを PMTiles 形式に変換するプロジェクトです。

- **データソース**: [OpenAerialMap](https://map.openaerialmap.org/#/-3.98703396320343,5.299799040916992,17/square/033333010030223110/5ea34be6c70abb0005869e90?_k=cir6ty)
- **GeoTIFF URL**: https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
- **ライセンス**: CC BY-NC 4.0
- **作成者**: Cristiano Giovando

## Requirements

- `curl` or `wget` for downloading
- `rio-pmtiles` for conversion
- Python environment with rasterio

## Installation

```bash
pip install rio-pmtiles
```

## Usage

### Download the GeoTIFF file

```bash
make download
```

### Convert to PMTiles format

```bash
make convert
```

### Upload to server

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
