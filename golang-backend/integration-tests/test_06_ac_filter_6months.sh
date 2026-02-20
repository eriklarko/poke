#!/bin/bash

# Test 6: AC Filter - 6 month interval

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_ac_filter_6months() {
    local actionId="test-ac-filter-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 6: AC Filter - 6 Month Interval"
    log_info "=========================================="

    # Create AC filter change action
    actionId=$(createAction "$actionId" "change-ac-filter" "\"location\": \"Living Room\"")

    # Change filter roughly every 6 months
    logEvent "$actionId" "2024-01-15T10:00:00Z"
    logEvent "$actionId" "2024-07-20T10:00:00Z"  # ~6 months later
    logEvent "$actionId" "2025-01-18T10:00:00Z"  # ~6 months later
    logEvent "$actionId" "2025-07-22T10:00:00Z"  # ~6 months later

    # Should predict roughly 6 months = ~182 days
    expectReminder "$actionId" "2026-01-23T10:00:00Z" "6-month AC filter"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_ac_filter_6months

# Print summary
print_summary
