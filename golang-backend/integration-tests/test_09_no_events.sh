#!/bin/bash

# Test 9: No events at all

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_no_events() {
    local actionId="test-no-events-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 9: No Events"
    log_info "=========================================="

    # Create action but don't log any events
    actionId=$(createAction "$actionId" "water-plant" "\"plant\": {\"id\": \"p5\", \"name\": \"Empty Plant\"}")

    # Expected: null (no events)
    expectReminder "$actionId" "null" "No events should return null"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_no_events

# Print summary
print_summary
