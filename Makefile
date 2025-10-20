# Makefile for shin-abidjan project
# Convert Maxar 2019 Abidjan Mosaic GeoTIFF to PMTiles

# Variables
DATA_DIR := data
OUTPUT_DIR := output
GEOTIFF_URL := https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
GEOTIFF_FILE := $(DATA_DIR)/5ea338e5c70abb0005869e8f.tif
PMTILES_FILE := $(OUTPUT_DIR)/abidjan-2019.pmtiles

# Metadata
NAME := "Maxar 2019 Abidjan Mosaic"
DESCRIPTION := "Maxar 2019 Abidjan Mosaic by Cristiano Giovando"
ATTRIBUTION := "© Maxar - CC BY-NC 4.0"

.PHONY: all download convert upload clean dirs help

# Default target
all: dirs download convert

# Create necessary directories
dirs:
	@echo "Creating working directories..."
	@mkdir -p $(DATA_DIR)
	@mkdir -p $(OUTPUT_DIR)

# Download the GeoTIFF file
download: dirs
	@echo "Downloading GeoTIFF file from OpenAerialMap..."
	@./scripts/download.sh $(GEOTIFF_FILE) $(GEOTIFF_URL)

# Convert GeoTIFF to PMTiles with metadata
# Ensure the download target runs first so the input file exists
convert: download
	@echo "Converting GeoTIFF to PMTiles..."
	# Verify input has at least 3 bands (RGB). If 4 bands exist and you want alpha,
	# use the --rgba flag for rio pmtiles.
	@if ! command -v gdalinfo >/dev/null 2>&1; then \
		echo "gdalinfo not found. Install GDAL (e.g. 'brew install gdal') to validate input bands."; \
		# Fall back to running rio pmtiles without pre-check; default to WEBP and tile-size 512
		FORMAT_FLAG="-f WEBP"; \
		RGBA_FLAG=""; \
		TILE_FLAG="--tile-size 512"; \
		rio pmtiles $(GEOTIFF_FILE) $(PMTILES_FILE) $$FORMAT_FLAG $$RGBA_FLAG $$TILE_FLAG \
			--name $(NAME) \
			--description $(DESCRIPTION) \
			--attribution $(ATTRIBUTION); \
	else \
		# Count bands using gdalinfo without requiring jq. This counts lines starting with "Band ".
		BANDS=$$(gdalinfo $(GEOTIFF_FILE) 2>/dev/null | grep -E "^Band [0-9]+" -c || true); \
		if [ -z "$$BANDS" ] || [ "$$BANDS" -lt 3 ]; then \
			echo "Error: input file has less than 3 bands ($$BANDS). rio pmtiles requires at least 3 bands (RGB)."; \
			exit 1; \
		fi; \
		# Default to WEBP and tile-size 512; WebP supports alpha so we can use --rgba when available.
		FORMAT_FLAG="-f WEBP"; \
		RGBA_FLAG=""; \
		TILE_FLAG="--tile-size 512"; \
		if [ "$$BANDS" -ge 4 ]; then \
			echo "Input has $$BANDS bands. Enabling --rgba and using WEBP for alpha support."; \
			RGBA_FLAG="--rgba"; \
		fi; \
		rio pmtiles $(GEOTIFF_FILE) $(PMTILES_FILE) $$FORMAT_FLAG $$RGBA_FLAG $$TILE_FLAG \
			--name $(NAME) \
			--description $(DESCRIPTION) \
			--attribution $(ATTRIBUTION); \
	fi
	@echo "Conversion complete: $(PMTILES_FILE)"

# Upload PMTiles to server
upload: $(PMTILES_FILE)
	rsync --progress -av $(PMTILES_FILE) pod@pod.local:/home/pod/x-24b/data/$(PMTILES_FILE) 

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(DATA_DIR)
	@rm -rf $(OUTPUT_DIR)
	@echo "Clean complete."

# Show help
help:
	@echo "Available targets:"
	@echo "  all      - Create directories, download and convert (default)"
	@echo "  dirs     - Create working directories"
	@echo "  download - Download the GeoTIFF file"
	@echo "  convert  - Convert GeoTIFF to PMTiles"
	@echo "  upload   - Upload PMTiles to server"
	@echo "  clean    - Remove generated files"
	@echo "  help     - Show this help message"
