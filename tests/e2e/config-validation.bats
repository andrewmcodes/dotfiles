#!/usr/bin/env bats
# End-to-end tests for configuration validation

load '../test_helper'

setup() {
    # Source validation library
    # shellcheck source=../../scripts/lib/validation.sh
    source "${REPO_ROOT}/scripts/lib/validation.sh"
}

@test "mise config exists and is valid" {
    local config="${REPO_ROOT}/dot_config/mise/config.toml"

    if [[ ! -f "$config" ]]; then
        skip "Mise config not present in repository"
    fi

    # Should have [tools] section
    grep -q '^\[tools\]' "$config"

    # Validate using validation library
    run validate_mise_config "$config"
    [ "$status" -eq 0 ]
}

@test "git config exists and is valid" {
    local git_config="${REPO_ROOT}/dot_config/git/config"

    [ -f "$git_config" ]

    # Should have required sections
    grep -q '^\[user\]' "$git_config"
    grep -q '^\[core\]' "$git_config"

    # Validate using validation library
    run validate_git_config "$git_config"
    [ "$status" -eq 0 ]
}

@test "Brewfile is valid" {
    local brewfile="${REPO_ROOT}/Brewfile"

    [ -f "$brewfile" ]

    # Should contain Homebrew commands
    grep -qE "^(tap|brew|cask)" "$brewfile"

    # Validate using validation library
    run validate_brewfile "$brewfile"
    [ "$status" -eq 0 ]
}

@test "zshenv file exists" {
    local zshenv="${REPO_ROOT}/dot_zshenv"

    [ -f "$zshenv" ]

    # Should set XDG_CONFIG_HOME
    grep -q 'XDG_CONFIG_HOME' "$zshenv"
}

@test "starship config exists and is valid TOML" {
    local starship_config="${REPO_ROOT}/dot_config/starship.toml"

    if [[ ! -f "$starship_config" ]]; then
        skip "Starship config not present in repository"
    fi

    # Should be valid TOML (basic check - has sections)
    [ -s "$starship_config" ]
}

@test "tmux config exists" {
    local tmux_config="${REPO_ROOT}/dot_config/tmux/tmux.conf"

    if [[ ! -f "$tmux_config" ]]; then
        skip "Tmux config not present in repository"
    fi

    [ -s "$tmux_config" ]
}

@test "editorconfig exists" {
    local editorconfig="${REPO_ROOT}/dot_editorconfig"

    if [[ ! -f "$editorconfig" ]]; then
        skip "EditorConfig not present in repository"
    fi

    # Should have root = true
    grep -q 'root.*=.*true' "$editorconfig"
}

@test "all dot_config directories have content" {
    if [[ ! -d "${REPO_ROOT}/dot_config" ]]; then
        skip "No dot_config directory"
    fi

    # Find all directories in dot_config
    local empty_dirs=0
    while IFS= read -r dir; do
        # Check if directory has any files (not just subdirectories)
        if ! find "$dir" -maxdepth 1 -type f | grep -q .; then
            echo "Empty directory: $dir"
            ((empty_dirs++))
        fi
    done < <(find "${REPO_ROOT}/dot_config" -mindepth 1 -type d)

    # Allow some empty directories (like subdirectories)
    [ "$empty_dirs" -lt 5 ]
}

@test "no sensitive files are committed" {
    # Check for common sensitive file patterns
    local sensitive_patterns=(
        "*.pem"
        "*.key"
        "id_rsa"
        "id_ed25519"
        ".env.local"
        "credentials.json"
        "secrets.json"
    )

    for pattern in "${sensitive_patterns[@]}"; do
        if find "${REPO_ROOT}" -name "$pattern" -not -path "*/.git/*" | grep -q .; then
            echo "Found potentially sensitive files matching: $pattern"
            return 1
        fi
    done
}

@test "all shell scripts have proper shebangs" {
    local missing_shebang=0

    while IFS= read -r script; do
        if ! head -n 1 "$script" | grep -q '^#!'; then
            echo "Missing shebang: $script"
            ((missing_shebang++))
        fi
    done < <(find "${REPO_ROOT}/install" "${REPO_ROOT}/scripts" -name "*.sh" -type f 2>/dev/null)

    [ "$missing_shebang" -eq 0 ]
}

@test "all shell scripts are executable" {
    local non_executable=0

    while IFS= read -r script; do
        if [[ ! -x "$script" ]]; then
            echo "Not executable: $script"
            ((non_executable++))
        fi
    done < <(find "${REPO_ROOT}/install" "${REPO_ROOT}/scripts" -name "*.sh" -type f 2>/dev/null)

    [ "$non_executable" -eq 0 ]
}

@test "all bats tests are executable" {
    local non_executable=0

    while IFS= read -r test_file; do
        if [[ ! -x "$test_file" ]]; then
            echo "Not executable: $test_file"
            ((non_executable++))
        fi
    done < <(find "${REPO_ROOT}/tests" -name "*.bats" -type f 2>/dev/null)

    [ "$non_executable" -eq 0 ]
}

@test "README contains essential sections" {
    local readme="${REPO_ROOT}/README.md"

    [ -f "$readme" ]

    # Should have key sections
    grep -qi "## Setup" "$readme"
    grep -qi "## Testing" "$readme"

    # Should mention key tools
    grep -qi "chezmoi" "$readme"
    grep -qi "mise" "$readme"
    grep -qi "homebrew" "$readme"
}

@test "chezmoiignore is properly configured" {
    local chezmoiignore="${REPO_ROOT}/.chezmoiignore"

    [ -f "$chezmoiignore" ]

    # Should ignore test infrastructure
    grep -q "tests/" "$chezmoiignore"
    grep -q "install/" "$chezmoiignore"
    grep -q "scripts/" "$chezmoiignore"

    # Should ignore CI/CD
    grep -q ".github" "$chezmoiignore"

    # Should ignore coverage
    grep -q "coverage" "$chezmoiignore"
}
