#!/bin/bash

# Test 2: Plant watering - varying times (time-of-day awareness)

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_plant_varying_times() {
    local actionId="test-plant-varying-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 2: Plant Watering - Varying Times"
    log_info "=========================================="

    # Create plant watering action
    actionId=$(createAction "$actionId" "water-plant" "\"plant\": {\"id\": \"p2\", \"name\": \"Snake Plant\"}")

    # Water weekly but at different times - algorithm should find most common time
    logEvent "$actionId" "1963-11-23T11:00:00Z"  # Saturday 11 AM
    logEvent "$actionId" "1963-11-30T12:00:00Z"  # Saturday 12 PM
    logEvent "$actionId" "1963-12-08T11:30:00Z"  # Sunday 11:30 AM (8 days later)
    logEvent "$actionId" "1963-12-15T11:15:00Z"  # Sunday 11:15 AM

    # Should average ~7.3 days and pick most common time (around 11:00-11:30 AM)
    expectReminder "$actionId" "1963-12-22T11:15:00Z" "Should predict around 11 AM based on mode"

    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_plant_varying_times

# Print summary
print_summary
