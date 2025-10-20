# Makefile for shin-abidjan project
# Convert Maxar 2019 Abidjan Mosaic GeoTIFF to PMTiles

# Variables
DATA_DIR := data
OUTPUT_DIR := output
GEOTIFF_URL := https://oin-hotosm-temp.s3.amazonaws.com/5ea338e5c70abb0005869e8e/0/5ea338e5c70abb0005869e8f.tif
GEOTIFF_FILE := $(DATA_DIR)/5ea338e5c70abb0005869e8f.tif
PMTILES_FILE := $(OUTPUT_DIR)/abidjan-2019.pmtiles

# Configurable options (override with `make FORMAT=PNG TILE_SIZE=256` etc.)
FORMAT ?= WEBP
TILE_SIZE ?= 512
ARIA_CONNECTIONS ?= 2
# RIO_WORKERS left empty by default (rio-pmtiles will choose CPU count). Set e.g. RIO_WORKERS=4
RIO_WORKERS ?=
# PMTILES_CO can be used to add creation options, e.g. PMTILES_CO=ZLEVEL=8 or PMTILES_CO="QUALITY=90 LOSSLESS=TRUE"
PMTILES_CO ?=

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
	@./scripts/download.sh $(GEOTIFF_FILE) $(GEOTIFF_URL) $(ARIA_CONNECTIONS)

# Convert GeoTIFF to PMTiles with metadata
# Ensure the download target runs first so the input file exists
convert: download
	@echo "Converting GeoTIFF to PMTiles..."
	# Verify input has at least 3 bands (RGB). If 4 bands exist and you want alpha,
	# use the --rgba flag for rio pmtiles.
	@if ! command -v gdalinfo >/dev/null 2>&1; then \
		echo "gdalinfo not found. Install GDAL (e.g. 'brew install gdal') to validate input bands."; \
		# Fall back to running rio pmtiles without pre-check; use configured FORMAT and TILE_SIZE
		FORMAT_FLAG="-f $(FORMAT)"; \
		RGBA_FLAG=""; \
		TILE_FLAG="--tile-size $(TILE_SIZE)"; \
		# Pass creation options if provided
		CO_FLAGS=""; \
		if [ -n "$(PMTILES_CO)" ]; then \
			for kv in $(PMTILES_CO); do CO_FLAGS="$$CO_FLAGS --co $$kv"; done; \
		fi; \
		rio pmtiles $(GEOTIFF_FILE) $(PMTILES_FILE) $$FORMAT_FLAG $$RGBA_FLAG $$TILE_FLAG $$CO_FLAGS $(if $(RIO_WORKERS),-j $(RIO_WORKERS),) \
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
		# Default to configured FORMAT and TILE_SIZE; WebP supports alpha so we can use --rgba when available.
		FORMAT_FLAG="-f $(FORMAT)"; \
		RGBA_FLAG=""; \
		TILE_FLAG="--tile-size $(TILE_SIZE)"; \
		if [ "$$BANDS" -ge 4 ]; then \
			echo "Input has $$BANDS bands. Enabling --rgba and using $(FORMAT) for alpha support."; \
			RGBA_FLAG="--rgba"; \
		fi; \
		CO_FLAGS=""; \
		if [ -n "$(PMTILES_CO)" ]; then \
			for kv in $(PMTILES_CO); do CO_FLAGS="$$CO_FLAGS --co $$kv"; done; \
		fi; \
		rio pmtiles $(GEOTIFF_FILE) $(PMTILES_FILE) $$FORMAT_FLAG $$RGBA_FLAG $$TILE_FLAG $$CO_FLAGS $(if $(RIO_WORKERS),-j $(RIO_WORKERS),) \
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
