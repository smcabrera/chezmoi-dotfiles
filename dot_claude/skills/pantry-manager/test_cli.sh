#!/bin/bash

# Test script for pantry-manager CLI
# This demonstrates all available commands

set -e  # Exit on error

CLI="/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager"

echo "=========================================="
echo "Testing pantry-manager CLI"
echo "=========================================="
echo

echo "1. Testing help command..."
$CLI help
echo
echo "✓ Help command works"
echo

echo "=========================================="
echo "2. Testing pantry management..."
echo "=========================================="
echo

echo "Adding items to pantry..."
$CLI add "test carrot" 5 whole
$CLI add "test onion" 2 whole
echo

echo "Listing pantry..."
$CLI list
echo

echo "Removing test items..."
$CLI remove "test carrot"
$CLI remove "test onion"
echo
echo "✓ Pantry management works"
echo

echo "=========================================="
echo "3. Testing recipe commands..."
echo "=========================================="
echo

echo "Listing all recipes..."
$CLI recipes
echo

echo "Showing recipe details..."
$CLI recipe 1
echo
echo "✓ Recipe commands work"
echo

echo "=========================================="
echo "4. Testing search..."
echo "=========================================="
echo

echo "Searching for 'chicken'..."
$CLI search chicken
echo
echo "✓ Search works"
echo

echo "=========================================="
echo "5. Testing favorites..."
echo "=========================================="
echo

echo "Adding recipe to favorites..."
$CLI favorite 2 4 "Great recipe!"
echo
echo "✓ Favorites work"
echo

echo "=========================================="
echo "6. Testing error handling..."
echo "=========================================="
echo

echo "Testing invalid command..."
if $CLI invalid-command 2>&1 | grep -q "Unknown command"; then
    echo "✓ Invalid command handling works"
else
    echo "✗ Invalid command handling failed"
    exit 1
fi
echo

echo "Testing missing arguments..."
if $CLI add 2>&1 | grep -q "Usage:"; then
    echo "✓ Missing arguments handling works"
else
    echo "✗ Missing arguments handling failed"
    exit 1
fi
echo

echo "=========================================="
echo "All tests passed!"
echo "=========================================="
echo
echo "The CLI can be used from anywhere:"
echo "  $CLI list"
echo
echo "Or add to your PATH for system-wide access:"
echo "  export PATH=\"/Users/stephen/.claude/skills/pantry-manager/bin:\$PATH\""
echo "  pantry-manager list"
