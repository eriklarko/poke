#!/bin/bash

# Test 8: Insufficient data (only 1 event)

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_insufficient_data() {
    local actionId="test-insufficient-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 8: Insufficient Data"
    log_info "=========================================="

    # Create action
    actionId=$(createAction "$actionId" "water-plant" "\"plant\": {\"id\": \"p4\", \"name\": \"Cactus\"}")

    # Only one event - should return null
    logEvent "$actionId" "2026-02-01T10:00:00Z"

    # Expected: null (need at least 2 events)
    expectReminder "$actionId" "null" "Single event should return null"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_insufficient_data

# Print summary
print_summary
