#!/bin/bash

# Test 7: AC Filter - variable interval (6-9 months)

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_ac_filter_variable() {
    local actionId="test-ac-filter-var-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 7: AC Filter - Variable Interval"
    log_info "=========================================="

    # Create AC filter change action
    actionId=$(createAction "$actionId" "change-ac-filter" "\"location\": \"Bedroom\"")

    # Change filter at variable intervals (6-9 months)
    logEvent "$actionId" "2023-01-01T14:00:00Z"
    logEvent "$actionId" "2023-07-15T14:00:00Z"  # 6.5 months
    logEvent "$actionId" "2024-04-01T14:00:00Z"  # 8.5 months
    logEvent "$actionId" "2024-10-15T14:00:00Z"  # 6.5 months

    # Should predict average interval (~7.2 months)
    expectReminder "$actionId" "2025-05-28T14:00:00Z" "Variable interval (6-9 months)"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_ac_filter_variable

# Print summary
print_summary
