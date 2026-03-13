# Dotfiles

Personal dotfiles and scripts for Windows, Linux and WSL.

## Repository structure

```
.bashrc              # Bash config (cross-platform, auto-launches zsh)
.bash_aliases        # Bash/Zsh aliases and functions (git, PHP, Laravel)
.vimrc               # Vim config (cross-platform)
.zsh                 # Zsh config (cross-platform, no framework)
git-export-diff      # Export git diff to an update folder (cross-platform, bash)
windows/.bin/        # Windows-specific scripts (php.bat, composer.bat)
linux/.envrc         # direnv config for PHP version switching
```

## Installation

### Windows (PowerShell)

```powershell
# Prerequisites
winget install Git.Git
winget install BeyondCode.Herd

# Modern CLI tools
winget install ajeetdsouza.zoxide
winget install eza-community.eza
winget install sharkdp.bat
winget install sharkdp.fd
winget install BurntSushi.ripgrep.MSVC
winget install junegunn.fzf

# Clone the repo
git clone git@github.com:shaffe-fr/dotfiles.git $env:TEMP\dotfiles

# Shell config
Copy-Item $env:TEMP\dotfiles\.bashrc $env:USERPROFILE\.bashrc -Force
Copy-Item $env:TEMP\dotfiles\.bash_aliases $env:USERPROFILE\.bash_aliases -Force
Copy-Item $env:TEMP\dotfiles\.vimrc $env:USERPROFILE\.vimrc -Force
Copy-Item $env:TEMP\dotfiles\.zsh $env:USERPROFILE\.zsh -Force

# PHP & Composer scripts
New-Item -ItemType Directory -Path $env:USERPROFILE\.bin -Force
Copy-Item $env:TEMP\dotfiles\windows\.bin\php.bat $env:USERPROFILE\.bin\php.bat -Force
Copy-Item $env:TEMP\dotfiles\windows\.bin\composer.bat $env:USERPROFILE\.bin\composer.bat -Force

# git-export-diff (usable from Git Bash)
Copy-Item $env:TEMP\dotfiles\git-export-diff $env:USERPROFILE\.bin\git-export-diff -Force

# Cleanup
Remove-Item -Recurse -Force $env:TEMP\dotfiles
```

### Linux / WSL (Bash)

```bash
# Prerequisites
sudo apt install git direnv

# Clone the repo
git clone git@github.com:shaffe-fr/dotfiles.git /tmp/dotfiles

# Shell config
cp /tmp/dotfiles/.bashrc ~/.bashrc
cp /tmp/dotfiles/.bash_aliases ~/.bash_aliases
cp /tmp/dotfiles/.vimrc ~/.vimrc
cp /tmp/dotfiles/.zsh ~/.zsh

# git-export-diff
mkdir -p ~/.bin
cp /tmp/dotfiles/git-export-diff ~/.bin/git-export-diff
chmod +x ~/.bin/git-export-diff

# direnv .envrc template
mkdir -p ~/.config/dotfiles
cp /tmp/dotfiles/linux/.envrc ~/.config/dotfiles/.envrc

# Cleanup
rm -rf /tmp/dotfiles
```

## Cross-platform

### .bashrc

Adds `~/.bin` to the front of `PATH` so that custom scripts take priority. Automatically launches zsh when running in an interactive terminal.

### .zsh (Zsh config)

Lightweight zsh configuration without any framework (no oh-my-zsh). Optimized for fast startup (~16ms) using:

- Async compinit loading (deferred after first prompt)
- Lazy-loaded nvm
- Modern CLI tool aliases (see below)

Plugins are loaded from `~/.zsh/plugins/`:

```sh
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-completions.git ~/.zsh/plugins/zsh-completions
```

### Modern CLI tools

The zsh config auto-detects and uses these tools when available:

| Tool | Replaces | Install (winget) |
|------|----------|------------------|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd` | `ajeetdsouza.zoxide` |
| [eza](https://github.com/eza-community/eza) | `ls` | `eza-community.eza` |
| [bat](https://github.com/sharkdp/bat) | `cat` | `sharkdp.bat` |
| [fd](https://github.com/sharkdp/fd) | `find` | `sharkdp.fd` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | `BurntSushi.ripgrep.MSVC` |
| [fzf](https://github.com/junegunn/fzf) | Ctrl+R, Ctrl+T | `junegunn.fzf` |

### git-export-diff

Exports all changed files between two git commits into an `update/` folder. Works on Linux, Windows (Git Bash) and WSL.

```sh
# Export diff between HEAD~1 and HEAD (default)
git-export-diff

# Export diff from a specific commit
git-export-diff <ref>

# Pretend mode (dry run)
git-export-diff -p
```

Run `git-export-diff -h` for all options.

### .phpversion

Place a `.phpversion` file in your project root to pin the PHP version. Both `8.1` and `81` formats are supported. The Windows scripts and Linux direnv config both read this file and resolve the correct PHP binary.

## Windows

### Shell setup (Zsh on Git Bash)

The `.bashrc` launches zsh automatically when running in an interactive terminal.

1. Download the zsh package from the [MSYS2 repository](https://packages.msys2.org/packages/zsh)
2. Extract the `.pkg.tar.zst` archive into `C:\Program Files\Git` (requires admin):
   ```powershell
   tar -xf zsh-5.9-5-x86_64.pkg.tar.zst -C "C:\Program Files\Git"
   ```

### PHP version switching

The scripts in `~/.bin/` read `.phpversion` from the current directory and resolve the PHP binary from Herd's installation at `~/.config/herd/bin/php<version>/php.exe`. If no `.phpversion` is found, they fall back to Herd's `which-php` command.

## Linux / WSL

### PHP version switching

Copy `linux/.envrc` to your project root:

```bash
cp ~/.config/dotfiles/.envrc /path/to/project/.envrc
direnv allow
```

The `.envrc` reads `.phpversion`, creates a symlink at `.direnv/bin/php` pointing to the correct PHP binary, and uses `PATH_add` to prepend it. Each project gets its own isolated PHP version — multiple terminals in different projects work independently.
