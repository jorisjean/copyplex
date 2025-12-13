#!/bin/bash

# Load the configuration file containing PLEX_TOKEN
CONFIG_FILE="$HOME/plex_config.env"  # Uses home directory (~) for the config file

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Error: Configuration file not found at $CONFIG_FILE."
  exit 1
fi

# Check if PLEX_TOKEN is loaded from the config file
if [ -z "$PLEX_TOKEN" ]; then
  echo "Error: PLEX_TOKEN not set in configuration file."
  exit 1
fi

# Plex server information
PLEX_SERVER="localhost"  # Change to your Plex server's IP or hostname if necessary
PLEX_PORT="32400"

# Usage function
usage() {
  echo "Usage: $0 -m|-s <file_path>"
  echo "  -m: Copy to Movies folder"
  echo "  -s: Copy to TVShows folder"
  exit 1
}

# Check for correct number of arguments
if [ $# -lt 2 ]; then
  usage
fi

# Parse options
while getopts "ms" option; do
  case $option in
    m)
      DESTINATION="/var/lib/plexmediaserver/media/Movies/"
      ;;
    s)
      DESTINATION="/var/lib/plexmediaserver/media/TVShows/"
      ;;
    *)
      usage
      ;;
  esac
done

# Shift arguments so file path is the next argument
shift $((OPTIND - 1))

# Check if file path is provided
if [ -z "$1" ]; then
  echo "Error: No file path provided."
  usage
fi

FILE_PATH="$1"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File does not exist at $FILE_PATH."
  exit 1
fi

# Copy the file to the destination
sudo mv "$FILE_PATH" "$DESTINATION"
if [ $? -ne 0 ]; then
  echo "Error: Failed to move the file."
  exit 1
fi

# Change ownership to plex:plex using sudo
sudo chown plex:plex "${DESTINATION}$(basename "$FILE_PATH")"
if [ $? -ne 0 ]; then
  echo "Error: Failed to change ownership to plex:plex."
  exit 1
fi

# Change perms to allow group to delete
sudo chmod 775 "${DESTINATION}$(basename "$FILE_PATH")"
if [ $? -ne 0 ]; then
  echo "Error: Failed to change perms to 775."
  exit 1
fi

# Refresh Plex library by sending a request to the Plex API
REFRESH_URL="http://${PLEX_SERVER}:${PLEX_PORT}/library/sections/all/refresh?X-Plex-Token=${PLEX_TOKEN}"

curl -X POST "$REFRESH_URL"
if [ $? -ne 0 ]; then
  echo "Error: Failed to refresh Plex library."
  exit 1
fi

echo "File successfully copied, ownership changed, and Plex library refreshed."
