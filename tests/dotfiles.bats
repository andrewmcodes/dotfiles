#!/usr/bin/env bats
# Dotfile backup and restore suite.
#
# Tests A-C are repository-internal and run anywhere. Tests D-K exercise mise
# against an isolated fake HOME inside $BATS_TEST_TMPDIR. Nothing in this file
# may write to the real $HOME; tests/test_helper.bash aborts if isolation fails.
#
# Tests J cover the safety guards: the failure modes that would otherwise let a
# backup look healthy while silently covering less than it claims.

setup() {
	load 'test_helper'
	MANIFEST="${REPO_ROOT}/config/dotfiles-manifest.tsv"
	BASELINE="${REPO_ROOT}/config/chezmoi-baseline.txt"
}

# --- Test A: baseline coverage -------------------------------------------------

@test "A: every baseline path has a manifest row" {
	local baseline_count manifest_count missing=0 relative

	baseline_count="$(grep -vc '^[[:space:]]*$' "$BASELINE")"
	manifest_count="$(cut -f1 "$MANIFEST" | grep -vc '^[[:space:]]*$')"

	while IFS= read -r relative; do
		[[ -n "$relative" ]] || continue
		if ! cut -f1 "$MANIFEST" | grep -qxF "$relative"; then
			echo "missing from manifest: $relative"
			missing=$((missing + 1))
		fi
	done < "$BASELINE"

	echo "chezmoi baseline: ${baseline_count}"
	echo "mise backup: ${manifest_count}"
	echo "covered: $((baseline_count - missing))"
	echo "missing: ${missing}"

	[ "$missing" -eq 0 ]
	[ "$baseline_count" -eq "$manifest_count" ]
}

# --- Test B: manifest integrity ------------------------------------------------

@test "B: every manifest source exists, is a regular file, and matches its checksum" {
	local relative source sha mode size abs actual errors=0

	while IFS=$'\t' read -r relative source sha mode size; do
		[[ -n "$relative" ]] || continue
		abs="${REPO_ROOT}/${source}"

		if [[ "$source" != "home/${relative}" ]]; then
			echo "source path mismatch: $relative -> $source"
			errors=$((errors + 1))
			continue
		fi
		if [[ -L "$abs" ]]; then
			echo "source is a symlink: $source"
			errors=$((errors + 1))
			continue
		fi
		if [[ ! -f "$abs" ]]; then
			echo "source missing: $source"
			errors=$((errors + 1))
			continue
		fi
		actual="$(shasum -a 256 "$abs" | cut -d' ' -f1)"
		if [[ "$actual" != "$sha" ]]; then
			echo "checksum mismatch: $source"
			errors=$((errors + 1))
		fi
		[[ "$mode" =~ ^[0-7]{3,4}$ ]] || {
			echo "bad mode: $relative -> $mode"
			errors=$((errors + 1))
		}
		[[ "$size" =~ ^[0-9]+$ ]] || {
			echo "bad size: $relative -> $size"
			errors=$((errors + 1))
		}
	done < "$MANIFEST"

	[ "$errors" -eq 0 ]
}

@test "B: manifest has no duplicate target or source" {
	run bash -c "cut -f1 '$MANIFEST' | sort | uniq -d"
	[ "$status" -eq 0 ]
	[ -z "$output" ]

	run bash -c "cut -f2 '$MANIFEST' | sort | uniq -d"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

# --- Test C: config safety -----------------------------------------------------

@test "C: every dotfile entry is copy mode with no symlink entries" {
	# Inspect the entries in the [dotfiles] table only, with comment lines and
	# trailing comments stripped, so prose about symlinks cannot trip the check.
	local entries
	entries="$(awk '
		/^\[dotfiles\]/ { f = 1; next }
		/^\[/           { f = 0 }
		f && /=/ && $0 !~ /^[[:space:]]*#/ { sub(/#.*$/, ""); print }
	' "${REPO_ROOT}/mise.toml")"

	[ -n "$entries" ]

	# 39 entries covering the 43 managed files.
	local count
	count="$(printf '%s\n' "$entries" | wc -l | tr -d ' ')"
	[ "$count" -eq 39 ]

	# Every entry states mode = "copy".
	run bash -c "printf '%s\n' \"\$1\" | grep -vc 'mode = \"copy\"'" _ "$entries"
	[ "$output" = "0" ]

	# No entry uses a symlink mode.
	run bash -c "printf '%s\n' \"\$1\" | grep -cE 'symlink'" _ "$entries"
	[ "$output" = "0" ]
}

@test "C: no directory entry on a tree holding untracked local files" {
	# ~/.config/mise/config.local.toml carries a token and ~/.claude holds
	# settings.local.json; a directory entry would sweep them into the repo.
	for forbidden in '"~/.config"' '"~/.config/mise"' '"~/.claude"'; do
		run grep -F "${forbidden} =" "${REPO_ROOT}/mise.toml"
		[ "$status" -ne 0 ]
	done
}

@test "C: verifier passes in repository-only mode" {
	run "${REPO_ROOT}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 0 ]
	[[ "$output" == *"errors=0"* ]]
}

# --- Test D: full restore into an empty HOME -----------------------------------

@test "D: restore into an empty HOME yields real files with recorded modes" {
	isolate_home

	run mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles apply --yes
	[ "$status" -eq 0 ]

	run "${REPO_ROOT}/scripts/apply-dotfile-modes.sh"
	[ "$status" -eq 0 ]

	local relative source sha mode size live errors=0
	while IFS=$'\t' read -r relative source sha mode size; do
		[[ -n "$relative" ]] || continue
		live="${HOME}/${relative}"

		if [[ -L "$live" ]]; then
			echo "restored as symlink: $relative"
			errors=$((errors + 1))
			continue
		fi
		if [[ ! -f "$live" ]]; then
			echo "not restored: $relative"
			errors=$((errors + 1))
			continue
		fi
		if ! cmp -s "${REPO_ROOT}/${source}" "$live"; then
			echo "content differs: $relative"
			errors=$((errors + 1))
		fi
		if [[ "$(stat -f '%Lp' "$live")" != "$mode" ]]; then
			echo "mode differs: $relative got $(stat -f '%Lp' "$live") want $mode"
			errors=$((errors + 1))
		fi
	done < "$MANIFEST"

	[ "$errors" -eq 0 ]
}

@test "D: restore creates no symlinks anywhere under HOME" {
	isolate_home

	mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles apply --yes

	run bash -c "find '$HOME' -type l | head"
	[ -z "$output" ]
}

# --- Test E: idempotent restore ------------------------------------------------

@test "E: a second apply changes nothing and status reports converged" {
	isolate_home

	mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles apply --yes
	local before
	before="$(find "$HOME" -type f -exec shasum -a 256 {} + | sort)"

	run mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles apply --yes
	[ "$status" -eq 0 ]

	local after
	after="$(find "$HOME" -type f -exec shasum -a 256 {} + | sort)"
	[ "$before" = "$after" ]

	run mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles status --missing
	[ "$status" -eq 0 ]
}

# --- Test F: drift detection ---------------------------------------------------

@test "F: modifying a restored file makes status --missing fail" {
	isolate_home

	mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles apply --yes

	run mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles status --missing
	[ "$status" -eq 0 ]

	local target
	target="$(first_text_target "$MANIFEST")"
	[ -n "$target" ]
	printf 'drifted by the test suite\n' > "${HOME}/${target}"

	run mise_with "${REPO_ROOT}/mise.toml" bootstrap dotfiles status --missing
	[ "$status" -eq 1 ]
}

# --- Test G: live to repo capture ----------------------------------------------

@test "G: capture copies a live edit into the repo without touching the live file" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	mise_with "${repo}/mise.toml" bootstrap dotfiles apply --yes

	local target
	target="$(first_text_target "${repo}/config/dotfiles-manifest.tsv")"
	[ -n "$target" ]

	local live="${HOME}/${target}"
	printf 'edited live, must win\n' > "$live"
	chmod 0600 "$live"

	local before_mtime before_sha
	before_mtime="$(stat -f '%Fm' "$live")"
	before_sha="$(shasum -a 256 "$live" | cut -d' ' -f1)"

	run mise_with "${repo}/mise.toml" bootstrap dotfiles add "$live" --no-apply -y
	if [ "$status" -ne 0 ]; then
		echo "capture failed (status=${status}) on mise $(mise --version)"
		echo "target: ${target}"
		echo "output: ${output}"
		false
	fi

	# The repo source now holds the live edit.
	run cat "${repo}/home/${target}"
	[[ "$output" == *"edited live, must win"* ]]

	# The live file is unchanged: still a regular file, same bytes, same mtime.
	[ ! -L "$live" ]
	[ -f "$live" ]
	[ "$(shasum -a 256 "$live" | cut -d' ' -f1)" = "$before_sha" ]
	[ "$(stat -f '%Fm' "$live")" = "$before_mtime" ]

	# No symlink was introduced on either side.
	run bash -c "find '$HOME' '${repo}/home' -type l | head"
	[ -z "$output" ]
}

# --- Test H: a missing live file is never silently deleted ---------------------

@test "H: backup fails when a live file is missing and keeps the repo source" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	mise_with "${repo}/mise.toml" bootstrap dotfiles apply --yes

	local target
	target="$(first_text_target "${repo}/config/dotfiles-manifest.tsv")"
	[ -n "$target" ]

	rm -f "${HOME}/${target}"

	run "${repo}/scripts/backup-dotfiles.sh"
	[ "$status" -ne 0 ]

	# The repo source survived.
	[ -f "${repo}/home/${target}" ]
	[ -s "${repo}/home/${target}" ]

	# Nothing else was removed either.
	local rows sources
	rows="$(cut -f2 "${repo}/config/dotfiles-manifest.tsv" | wc -l | tr -d ' ')"
	sources="$(cut -f2 "${repo}/config/dotfiles-manifest.tsv" | while IFS= read -r s; do [ -f "${repo}/${s}" ] && echo x; done | wc -l | tr -d ' ')"
	[ "$rows" = "$sources" ]
}

# --- Test I: path safety -------------------------------------------------------

@test "I: unsafe target paths are rejected" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	run "${repo}/scripts/backup-dotfiles.sh" "../outside"
	[ "$status" -ne 0 ]

	run "${repo}/scripts/backup-dotfiles.sh" "/absolute/outside/home"
	[ "$status" -ne 0 ]

	run "${repo}/scripts/backup-dotfiles.sh" "$HOME/../escape"
	[ "$status" -ne 0 ]
}

@test "I: an unconfigured target is refused rather than added" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	printf 'not managed\n' > "${HOME}/.brand-new-file"
	local cfg_before
	cfg_before="$(shasum -a 256 "${repo}/mise.toml" | cut -d' ' -f1)"

	run "${repo}/scripts/backup-dotfiles.sh" "${HOME}/.brand-new-file"
	[ "$status" -ne 0 ]

	# The config was not rewritten and no stray source appeared.
	[ "$(shasum -a 256 "${repo}/mise.toml" | cut -d' ' -f1)" = "$cfg_before" ]
	[ ! -e "${repo}/home/.brand-new-file" ]
	[ ! -d "${HOME}/.dotfiles" ]
}

# --- Isolation self-check ------------------------------------------------------

@test "isolation: mise never reads the real user's global config" {
	isolate_home
	run assert_no_real_config_leak "${REPO_ROOT}/mise.toml"
	[ "$status" -eq 0 ]
}

# --- Test J: safety guards -----------------------------------------------------
#
# These cover the failure modes that make a backup look healthy while it is not.
# Each runs against a throwaway copy of the repository.

@test "J: an unmanaged file in home/ fails verification" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 0 ]

	# A directory entry re-imports whatever the live tree holds, so an untracked
	# local file can reach home/ without ever getting a manifest row.
	printf 'leaked\n' > "${repo}/home/.warp/workflows/leaked.yaml"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 1 ]
	[[ "$output" == *"unmanaged-source"* ]]
	[[ "$output" == *"leaked.yaml"* ]]
}

@test "J: a missing baseline never truncates the manifest" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	local before rows_before
	before="$(shasum -a 256 "${repo}/config/dotfiles-manifest.tsv" | cut -d' ' -f1)"
	rows_before="$(wc -l < "${repo}/config/dotfiles-manifest.tsv" | tr -d ' ')"

	rm -f "${repo}/config/chezmoi-baseline.txt"

	run "${repo}/scripts/backup-dotfiles.sh"
	[ "$status" -ne 0 ]

	# The committed manifest must survive intact.
	[ "$(shasum -a 256 "${repo}/config/dotfiles-manifest.tsv" | cut -d' ' -f1)" = "$before" ]
	[ "$(wc -l < "${repo}/config/dotfiles-manifest.tsv" | tr -d ' ')" = "$rows_before" ]
}

@test "J: an empty dotfiles table fails verification instead of passing vacuously" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	printf '[settings]\ndotfiles.default_mode = "copy"\ndotfiles.root = "home"\n\n[dotfiles]\n' \
		> "${repo}/mise.toml"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 1 ]
	[[ "$output" == *"no-dotfile-entries"* ]]
}

@test "J: a manifest path with no configured entry fails verification" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	# Drop one entry from the config but leave its manifest row in place.
	grep -v '^"~/.editorconfig"' "${repo}/mise.toml" > "${repo}/mise.toml.tmp"
	mv "${repo}/mise.toml.tmp" "${repo}/mise.toml"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 1 ]
	[[ "$output" == *".editorconfig"* ]]
}

@test "J: a malformed manifest mode is refused and the live file is left alone" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	mise_with "${repo}/mise.toml" bootstrap dotfiles apply --yes

	awk -F'\t' 'BEGIN { OFS = "\t" } $1 == ".editorconfig" { $4 = "XYZ" } { print }' \
		"${repo}/config/dotfiles-manifest.tsv" > "${repo}/config/m.tmp"
	mv "${repo}/config/m.tmp" "${repo}/config/dotfiles-manifest.tsv"

	local before
	before="$(stat -f '%Lp' "${HOME}/.editorconfig")"

	run "${repo}/scripts/apply-dotfile-modes.sh"
	[ "$status" -ne 0 ]
	[[ "$output" == *"bad recorded mode"* ]]

	# chmod never ran on the live file.
	[ "$(stat -f '%Lp' "${HOME}/.editorconfig")" = "$before" ]
}

@test "J: restore refuses contradictory flags rather than writing" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	# --apply --dry-run must not be read as --apply.
	run "${repo}/scripts/restore-dotfiles.sh" --apply --dry-run
	[ "$status" -eq 2 ]
	[ ! -e "${HOME}/.editorconfig" ]

	run "${repo}/scripts/restore-dotfiles.sh" --bogus
	[ "$status" -eq 2 ]
}

@test "J: the fingerprint refuses to write inside \$HOME" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	run "${repo}/scripts/fingerprint-home.sh" "${HOME}/fingerprint.tsv"
	[ "$status" -eq 2 ]
	[ ! -e "${HOME}/fingerprint.tsv" ]

	# A symlink pointing back into $HOME must not slip past the guard.
	mkdir -p "${BATS_TEST_TMPDIR}/link"
	ln -s "$HOME" "${BATS_TEST_TMPDIR}/link/home"
	run "${repo}/scripts/fingerprint-home.sh" "${BATS_TEST_TMPDIR}/link/home/fp.tsv"
	[ "$status" -eq 2 ]
}

@test "J: a manifest mode whose executable bit contradicts the repo source fails verification" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 0 ]

	# Git carries the executable bit, so it is the one mode bit the verifier
	# can defend without a live $HOME. .editorconfig's source is not
	# executable; a 755 manifest row for it is corruption.
	awk -F'\t' 'BEGIN { OFS = "\t" } $1 == ".editorconfig" { $4 = "755" } { print }' \
		"${repo}/config/dotfiles-manifest.tsv" > "${repo}/config/m.tmp"
	mv "${repo}/config/m.tmp" "${repo}/config/dotfiles-manifest.tsv"

	run "${repo}/scripts/verify-dotfiles.sh" --no-live
	[ "$status" -eq 1 ]
	[[ "$output" == *"mode-exec-mismatch"* ]]
}

# --- Test K: adding a new dotfile ------------------------------------------------

@test "K: the documented add-a-dotfile steps capture a brand-new file" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	mise_with "${repo}/mise.toml" bootstrap dotfiles apply --yes
	# Backup ends with a live-mode verify, so the sandbox needs real modes.
	run "${repo}/scripts/apply-dotfile-modes.sh"
	[ "$status" -eq 0 ]

	printf 'brand new managed file\n' > "${HOME}/.newdotfile"
	chmod 0600 "${HOME}/.newdotfile"

	# Step 1: the [dotfiles] entry with explicit copy mode.
	awk '{ print } /^\[dotfiles\]$/ {
		print "\"~/.newdotfile\" = { source = \"home/.newdotfile\", mode = \"copy\" }"
	}' "${repo}/mise.toml" > "${repo}/mise.toml.tmp"
	mv "${repo}/mise.toml.tmp" "${repo}/mise.toml"

	# Step 2: the baseline row.
	printf '.newdotfile\n' >> "${repo}/config/chezmoi-baseline.txt"

	# Step 3: a plain backup run must capture it.
	run "${repo}/scripts/backup-dotfiles.sh"
	[ "$status" -eq 0 ]

	[ -f "${repo}/home/.newdotfile" ]
	run cat "${repo}/home/.newdotfile"
	[[ "$output" == *"brand new managed file"* ]]

	run bash -c "cut -f1,4 '${repo}/config/dotfiles-manifest.tsv' | grep -x '.newdotfile	600'"
	[ "$status" -eq 0 ]

	# The live file was not touched and nothing became a symlink.
	[ ! -L "${HOME}/.newdotfile" ]
	[ "$(stat -f '%Lp' "${HOME}/.newdotfile")" = "600" ]
}

@test "J: a partial fingerprint is never written" {
	isolate_home
	local repo
	repo="$(copy_repo)"

	mise_with "${repo}/mise.toml" bootstrap dotfiles apply --yes
	rm -f "${HOME}/.editorconfig"

	local out="${BATS_TEST_TMPDIR}/partial.tsv"
	run "${repo}/scripts/fingerprint-home.sh" "$out"
	[ "$status" -ne 0 ]

	# Diffing a truncated fingerprint would report spurious $HOME changes.
	[ ! -e "$out" ]
}
