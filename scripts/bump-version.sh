#!/bin/bash

# Version bump script
# Usage: ./scripts/bump-version.sh [major|minor|patch]

set -e

BUMP_TYPE=${1:-patch}
VERSION_FILE="VERSION"

# Get current version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
else
    CURRENT_VERSION="0.0.0"
fi

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version
case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

echo "Version bumped: $CURRENT_VERSION -> $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Update CHANGELOG.md with changes for v$NEW_VERSION"
echo "  2. Commit: git add VERSION CHANGELOG.md && git commit -m \"Bump version to $NEW_VERSION\""
echo "  3. Tag: git tag v$NEW_VERSION"
echo "  4. Push: git push && git push --tags"
