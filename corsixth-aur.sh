#!/bin/bash

# Enable strict error handling to immediately exit on failures or unset variables
set -euo pipefail

# Ensure the script is being run in a directory containing a PKGBUILD
if [[ ! -f "PKGBUILD" ]]; then
    echo "Error: No PKGBUILD found in the current directory. Aborting."
    exit 1
fi

echo "==> Updating checksums..."
updpkgsums

echo "==> Building package, syncing dependencies, and running tests..."
makepkg -src

echo "==> Regenerating .SRCINFO..."
makepkg --printsrcinfo > .SRCINFO

# Source the PKGBUILD to extract the updated version and release number
source ./PKGBUILD
COMMIT_MSG="Update to version ${pkgver}-${pkgrel}"

# Check if there are actually changes to commit (prevents git from throwing an error)
if [[ -z $(git status -s) ]]; then
    echo "==> No changes detected in the repository. Exiting."
    exit 0
fi

echo "==> Staging PKGBUILD and .SRCINFO..."
git add PKGBUILD .SRCINFO

echo "==> Committing updates: '$COMMIT_MSG'"
git commit -m "$COMMIT_MSG"

echo "==> Pushing to the AUR remote..."
git push

echo "==> Success! $pkgname successfully updated to ${pkgver}-${pkgrel}."