#!/bin/bash

# Okaerii Master Release Script
# This script automates: Build -> Commit -> Tag -> Push -> GitHub Release

set -e

# 1. Ask for version
current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")
echo "Current version: $current_version"
read -p "Enter new version (e.g. v1.1.1): " new_version

if [ -z "$new_version" ]; then
    echo "❌ Version cannot be empty."
    exit 1
fi

echo "🚀 Starting release process for $new_version..."

# 2. Build DMG
echo "🔨 Building installer..."
chmod +x scripts/build_installer.sh
./scripts/build_installer.sh

# 3. Git Operations
echo "📝 Committing changes..."
git add .
git commit -m "chore: release $new_version" || echo "No changes to commit"

echo "🏷️ Tagging $new_version..."
git tag -a "$new_version" -m "Release $new_version"

echo "⬆️ Pushing to GitHub..."
git push origin main
git push origin "$new_version"

# 4. GitHub Release
echo "🎁 Creating GitHub Release..."
gh release create "$new_version" Okaerii.dmg \
    --title "$new_version" \
    --generate-notes

echo "✅ All done! $new_version is now live on GitHub."
