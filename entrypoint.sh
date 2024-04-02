#!/bin/bash
set -e

# Check database connectivity, run migrations, etc.
# Example:
rails db:migrate

# Then start the Rails server
exec "$@"
