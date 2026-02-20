#!/bin/bash

# Shared Test Library for Prediction Algorithm Tests
# Contains all helper functions and common setup

set -euo pipefail

# Configuration
API_BASE="${API_BASE:-http://localhost:8080}"
AUTH_TOKEN="${AUTH_TOKEN:-}"
TEST_USER_ID="${TEST_USER_ID:-test-user-$(date +%s)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Check if server is running
check_server() {
    log_info "Checking if server is running at $API_BASE..."
    if curl -s -f "$API_BASE/health" > /dev/null 2>&1; then
        log_success "Server is running"
        return 0
    else
        log_error "Server is not responding at $API_BASE/health"
        log_info "Start the server with: cd golang-backend && go run cmd/api/main.go"
        return 1
    fi
}

# Make authenticated API request
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="${API_BASE}${endpoint}"
    local args=(-X "$method")

    if [ -n "$AUTH_TOKEN" ]; then
        args+=(-H "Authorization: Bearer $AUTH_TOKEN")
    fi

    args+=(-H "Content-Type: application/json")

    if [ -n "$data" ]; then
        args+=(-d "$data")
    fi

    # Show full response including headers for debugging
    args+=(-w "\nHTTP_CODE:%{http_code}")

    curl "${args[@]}" "$url"
}

# Create an action
# Usage: createAction <actionId> <serializationKey> [additionalJson]
# Returns: The actual action ID created by the server (echoed to stdout)
createAction() {
    local actionId="$1"
    local serializationKey="$2"
    local additionalJson="${3:-}"

    local payload="{\"serializationKey\": \"$serializationKey\", \"events\": {}}"

    if [ -n "$additionalJson" ]; then
        # Merge additional JSON (remove trailing } and add fields, then close })
        payload="${payload%\}}, $additionalJson}"
    fi

    log_info "Creating action: $actionId ($serializationKey)"
    local response=$(api_request POST "/v1/actions" "$payload")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_CODE:")

    if [[ "$http_code" == "201" ]] || [[ "$http_code" == "200" ]]; then
        # Extract the actual action ID from the response
        local actualActionId=""
        if command -v jq &> /dev/null; then
            actualActionId=$(echo "$body" | jq -r '.actionId // empty')
        fi

        if [ -n "$actualActionId" ]; then
            log_success "Action created: $actualActionId"
            echo "$actualActionId"  # Return the action ID
        else
            echo "ERROR!! No actionId returned in response:" >&2
            echo "$body" | head -15 >&2
            exit 100
        fi
        return 0
    elif [[ "$http_code" == "409" ]]; then
        log_warning "Action already exists: $actionId"
        # Derive the action ID the server would have assigned for water-plant actions.
        # For other types a ksuid was generated so we cannot reconstruct it, and
        # the caller should delete + recreate instead.
        if [ -n "$additionalJson" ]; then
            local plantId
            plantId=$(echo "$additionalJson" | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1)
            if [ -n "$plantId" ]; then
                local derivedId="water-$plantId"
                log_info "Returning derived action ID for existing water-plant: $derivedId"
                echo "$derivedId"
                return 0
            fi
        fi
        log_error "Cannot derive action ID for existing action — delete it first or use a unique plant ID"
        return 1
    else
        log_error "Failed to create action: $actionId (HTTP $http_code)"
        echo "$body" | head -5 >&2
        return 1
    fi
}

# Log an event
# Usage: logEvent <actionId> <timestamp> [eventData]
logEvent() {
    local actionId="$1"
    local timestamp="$2"
    local eventData="${3:-{}}"

    # Convert simple date formats to RFC3339
    if [[ ! "$timestamp" =~ T.*Z$ ]] && [[ ! "$timestamp" =~ T.*[+-] ]]; then
        # If it looks like YYYY-MM-DD HH:MM:SS, convert to RFC3339
        if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            timestamp="${timestamp/T/ }Z"
            timestamp="${timestamp// /T}"
        elif [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            timestamp="${timestamp}T00:00:00Z"
        fi
    fi

    local payload="{\"when\": \"$timestamp\", \"data\": $eventData}"

    log_info "Logging event for $actionId at $timestamp"
    local response=$(api_request POST "/v1/actions/$actionId/events" "$payload")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_CODE:")

    if [[ "$http_code" == "201" ]] || [[ "$http_code" == "200" ]]; then
        log_success "Event logged for $actionId"
        return 0
    elif [[ "$http_code" == "409" ]]; then
        log_warning "Event already exists at this timestamp"
        return 0
    else
        log_error "Failed to log event (HTTP $http_code)"
        echo "$body" | head -5 >&2
        return 1
    fi
}

# Get all actions (which includes events)
getActions() {
    log_info "Fetching all actions..."
    local response=$(api_request GET "/v1/actions")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_CODE:")

    if [[ "$http_code" == "200" ]]; then
        echo "$body"
        return 0
    else
        log_error "Failed to get actions (HTTP $http_code)"
        echo "$body" | head -5 >&2
        return 1
    fi
}

# Get a specific action
getAction() {
    local actionId="$1"

    log_info "Fetching action: $actionId"
    local response=$(api_request GET "/v1/actions/$actionId")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_CODE:")

    if [[ "$http_code" == "200" ]]; then
        echo "$body"
        return 0
    else
        log_error "Failed to get action (HTTP $http_code)"
        echo "$body" | head -5 >&2
        return 1
    fi
}

# Get reminders (once the endpoint is implemented)
getReminders() {
    log_info "Fetching reminders..."
    local response=$(api_request GET "/v1/reminders")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_CODE:")

    if [[ "$http_code" == "200" ]]; then
        echo "$body"
        return 0
    elif [[ "$http_code" == "404" ]]; then
        log_warning "Reminders endpoint not yet implemented"
        log_info "Falling back to calculating from action events..."
        return 2
    else
        log_error "Failed to get reminders (HTTP $http_code)"
        echo "$body" | head -5 >&2
        return 1
    fi
}

# Get reminder for a specific action from the API
# Returns the dueDate for the action, or "null" if not available
getReminderForAction() {
    local actionId="$1"

    # Get all reminders from the API
    local response=$(getReminders 2>/dev/null)
    local status=$?

    if [ $status -eq 2 ]; then
        # Endpoint not yet implemented
        log_warning "Reminders endpoint not implemented yet"
        echo "NOT_IMPLEMENTED"
        return 2
    elif [ $status -ne 0 ]; then
        echo "null"
        return 1
    fi

    # Parse JSON to find reminder for this actionId
    if command -v jq &> /dev/null; then
        # Match reminder by the actionId field that the server now includes in each Action.
        local dueDate
        dueDate=$(echo "$response" | jq -r ".reminders[] | select(.action.actionId == \"$actionId\") | .dueDate" 2>/dev/null | head -1)

        if [ -z "$dueDate" ] || [ "$dueDate" = "null" ]; then
            echo "null"
            return 0
        fi

        echo "$dueDate"
        return 0
    else
        log_warning "jq not installed - can't parse JSON"
        echo "null"
        return 1
    fi
}

# Expect a reminder (validation function)
expectReminder() {
    local actionId="$1"
    local expectedDate="$2"
    local description="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo ""
    echo "=========================================="
    if [ -n "$description" ]; then
        log_info "Test: $description"
    fi
    log_info "Checking reminder for: $actionId"
    log_info "Expected date: $expectedDate"

    # Get the actual reminder from the API
    local actualDate=$(getReminderForAction "$actionId")
    local status=$?

    if [ $status -eq 2 ]; then
        log_warning "Reminders endpoint not yet implemented - skipping test"
        TESTS_RUN=$((TESTS_RUN - 1))  # Don't count this test
        return 0
    fi

    log_info "Actual date: $actualDate"

    # Compare dates
    if [[ "$actualDate" == "$expectedDate" ]]; then
        log_success "Reminder matches expected value!"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    elif [[ "$actualDate" == "null" ]] && [[ "$expectedDate" == "null" ]]; then
        log_success "Correctly returns null (insufficient data)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Reminder mismatch!"
        log_error "  Expected: $expectedDate"
        log_error "  Got: $actualDate"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Clean up test data
cleanup() {
    local actionId="$1"
    log_info "Cleaning up action: $actionId"
    api_request DELETE "/v1/actions/$actionId" > /dev/null 2>&1 || true
}

# Print test summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed"
        exit 1
    fi
}
