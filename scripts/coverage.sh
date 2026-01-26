#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Generate code coverage report locally using kcov

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COVERAGE_DIR="${REPO_ROOT}/coverage"

# Source common library
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Check if kcov is installed
check_kcov() {
	if ! command -v kcov >/dev/null 2>&1; then
		log_error "kcov not installed"
		log_info ""
		log_info "Install kcov with:"
		if [[ "$OSTYPE" == "darwin"* ]]; then
			log_info "  brew install kcov"
		else
			log_info "  sudo apt-get install kcov"
		fi
		return 1
	fi
}

# Generate coverage for all tests
generate_coverage() {
	log_header "Generating Code Coverage"

	# Check for kcov
	if ! check_kcov; then
		return 1
	fi

	# Clean coverage directory
	log_info "Cleaning coverage directory..."
	rm -rf "$COVERAGE_DIR"
	mkdir -p "$COVERAGE_DIR"

	log_info "Running tests with coverage..."

	# Find all bats test files in unit tests
	local test_count=0
	while IFS= read -r test_file; do
		((test_count++))
		log_info "[$test_count] Running: $(basename "$test_file")"

		# Run kcov with test file
		kcov \
			--exclude-pattern=/usr/include,/tmp,/opt/homebrew \
			"$COVERAGE_DIR/$(basename "$test_file" .bats)" \
			"$test_file" || log_warning "Test failed: $test_file"
	done < <(find "${REPO_ROOT}/tests/unit" -name "*.bats" -type f)

	log_info ""
	log_success "Coverage generation complete!"
	log_info "Coverage report: $COVERAGE_DIR/index.html"

	# Open report in browser on macOS
	if [[ "$OSTYPE" == "darwin"* ]]; then
		log_info "Opening coverage report in browser..."
		open "$COVERAGE_DIR/index.html" 2>/dev/null || true
	fi
}

# Show help
show_help() {
	cat <<EOF
Code Coverage Script

Usage: $0 [OPTIONS]

Generates code coverage reports for bash scripts using kcov.

Options:
  -h, --help    Show this help message

Requirements:
  - kcov must be installed
  - bats-core must be installed

Example:
  $0

EOF
}

# Main entry point
main() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		show_help
		exit 0
	fi

	generate_coverage
}

main "$@"
