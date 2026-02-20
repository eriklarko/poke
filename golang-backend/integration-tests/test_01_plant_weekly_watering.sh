#!/bin/bash

# Test 1: Plant watering - regular weekly pattern

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_plant_weekly_watering() {
    # Use a timestamp-based plant ID so each run creates a fresh, unique action
    # and never collides with existing Firestore data (e.g. from the Flutter app).
    local ts
    ts=$(date +%s)
    local plantId="p1-${ts}"

    log_info "=========================================="
    log_info "TEST 1: Plant Watering - Weekly Pattern"
    log_info "=========================================="

    # Create plant watering action
    local actionId
    actionId=$(createAction "water-${plantId}" "water-plant" "\"plant\": {\"id\": \"${plantId}\", \"name\": \"Fiddle Leaf Fig\"}")

    # Water every Saturday at 11:00 AM (Nov 23, 1963 was a Saturday)
    logEvent "$actionId" "1963-11-23T11:00:00Z"
    logEvent "$actionId" "1963-11-30T11:00:00Z"
    logEvent "$actionId" "1963-12-07T11:00:00Z"
    logEvent "$actionId" "1963-12-14T11:00:00Z"

    # Expected: 7 days after last event = 1963-12-21T11:00:00Z
    expectReminder "$actionId" "1963-12-21T11:00:00Z" "Weekly watering should predict next Saturday"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_plant_weekly_watering

# Print summary
print_summary
