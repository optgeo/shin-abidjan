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
	@if [ -f "$(GEOTIFF_FILE)" ]; then \
		echo "GeoTIFF file already exists. Skipping download."; \
	else \
		curl -L -o $(GEOTIFF_FILE) $(GEOTIFF_URL); \
		echo "Download complete."; \
	fi

# Convert GeoTIFF to PMTiles with metadata
convert: $(GEOTIFF_FILE)
	@echo "Converting GeoTIFF to PMTiles..."
	@rio pmtiles $(GEOTIFF_FILE) $(PMTILES_FILE) \
		--name $(NAME) \
		--description $(DESCRIPTION) \
		--attribution $(ATTRIBUTION)
	@echo "Conversion complete: $(PMTILES_FILE)"

# Upload PMTiles to server
upload: $(PMTILES_FILE)
	rsync --progress -av $(PMTILES_FILE) pod@pod.local:/home/pod/x-24b/data/shin-abidjan.pmtiles

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
