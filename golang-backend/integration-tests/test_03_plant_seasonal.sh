#!/bin/bash

# Test 3: Plant watering - seasonal variation (summer vs winter)

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared test library
source "$SCRIPT_DIR/test_lib.sh"

# Test function
test_plant_seasonal() {
    local actionId="test-plant-seasonal-$(date +%s)"

    log_info "=========================================="
    log_info "TEST 3: Plant Watering - Seasonal Pattern"
    log_info "=========================================="

    # Create plant watering action
    actionId=$(createAction "$actionId" "water-plant" "\"plant\": {\"id\": \"p3\", \"name\": \"Pothos\"}")

    # Summer watering (more frequent - every 3 days)
    logEvent "$actionId" "2025-06-01T10:00:00Z"
    logEvent "$actionId" "2025-06-04T10:00:00Z"
    logEvent "$actionId" "2025-06-07T10:00:00Z"
    logEvent "$actionId" "2025-06-10T10:00:00Z"

    # Algorithm will average 3 days and predict next watering
    expectReminder "$actionId" "2025-06-13T10:00:00Z" "Summer: every 3 days"

    # Now add winter watering (less frequent - every 7 days)
    logEvent "$actionId" "2025-12-01T10:00:00Z"
    logEvent "$actionId" "2025-12-08T10:00:00Z"
    logEvent "$actionId" "2025-12-15T10:00:00Z"

    # TODO: Improve test by checking if algorithm can detect seasonality and adjust predictions accordingly.
    # or not... I don't know - maybe trust the unit tests here; it's gonna be weird setting "now"

    # Algorithm will now average across all events (mix of 3-day and 7-day)
    expectReminder "$actionId" "2025-12-22T10:00:00Z" "Mixed seasons: average cadence"
    cleanup "$actionId"
}

# Check if server is running
if ! check_server; then
    exit 1
fi

# Run the test
test_plant_seasonal

# Print summary
print_summary
