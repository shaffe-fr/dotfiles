# ============================================================
# .zshrc — optimisé pour la vitesse (pas de framework)
# ============================================================

skip_global_compinit=1
ZSH_PLUGINS="$HOME/.zsh/plugins"

# --- Historique ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
HIST_STAMPS="yyyy-mm-dd"

# --- Options shell ---
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --- Prompt minimaliste et rapide ---
_fast_git_branch() {
  local branch
  branch=$(command git symbolic-ref --short HEAD 2>/dev/null) || return
  echo " (%F{cyan}${branch}%f)"
}

setopt PROMPT_SUBST
PROMPT='%F{green}%~%f$(_fast_git_branch) %F{yellow}❯%f '

# --- Keybindings (emacs-style) ---
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char

# --- PATH & cdpath ---
typeset -U path cdpath fpath
path=(
    $HOME/.bin
    $HOME/.local/bin
    $APPDATA/Composer/vendor/bin
    ./vendor/bin
    $path
)

setopt auto_cd
cdpath=(
    $HOME/sites
)

# --- Outils modernes ---
if (( $+commands[eza] )); then
  alias ls='eza --color=auto'
  alias ll='eza -lah --git'
  alias la='eza -a'
  alias tree='eza --tree --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
  alias la='ls -A --color=auto'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never --style=plain'
  alias catp='bat'
  export BAT_THEME="ansi"
fi

(( $+commands[fd] )) && alias find='fd'
(( $+commands[rg] )) && alias grep='rg'

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi

# --- fzf ---
if (( $+commands[fzf] )); then
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
fi

# --- Aliases ---
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline -20'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias a='php artisan'

# --- Chargement paresseux de nvm ---
if [[ -d "$HOME/.nvm" ]]; then
  lazy_nvm() {
    unset -f nvm node npm npx
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }
  nvm()  { lazy_nvm; nvm "$@"; }
  node() { lazy_nvm; node "$@"; }
  npm()  { lazy_nvm; npm "$@"; }
  npx()  { lazy_nvm; npx "$@"; }
fi

export TERM=xterm-256color

# --- Chargement asynchrone (après le premier prompt) ---
autoload -Uz add-zsh-hook

_deferred_init() {
  # zsh-completions
  [[ -d "$ZSH_PLUGINS/zsh-completions/src" ]] && fpath=("$ZSH_PLUGINS/zsh-completions/src" $fpath)

  # compinit
  autoload -Uz compinit
  if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ~/.zsh/cache
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*:descriptions' format %B%d%b
  zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
      'local-directories named-directories'

  # zsh-autosuggestions
  if [[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    bindkey '^ ' autosuggest-accept
  fi

  # zsh-syntax-highlighting (toujours en dernier)
  if [[ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi

  # fzf keybindings
  if (( $+commands[fzf] )); then
    source <(fzf --zsh 2>/dev/null) || true
  fi

  add-zsh-hook -d precmd _deferred_init
}

add-zsh-hook precmd _deferred_init
