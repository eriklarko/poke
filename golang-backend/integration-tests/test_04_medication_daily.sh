#!/bin/bash

# Test 4: Medication - daily at same time (nagging cron job)

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_medication_daily() {
    local actionId="test-meds-daily-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 4: Medication - Daily Reminder"
    log_info "=========================================="

    # Create medication action
    actionId=$(createAction "$actionId" "take-medication" "\"medication\": {\"name\": \"Vitamin D\", \"dosage\": \"1000 IU\"}")

    # Take medication daily at 8:00 AM
    logEvent "$actionId" "2026-02-01T08:00:00Z"
    logEvent "$actionId" "2026-02-02T08:00:00Z"
    logEvent "$actionId" "2026-02-03T08:00:00Z"
    logEvent "$actionId" "2026-02-04T08:00:00Z"
    logEvent "$actionId" "2026-02-05T08:00:00Z"

    # Expected: exactly 24 hours after last event
    expectReminder "$actionId" "2026-02-06T08:00:00Z" "Daily at 8 AM"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_medication_daily

# Print summary
print_summary
