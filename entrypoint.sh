#!/bin/sh

# Set permissions on the media volume
echo "Setting permissions on the media volume..."
chown -R 1001:1001 /app/public/media

# Execute the original command
echo "Starting Payload CMS..."
exec "$@"
