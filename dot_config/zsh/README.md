# Zsh Configuration

This directory contains the Zsh configuration (`$ZDOTDIR`) following a modular structure inspired by [zdotdir](https://github.com/mattmc3/zdotdir).

## Structure

```
~/.config/zsh/
├── .zshenv              # Environment variables and XDG setup
├── .zshrc               # Interactive shell configuration
├── .zstyles             # Zstyle settings for plugins
├── .zsh_plugins.txt     # Antidote plugin list
├── lib/
│   └── antidote.zsh     # Antidote plugin manager loader
├── conf.d/
│   └── __init__.zsh     # Initial configuration (runs first)
├── functions/           # Custom Zsh functions
└── completions/         # Custom completion scripts
```

## Plugin Management

This configuration uses [Antidote](https://github.com/mattmc3/antidote) for plugin management. Plugins are defined in `.zsh_plugins.txt` and are automatically loaded.

### Key Features

- **Modular Configuration**: Configuration is split into separate files in `conf.d/` for easier maintenance
- **Plugin Management**: Antidote provides fast, declarative plugin loading
- **XDG Compliance**: Respects XDG Base Directory specification
- **Performance**: Includes profiling support with `zprofrc` alias
- **Custom Functions**: Autoload custom functions from `functions/` directory
- **Completions**: Custom completions from `completions/` directory

## Adding Plugins

Edit `.zsh_plugins.txt` and add plugin entries. For example:

```
# Add a GitHub plugin
username/repo

# Add a specific path
ohmyzsh/ohmyzsh path:plugins/git

# Conditional loading (macOS only)
mattmc3/zsh_custom path:plugins/macos conditional:is-macos
```

After editing, restart your shell or run `exec zsh` to reload.

## Adding Custom Configuration

Place custom configuration files in `conf.d/`. They will be automatically loaded in alphabetical order (after `__init__.zsh` which always runs first).

Example:

```bash
# Create a new config file
echo "alias myalias='command'" > ~/.config/zsh/conf.d/aliases.zsh
```

## Adding Custom Functions

Place function files in `functions/`. Each file should contain a single function with the same name as the file.

Example:

```bash
# Create a new function
cat > ~/.config/zsh/functions/myfunc <<'EOF'
#!/bin/zsh
# Description of what this function does
myfunc() {
  echo "Hello from myfunc"
}
EOF
```

## Profiling

To profile your Zsh startup time:

```bash
zprofrc
```

This will start a new Zsh session with profiling enabled and display the results.

## Integration with Chezmoi

Since this is managed by [chezmoi](https://www.chezmoi.io/), files are prefixed with `dot_` in the repository:

- `dot_zshenv` → `~/.config/zsh/.zshenv`
- `dot_zshrc` → `~/.config/zsh/.zshrc`
- `dot_zstyles` → `~/.config/zsh/.zstyles`
- etc.

To edit and apply changes:

```bash
chezmoi edit --apply ~/.config/zsh/.zshrc
```

## Resources

- [Antidote Documentation](https://getantidote.github.io/)
- [mattmc3/zdotdir](https://github.com/mattmc3/zdotdir) - Reference implementation
- [Zsh Documentation](http://zsh.sourceforge.net/Doc/)
