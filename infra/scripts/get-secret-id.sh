#!/bin/bash
# Script to get Docker secret ID by name
# Used by Terraform external data source

set -e

# Read input JSON from stdin
eval "$(jq -r '@sh "SECRET_NAME=\(.name)"')"

# Get secret ID via docker CLI
SECRET_ID=$(docker secret inspect "$SECRET_NAME" --format '{{.ID}}' 2>/dev/null || echo "")

# Output JSON
jq -n --arg id "$SECRET_ID" '{"id": $id}'
