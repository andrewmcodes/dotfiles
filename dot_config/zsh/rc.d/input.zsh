#
# Input/Output Configuration
#

# VI Mode
bindkey -v

# Colors
autoload -U colors && colors

#
# Directory Navigation
#
setopt AUTO_CD                # Change directory without cd command
setopt AUTO_PUSHD            # Make cd push directories to the stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicate directories
setopt PUSHD_SILENT          # Don't print the directory stack after pushd/popd
setopt PUSHD_TO_HOME         # pushd without args acts like pushd $HOME

# Only enable in zsh >= 5.8
autoload -Uz is-at-least && if is-at-least 5.8; then
    setopt CD_SILENT         # Don't print working directory after cd
fi

#
# Globbing and Completion
#
unsetopt case_glob           # Case-insensitive globbing
setopt globdots              # Include dotfiles in globbing
setopt EXTENDED_GLOB         # Extended globbing patterns for #, ~, and ^
setopt brace_ccl            # Allow brace character class list expansion
WORDCHARS=${WORDCHARS//[\/]/}  # Remove path separator from WORDCHARS

#
# Input Behavior
#
setopt CORRECT              # Command spelling correction
setopt combining_chars      # Combine zero-length punctuation chars with base char
setopt rc_quotes           # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
setopt INTERACTIVE_COMMENTS # Allow # comments in interactive shell
setopt NO_CLOBBER         # Prevent accidental file overwrite with >
setopt no_beep            # No beep on error

# Spelling correction prompt customization
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

#
# Job Control
#
setopt auto_resume          # Resume existing job before creating new process
setopt notify              # Immediate job status notification
setopt LONG_LIST_JOBS      # Verbose jobs listing
setopt NO_BG_NICE         # Don't reduce background job priority
setopt NO_CHECK_JOBS      # Don't check jobs on shell exit
setopt NO_HUP             # Don't send SIGHUP to jobs on shell exit

#
# Miscellaneous
#
unsetopt mail_warning      # Don't warn about mail file access
