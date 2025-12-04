#!/bin/bash
# Xcode Cloud Post-Clone Script
# This script runs after the repository is cloned

set -e

echo "🔧 Setting up environment for metadata upload..."

# Install Fastlane if not already available
if ! command -v fastlane &> /dev/null; then
    echo "📦 Installing Fastlane..."
    gem install fastlane --no-document
fi

# Verify Fastlane installation
fastlane --version

echo "✅ Environment setup complete"

