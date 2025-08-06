#!/bin/sh

# The directory where your Payload CMS media volume is mounted.
MEDIA_VOLUME_PATH="/app/public/media"

echo "Setting permissions on the media volume at ${MEDIA_VOLUME_PATH}..."

# Check if the media directory exists and grant permissions.
# We use `find` to grant permissions recursively while skipping the `lost+found` directory.
if [ -d "${MEDIA_VOLUME_PATH}" ]; then
  # Grant full read, write, and execute permissions to the current user and group
  # for all files and directories under the media volume.
  # We use `find` to exclude the 'lost+found' directory.
  find "${MEDIA_VOLUME_PATH}" -maxdepth 1 ! -name 'lost+found' -exec chmod -R ug+rwx,o-rwx {} +
  echo "✅ Permissions granted to mounted volume."
else
  echo "⚠️ Media volume path ${MEDIA_VOLUME_PATH} does not exist. Skipping permission setup."
fi

# Finally, execute the main command.
echo "Starting Payload CMS with command: $*"
exec "$@"
