#!/bin/sh

# Set permissions on the media volume
echo "Setting permissions on the media volume..."
chown -R appuser:appgroup /app/public/media

# Execute the original command
echo "Starting Payload CMS..."
exec "$@"
