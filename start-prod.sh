#!/bin/bash

# Wrapper script to start production server with AWS SSO credentials
# Usage: ./start-prod.sh

set -e

echo "Checking AWS SSO session..."

# Check if AWS credentials are valid
if ! aws sts get-caller-identity --profile default &> /dev/null; then
    echo ""
    echo "❌ AWS SSO session is invalid or expired."
    echo "Please authenticate first with:"
    echo "  aws sso login --profile default"
    echo ""
    exit 1
fi

echo "✓ AWS SSO session is valid"
echo ""

# Refresh credentials to .env.local
echo "Refreshing credentials..."
./refresh-aws-creds.sh

echo ""
echo "Starting production server on port 6001..."
echo ""

# Start production server
npm start
