#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting build of Tesseract OCR 5.5.0 for SteamOS...${NC}"

# Creating directory for binary files if it doesn't exist
mkdir -p ./bin/steamos

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed! Please install Docker and try again.${NC}"
    exit 1
fi

# Building Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t tesseract-steamos -f Dockerfile.steamos . || {
    echo -e "${RED}Error during Docker image build!${NC}"
    exit 1
}

# Running container to copy files
echo -e "${YELLOW}Copying built files...${NC}"
docker run --rm -v "$(pwd)/bin/steamos:/dist" tesseract-steamos || {
    echo -e "${RED}Error copying files!${NC}"
    exit 1
}

# Checking for binary files
if [ ! -f "./bin/steamos/bin/tesseract" ]; then
    echo -e "${RED}Tesseract binary file not found! Build failed.${NC}"
    exit 1
fi

if [ ! -f "./bin/steamos/bin/run_tesseract.sh" ]; then
    echo -e "${RED}run_tesseract.sh wrapper script not found! Build failed.${NC}"
    exit 1
fi

# Setting correct permissions
echo -e "${YELLOW}Setting access permissions...${NC}"
chmod -R 755 ./bin/steamos/bin

# Checking for language data
if [ ! -f "./bin/steamos/tessdata/eng.traineddata" ]; then
    echo -e "${YELLOW}English language file not found. Attempting to download...${NC}"
    mkdir -p ./bin/steamos/tessdata
    curl -o ./bin/steamos/tessdata/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata || {
        echo -e "${RED}Failed to download eng.traineddata!${NC}"
        exit 1
    }
fi

if [ ! -f "./bin/steamos/tessdata/rus.traineddata" ]; then
    echo -e "${YELLOW}Russian language file not found. Attempting to download...${NC}"
    mkdir -p ./bin/steamos/tessdata
    curl -o ./bin/steamos/tessdata/rus.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata || {
        echo -e "${YELLOW}Failed to download rus.traineddata. This is not critical for English OCR functionality.${NC}"
    }
fi

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Tesseract 5.5.0 binary files are available in ./bin/steamos directory${NC}"
echo -e "${YELLOW}To use Tesseract in the plugin, call ./bin/steamos/bin/run_tesseract.sh${NC}"