#!/bin/bash

# Test 10: Exact 24-hour medication reminder

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_medication_exact_24h() {
    local actionId="test-meds-24h-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 10: Medication - Exact 24h Intervals"
    log_info "=========================================="

    # Create medication action
    actionId=$(createAction "$actionId" "take-medication" "\"medication\": {\"name\": \"Blood Pressure Med\"}")

    # Perfectly regular 24-hour intervals
    logEvent "$actionId" "2026-02-10T07:00:00Z"
    logEvent "$actionId" "2026-02-11T07:00:00Z"
    logEvent "$actionId" "2026-02-12T07:00:00Z"
    logEvent "$actionId" "2026-02-13T07:00:00Z"
    logEvent "$actionId" "2026-02-14T07:00:00Z"
    logEvent "$actionId" "2026-02-15T07:00:00Z"
    logEvent "$actionId" "2026-02-16T07:00:00Z"

    # Should predict exactly 2026-02-17T07:00:00Z
    expectReminder "$actionId" "2026-02-17T07:00:00Z" "Perfect 24h should predict 2026-02-17T07:00:00Z"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_medication_exact_24h

# Print summary
print_summary
