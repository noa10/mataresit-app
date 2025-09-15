#!/bin/bash

# iOS Testing Automation Script
# Runs comprehensive iOS testing suite and generates reports

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_REPORTS_DIR="$PROJECT_ROOT/test_reports"
LOGS_DIR="$PROJECT_ROOT/test_logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print header
print_header() {
    echo "=================================================="
    echo "         iOS Testing Automation Script"
    echo "=================================================="
    echo "Project: Mataresit Flutter App"
    echo "Phase: 3 - Testing and Validation"
    echo "Date: $(date)"
    echo "=================================================="
    echo
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS testing requires macOS"
        exit 1
    fi
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    
    # Check iOS Simulator
    if ! xcrun simctl list devices | grep -q "iPhone"; then
        log_error "No iOS simulators found"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create directories
    mkdir -p "$TEST_REPORTS_DIR"
    mkdir -p "$LOGS_DIR"
    
    # Clean previous test results
    rm -rf "$TEST_REPORTS_DIR"/*
    rm -rf "$LOGS_DIR"/*
    
    # Navigate to project root
    cd "$PROJECT_ROOT"
    
    # Get Flutter dependencies
    log_info "Getting Flutter dependencies..."
    flutter pub get
    
    # Clean build
    log_info "Cleaning Flutter build..."
    flutter clean
    
    log_success "Test environment setup completed"
}

# Start iOS Simulator
start_ios_simulator() {
    log_info "Starting iOS Simulator..."
    
    # Get available simulators
    local simulators=$(xcrun simctl list devices available | grep "iPhone" | head -1)
    
    if [[ -z "$simulators" ]]; then
        log_error "No available iPhone simulators found"
        exit 1
    fi
    
    # Extract simulator UDID
    local simulator_udid=$(echo "$simulators" | grep -o '[A-F0-9-]\{36\}')
    
    if [[ -z "$simulator_udid" ]]; then
        log_error "Could not extract simulator UDID"
        exit 1
    fi
    
    # Boot simulator
    log_info "Booting simulator: $simulator_udid"
    xcrun simctl boot "$simulator_udid" || true
    
    # Wait for simulator to boot
    log_info "Waiting for simulator to boot..."
    sleep 10
    
    # Verify simulator is booted
    if xcrun simctl list devices | grep "$simulator_udid" | grep -q "Booted"; then
        log_success "iOS Simulator started successfully"
        export IOS_SIMULATOR_UDID="$simulator_udid"
    else
        log_error "Failed to start iOS Simulator"
        exit 1
    fi
}

# Run iOS tests
run_ios_tests() {
    log_info "Running iOS integration tests..."
    
    local test_exit_code=0
    
    # Run integration tests
    log_info "Executing iOS test suite..."
    
    if flutter test integration_test/ios_test_runner.dart --verbose > "$LOGS_DIR/ios_tests.log" 2>&1; then
        log_success "iOS tests completed successfully"
    else
        test_exit_code=$?
        log_error "iOS tests failed with exit code: $test_exit_code"
        
        # Show last 20 lines of test output
        log_info "Last 20 lines of test output:"
        tail -20 "$LOGS_DIR/ios_tests.log"
    fi
    
    return $test_exit_code
}

# Run specific test suites
run_test_suite() {
    local suite_name="$1"
    local test_file="$2"
    
    log_info "Running $suite_name..."
    
    local suite_log="$LOGS_DIR/${suite_name,,}_tests.log"
    
    if flutter test "$test_file" --verbose > "$suite_log" 2>&1; then
        log_success "$suite_name completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "$suite_name failed with exit code: $exit_code"
        
        # Show test failures
        if grep -q "FAILED" "$suite_log"; then
            log_info "Test failures in $suite_name:"
            grep "FAILED" "$suite_log" | head -10
        fi
        
        return $exit_code
    fi
}

# Generate test reports
generate_test_reports() {
    log_info "Generating test reports..."
    
    # Check if test reports were generated
    if [[ -f "$TEST_REPORTS_DIR/ios_test_report.json" ]]; then
        log_success "JSON test report generated"
    else
        log_warning "JSON test report not found"
    fi
    
    if [[ -f "$TEST_REPORTS_DIR/ios_test_report.html" ]]; then
        log_success "HTML test report generated"
    else
        log_warning "HTML test report not found"
    fi
    
    if [[ -f "$TEST_REPORTS_DIR/ios_test_report.md" ]]; then
        log_success "Markdown test report generated"
    else
        log_warning "Markdown test report not found"
    fi
    
    # Generate summary report
    generate_summary_report
}

# Generate summary report
generate_summary_report() {
    local summary_file="$TEST_REPORTS_DIR/test_summary.txt"
    
    {
        echo "iOS Test Suite Summary"
        echo "======================"
        echo "Date: $(date)"
        echo "Project: Mataresit Flutter App"
        echo "Phase: 3 - Testing and Validation"
        echo ""
        
        # Device information
        echo "Test Environment:"
        echo "- macOS Version: $(sw_vers -productVersion)"
        echo "- Xcode Version: $(xcodebuild -version | head -1)"
        echo "- Flutter Version: $(flutter --version | head -1)"
        echo "- iOS Simulator: ${IOS_SIMULATOR_UDID:-"Not available"}"
        echo ""
        
        # Test results summary
        if [[ -f "$TEST_REPORTS_DIR/ios_test_report.json" ]]; then
            echo "Test Results:"
            # Parse JSON report for summary (requires jq if available)
            if command -v jq &> /dev/null; then
                local total_tests=$(jq -r '.summary.totalTests' "$TEST_REPORTS_DIR/ios_test_report.json")
                local passed_tests=$(jq -r '.summary.totalPassed' "$TEST_REPORTS_DIR/ios_test_report.json")
                local failed_tests=$(jq -r '.summary.totalFailed' "$TEST_REPORTS_DIR/ios_test_report.json")
                local success_rate=$(jq -r '.summary.successRate' "$TEST_REPORTS_DIR/ios_test_report.json")
                
                echo "- Total Tests: $total_tests"
                echo "- Passed: $passed_tests"
                echo "- Failed: $failed_tests"
                echo "- Success Rate: $success_rate%"
            else
                echo "- Detailed results available in ios_test_report.json"
            fi
        else
            echo "Test Results: Report not generated"
        fi
        
        echo ""
        echo "Report Files:"
        echo "- JSON Report: $TEST_REPORTS_DIR/ios_test_report.json"
        echo "- HTML Report: $TEST_REPORTS_DIR/ios_test_report.html"
        echo "- Markdown Report: $TEST_REPORTS_DIR/ios_test_report.md"
        echo "- Test Logs: $LOGS_DIR/"
        
    } > "$summary_file"
    
    log_success "Summary report generated: $summary_file"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."
    
    # Stop iOS Simulator if we started it
    if [[ -n "${IOS_SIMULATOR_UDID:-}" ]]; then
        log_info "Shutting down iOS Simulator..."
        xcrun simctl shutdown "$IOS_SIMULATOR_UDID" || true
    fi
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    print_header
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
    
    # Check command line arguments
    local run_all_tests=true
    local specific_suite=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --suite)
                specific_suite="$2"
                run_all_tests=false
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--suite SUITE_NAME] [--help]"
                echo ""
                echo "Options:"
                echo "  --suite SUITE_NAME  Run specific test suite only"
                echo "  --help             Show this help message"
                echo ""
                echo "Available test suites:"
                echo "  - simulator"
                echo "  - performance"
                echo "  - feature-parity"
                echo "  - edge-cases"
                echo "  - accessibility"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute test pipeline
    check_prerequisites
    setup_test_environment
    start_ios_simulator
    
    local overall_exit_code=0
    
    if [[ "$run_all_tests" == true ]]; then
        # Run all test suites
        log_info "Running comprehensive iOS test suite..."
        
        if ! run_ios_tests; then
            overall_exit_code=1
        fi
    else
        # Run specific test suite
        case "$specific_suite" in
            simulator)
                run_test_suite "iOS Simulator Tests" "test/ios_testing/ios_simulator_tests.dart" || overall_exit_code=1
                ;;
            performance)
                run_test_suite "iOS Performance Tests" "test/ios_testing/ios_performance_tests.dart" || overall_exit_code=1
                ;;
            feature-parity)
                run_test_suite "Feature Parity Tests" "test/ios_testing/feature_parity_tests.dart" || overall_exit_code=1
                ;;
            edge-cases)
                run_test_suite "iOS Edge Case Tests" "test/ios_testing/ios_edge_case_tests.dart" || overall_exit_code=1
                ;;
            accessibility)
                run_test_suite "iOS Accessibility Tests" "test/ios_testing/ios_accessibility_tests.dart" || overall_exit_code=1
                ;;
            *)
                log_error "Unknown test suite: $specific_suite"
                exit 1
                ;;
        esac
    fi
    
    # Generate reports
    generate_test_reports
    
    # Print final status
    echo
    if [[ $overall_exit_code -eq 0 ]]; then
        log_success "iOS testing completed successfully!"
        log_info "Test reports available in: $TEST_REPORTS_DIR"
    else
        log_error "iOS testing completed with failures!"
        log_info "Check test logs in: $LOGS_DIR"
        log_info "Test reports available in: $TEST_REPORTS_DIR"
    fi
    
    exit $overall_exit_code
}

# Run main function
main "$@"
