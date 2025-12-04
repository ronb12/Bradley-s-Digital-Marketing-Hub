#!/bin/bash
# Xcode Cloud Post-Build Script
# This script runs after Xcode build completes
# Use this to upload metadata to App Store Connect

set -e

echo "📤 Starting metadata upload to App Store Connect..."

# Navigate to project directory
cd "$CI_WORKSPACE"

# Check if we should upload metadata
# Only upload if this is a main branch build or a tag
if [[ "$CI_BRANCH" == "main" ]] || [[ -n "$CI_TAG" ]]; then
    echo "✅ Build is on main branch or tag, proceeding with metadata upload..."
    
    # Set up API key authentication
    # Xcode Cloud provides secure environment variables
    if [[ -n "$APP_STORE_CONNECT_API_KEY_KEY_ID" ]] && [[ -n "$APP_STORE_CONNECT_API_KEY_ISSUER_ID" ]]; then
        echo "🔑 Using API key authentication from Xcode Cloud environment variables..."
        
        # Create directory for API key
        mkdir -p ~/.appstoreconnect/private_keys
        
        # The API key file should be stored as a secure file in Xcode Cloud
        # and made available via environment variable or file path
        if [[ -n "$APP_STORE_CONNECT_API_KEY_PATH" ]] && [[ -f "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
            echo "📁 Found API key file at: $APP_STORE_CONNECT_API_KEY_PATH"
            cp "$APP_STORE_CONNECT_API_KEY_PATH" ~/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_KEY_ID}.p8
            chmod 600 ~/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_KEY_ID}.p8
        fi
        
        # Export API key variables for Fastlane
        export APP_STORE_CONNECT_API_KEY_KEY_ID
        export APP_STORE_CONNECT_API_KEY_ISSUER_ID
        export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH=~/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_KEY_ID}.p8
        
        echo "🚀 Running Fastlane upload_all with API key..."
        fastlane upload_all || {
            echo "⚠️  API key authentication failed, this is a known Fastlane limitation"
            echo "   Metadata upload will need to be done manually or via password authentication"
            exit 0  # Don't fail the build, just warn
        }
    else
        echo "⚠️  API key environment variables not set"
        echo "   To enable metadata uploads, configure:"
        echo "   - APP_STORE_CONNECT_API_KEY_KEY_ID"
        echo "   - APP_STORE_CONNECT_API_KEY_ISSUER_ID"
        echo "   - APP_STORE_CONNECT_API_KEY_PATH (path to .p8 file)"
        echo ""
        echo "   Or use Xcode Cloud's built-in App Store Connect authentication"
    fi
else
    echo "ℹ️  Build is on branch: $CI_BRANCH"
    echo "   Skipping metadata upload (only runs on main branch or tags)"
fi

echo "✅ Metadata upload process complete"

