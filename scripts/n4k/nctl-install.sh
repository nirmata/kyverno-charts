#!/bin/bash

# Version and OS information
if [ -n "$VERSION" ]; then
  # The environment variable is set, use its value
  VERSION="$VERSION"

  #TO-DO --> Should terminate for invalid versions.
else
  # The environment variable is not set, assign a new value
  VERSION="3.3.0"
fi

if [ -n "$OS" ]; then
  # The environment variable is set, use its value
  OS="$OS"

  # Check if OS is not windows, macOs, or linux
  if [ "$OS" != "windows" ] && [ "$OS" != "macOs" ] && [ "$OS" != "linux" ]; then
    echo "Error: Unsupported OS!"
    exit 1
  fi

else
  OS="macOs"
fi


# The PATH you have added as an ENV variable
NCTL_PATH="/usr/bin/nctl"

# Base URL for the releases
BASE_URL="https://nirmata-downloads.s3.us-east-2.amazonaws.com/nctl"

# Generate the release URL based on the version and OS
RELEASE_URL="$BASE_URL/nctl_$VERSION/nctl_${VERSION}_${OS}_64-bit.zip"

echo $RELEASE_URL

# Temporary directory to store the downloaded zip file
TMP_DIR="/tmp/releases"

# Download the zip file
echo "Downloading releases..."
mkdir -p "$TMP_DIR"
curl -L "$RELEASE_URL" -o "$TMP_DIR/releases.zip"

# Unzip the release
echo "Unzipping releases..."
unzip "$TMP_DIR/releases.zip" -d "$TMP_DIR"

# Set permissions and move the executable
echo "Setting permissions and moving files..."
chmod u+x "$TMP_DIR/nctl"
sudo mv "$TMP_DIR/nctl" "$NCTL_PATH"

# Clean up temporary files
echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Installation completed successfully."
