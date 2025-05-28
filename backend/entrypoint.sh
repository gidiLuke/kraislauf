#!/bin/bash
set -e

# Wait for dependencies if needed
# sleep 5

# Run migrations or setup tasks if needed
# python -m app.db.init_db

# Start the application
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} ${UVICORN_EXTRA_ARGS:-}
