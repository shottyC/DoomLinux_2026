#!/usr/bin/env bash
set -eu

# Use ARTIFACT_DIR env var or default
ARTIFACT_DIR=${ARTIFACT_DIR:-tests/artifacts}
mkdir -p "$ARTIFACT_DIR"

# Ensure pip is up to date and install required modules in the environment
python3 -m pip install --upgrade pip >/dev/null 2>&1
python3 -m pip install --upgrade behave coverage >/dev/null 2>&1

# Run coverage
python3 -m coverage erase
python3 -m coverage run --source=. -m behave tests/features
python3 -m coverage report -m | tee "$ARTIFACT_DIR/coverage.txt"
python3 -m coverage xml -o "$ARTIFACT_DIR/coverage.xml"

echo "✅ Coverage artifacts generated in $ARTIFACT_DIR"
