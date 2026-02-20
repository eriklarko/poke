#!/bin/bash

# Test 5: Medication - with missed days

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_medication_missed_days() {
    local actionId="test-meds-missed-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 5: Medication - Missed Days"
    log_info "=========================================="

    # Create medication action
    actionId=$(createAction "$actionId" "take-medication" "\"medication\": {\"name\": \"Antibiotics\"}")

    # Sometimes miss a day - algorithm should still predict daily
    logEvent "$actionId" "2026-02-01T20:00:00Z"
    logEvent "$actionId" "2026-02-02T20:00:00Z"
    # Missed 2026-02-03
    logEvent "$actionId" "2026-02-04T20:00:00Z"
    logEvent "$actionId" "2026-02-05T20:00:00Z"
    logEvent "$actionId" "2026-02-06T20:00:00Z"

    # Average will be slightly more than 1 day due to the gap
    expectReminder "$actionId" "2026-02-07T20:00:00Z" "Should handle missed days"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_medication_missed_days

# Print summary
print_summary
