#!/bin/bash
# Slurm Cluster BATS Test Runner

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/slurm_tests_${TIMESTAMP}.log"
HTML_REPORT="${LOG_DIR}/slurm_tests_${TIMESTAMP}.html"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to display usage
show_usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help              Display this help message"
  echo "  -f, --filter PATTERN    Only run tests that match the pattern"
  echo "  -s, --skip PATTERN      Skip tests that match the pattern"
  echo "  -e, --env-only          Only run environment tests"
  echo "  -j, --job-only          Only run job submission tests"
  echo "  -c, --cleanup           Clean up test environment after running"
  echo "  -v, --verbose           Enable verbose output"
}

# Parse command-line arguments
BATS_ARGS=()
TEST_FILES=("${SCRIPT_DIR}/0"*.bats) # Default: run all test files
VERBOSE=""
CLEANUP=0

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -h | --help)
    show_usage
    exit 0
    ;;
  -f | --filter)
    BATS_ARGS+=("--filter" "$2")
    shift 2
    ;;
  -s | --skip)
    BATS_ARGS+=("--filter-tags" "!$2")
    shift 2
    ;;
  -e | --env-only)
    TEST_FILES=("${SCRIPT_DIR}/01-environment.bats" "${SCRIPT_DIR}/02-daemons.bats")
    shift
    ;;
  -j | --job-only)
    TEST_FILES=("${SCRIPT_DIR}/03-submission.bats" "${SCRIPT_DIR}/04-multinode.bats")
    shift
    ;;
  -c | --cleanup)
    CLEANUP=1
    shift
    ;;
  -v | --verbose)
    VERBOSE="--verbose"
    shift
    ;;
  *)
    # Assume anything else is a specific test file to run
    if [[ -f "$key" ]]; then
      TEST_FILES=("$key")
    elif [[ -f "${SCRIPT_DIR}/$key" ]]; then
      TEST_FILES=("${SCRIPT_DIR}/$key")
    else
      echo "Unknown option or file not found: $key"
      show_usage
      exit 1
    fi
    shift
    ;;
  esac
done

# Display header
echo "=== Slurm Cluster BATS Test Suite ==="
echo "Started at: $(date)"
echo "Log file: $LOG_FILE"
echo

# Execute BATS tests
# We use a subshell and tee to capture output while still showing it in the terminal
# Make sure we're in the script directory when running tests
(
  cd "$SCRIPT_DIR"
  if [[ -n "$VERBOSE" ]]; then
    bats $VERBOSE "${BATS_ARGS[@]}" "${TEST_FILES[@]}"
  else
    bats "${BATS_ARGS[@]}" "${TEST_FILES[@]}"
  fi
) | tee -a "$LOG_FILE"

# Extract test results - fix the parsing to avoid arithmetic errors
# Get the total number of tests from the "1..N" line
TESTS_TOTAL=0
TOTAL_LINE=$(grep -m 1 "^1\.\." "$LOG_FILE")
if [[ -n "$TOTAL_LINE" ]]; then
  TESTS_TOTAL=$(echo "$TOTAL_LINE" | cut -d'.' -f3)
  # Ensure we have a valid number
  if ! [[ "$TESTS_TOTAL" =~ ^[0-9]+$ ]]; then
    TESTS_TOTAL=0
  fi
fi

# Count failed tests
TESTS_FAILED=0
FAILED_COUNT=$(grep -c "^not ok" "$LOG_FILE")
if [[ -n "$FAILED_COUNT" && "$FAILED_COUNT" =~ ^[0-9]+$ ]]; then
  TESTS_FAILED=$FAILED_COUNT
fi

# Calculate passed tests and success rate
TESTS_PASSED=$((TESTS_TOTAL - TESTS_FAILED))
if [[ "$TESTS_PASSED" -lt 0 ]]; then
  TESTS_PASSED=0
fi

SUCCESS_RATE=0
if [[ $TESTS_TOTAL -gt 0 ]]; then
  SUCCESS_RATE=$((100 * TESTS_PASSED / TESTS_TOTAL))
fi

# Display summary
echo -e "\n=== TEST SUMMARY ==="
echo "Total tests: $TESTS_TOTAL"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Success rate: ${SUCCESS_RATE}%"
echo "Completed at: $(date)"
echo "Log file: $LOG_FILE"
echo "HTML Report: $HTML_REPORT"

# Generate HTML report
cat >"$HTML_REPORT" <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Slurm Cluster Test Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #336699; }
    .summary { background-color: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    .pass { color: green; }
    .fail { color: red; }
    pre { background-color: #f8f8f8; padding: 10px; border-radius: 5px; overflow: auto; }
  </style>
</head>
<body>
  <h1>Slurm Cluster Test Report</h1>
  <div class="summary">
    <p><strong>Date:</strong> $(date)</p>
    <p><strong>Total tests:</strong> $TESTS_TOTAL</p>
    <p><strong>Passed:</strong> <span class="pass">$TESTS_PASSED</span></p>
    <p><strong>Failed:</strong> <span class="fail">$TESTS_FAILED</span></p>
    <p><strong>Success rate:</strong> ${SUCCESS_RATE}%</p>
  </div>
  <h2>Test Results</h2>
  <pre>$(cat "$LOG_FILE" | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g')</pre>
</body>
</html>
EOF

echo "HTML Report: $HTML_REPORT"

# Clean up if requested
if [[ $CLEANUP -eq 1 ]]; then
  echo -e "\nCleaning up test environment..."
  # Source config.sh only for cleanup
  if [ -f "${SCRIPT_DIR}/config.sh" ]; then
    source "${SCRIPT_DIR}/config.sh"
    ssh $CONTROLLER "rm -rf $TEST_DIR" || true
    echo "Cleanup completed."
  else
    echo "Warning: config.sh not found, skipping cleanup."
  fi
fi

# Return appropriate exit code
if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed. Check log for details."
  exit 1
fi