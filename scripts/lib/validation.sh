#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2119,SC2120
# Configuration validation utilities

# Prevent double-sourcing
if [[ -n "${_VALIDATION_SH_LOADED:-}" ]]; then
	return 0
fi
readonly _VALIDATION_SH_LOADED=1

# Source common functions for logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# Mise validation
validate_mise_config() {
	local config_file="$1"

	if [[ ! -f "$config_file" ]]; then
		log_error "Mise config not found: $config_file"
		return 1
	fi

	# Check for [tools] section
	if ! grep -q '^\[tools\]' "$config_file"; then
		log_error "Mise config missing [tools] section"
		return 1
	fi

	log_success "Mise config validation passed"
}


# Git config validation
validate_git_config() {
	local git_config="$1"

	if [[ ! -f "$git_config" ]]; then
		log_error "Git config not found: $git_config"
		return 1
	fi

	# Check for required sections
	local required_sections=("user" "core")
	for section in "${required_sections[@]}"; do
		if ! grep -q "^\[$section\]" "$git_config"; then
			log_error "Git config missing [$section] section"
			return 1
		fi
	done

	log_success "Git config validation passed"
}

# Shell config validation
validate_shell_config() {
	local shell_config="$1"

	if [[ ! -f "$shell_config" ]]; then
		log_error "Shell config not found: $shell_config"
		return 1
	fi

	# Check for syntax errors (basic)
	if bash -n "$shell_config" 2>/dev/null; then
		log_success "Shell config syntax valid"
	else
		log_error "Shell config has syntax errors"
		return 1
	fi
}

# Brewfile validation
validate_brewfile() {
	local brewfile="$1"

	if [[ ! -f "$brewfile" ]]; then
		log_error "Brewfile not found: $brewfile"
		return 1
	fi

	# Check for valid Homebrew commands
	if ! grep -qE "^(tap|brew|cask|mas)" "$brewfile"; then
		log_warning "Brewfile may be empty or malformed"
	fi

	log_success "Brewfile validation passed"
}

# Chezmoi validation
validate_chezmoi_dir() {
	local chezmoi_dir="${1:-$HOME/.local/share/chezmoi}"

	if [[ ! -d "$chezmoi_dir" ]]; then
		log_error "Chezmoi directory not found: $chezmoi_dir"
		return 1
	fi

	if [[ ! -d "$chezmoi_dir/.git" ]]; then
		log_error "Chezmoi directory is not a git repository"
		return 1
	fi

	log_success "Chezmoi directory validation passed"
}

# Comprehensive validation
validate_all_configs() {
	local chezmoi_dir="${1:-$HOME/.local/share/chezmoi}"
	local errors=0

	log_header "Validating All Configurations"

	# Mise config
	if [[ -f "$chezmoi_dir/dot_config/mise/config.toml" ]]; then
		validate_mise_config "$chezmoi_dir/dot_config/mise/config.toml" || ((errors++))
	fi

	# Git config
	if [[ -f "$chezmoi_dir/dot_config/git/config" ]]; then
		validate_git_config "$chezmoi_dir/dot_config/git/config" || ((errors++))
	fi

	# Brewfile
	if [[ -f "$chezmoi_dir/Brewfile" ]]; then
		validate_brewfile "$chezmoi_dir/Brewfile" || ((errors++))
	fi

	if [[ $errors -eq 0 ]]; then
		log_success "All configuration validations passed"
		return 0
	else
		log_error "Configuration validation failed with $errors error(s)"
		return 1
	fi
}
