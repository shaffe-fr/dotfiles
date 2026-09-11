# ============================================================
# .zshrc — optimisé pour la vitesse (pas de framework)
# ============================================================

skip_global_compinit=1
ZSH_PLUGINS="$HOME/.zsh/plugins"
ZSH_CACHE="$HOME/.zsh/cache"
[[ -d $ZSH_CACHE ]] || mkdir -p $ZSH_CACHE

# Chaque spawn de binaire natif coûte 20 à 40 ms sous MSYS. Le code
# d'initialisation que ces outils émettent ne varie qu'avec leur version : le
# mettre en cache et ne le régénérer que si l'exécutable est plus récent.
_cached_init() {
  local name=$1 bin=$2
  shift 2
  local cache=$ZSH_CACHE/init-$name.zsh
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    "$@" >| $cache 2>/dev/null || return
  fi
  source $cache
}

# --- Détection terminal IDE (Kiro, VS Code, etc.) ---
if [[ "$TERM_PROGRAM" == "kiro" ]] || [[ "$TERM_PROGRAM" == "vscode" ]] || [[ "$TERM" == "dumb" ]]; then
  DISABLE_ZSH_VISUAL_PLUGINS=1
fi

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
# Requis par le qualificateur (#q...) du test de fraicheur de _deferred_init :
# sans lui le test est toujours vrai et compinit -C devient inatteignable.
setopt EXTENDED_GLOB
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --- Prompt minimaliste et rapide ---
# La branche est calculée dans un hook precmd, pas dans PROMPT : une
# substitution $(...) dans le prompt forke un sous-shell à chaque affichage.
# La lecture directe de .git/HEAD évite en plus le fork de `git symbolic-ref`,
# mesuré à 39 ms par prompt.
_git_prompt_info=''

_update_git_prompt() {
  _git_prompt_info=''
  local dir=$PWD head gitdir ref
  while [[ -n $dir ]]; do
    if [[ -f $dir/.git/HEAD ]]; then
      head=$dir/.git/HEAD
      break
    elif [[ -f $dir/.git ]]; then
      read -r gitdir < $dir/.git
      gitdir=${gitdir#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
      [[ -f $gitdir/HEAD ]] && head=$gitdir/HEAD
      break
    fi
    dir=${dir%/*}
  done
  [[ -n $head ]] || return
  read -r ref < $head
  if [[ $ref == ref:*refs/heads/* ]]; then
    _git_prompt_info=" (%F{cyan}${ref#*refs/heads/}%f)"
  elif [[ -n $ref ]]; then
    _git_prompt_info=" (%F{red}${ref[1,7]}%f)"
  fi
}

setopt PROMPT_SUBST
PROMPT='%F{green}%~%f${_git_prompt_info} %F{yellow}❯%f '

# --- Keybindings (emacs-style) ---
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# --- PATH & cdpath ---
typeset -U path cdpath fpath
# $APPDATA contient des antislashes que zsh interprète comme des échappements
# (\U, \A, \R) : l'entrée obtenue est corrompue. Garder la forme POSIX.
# /usr/bin est requis explicitement, sans quoi les coreutils MSYS manquent et
# compdump échoue sur `mv` sans jamais écrire son dump.
path=(
    $HOME/.bin
    $HOME/.local/bin
    $HOME/AppData/Roaming/Composer/vendor/bin
    ./vendor/bin
    /usr/bin
    /bin
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
  export BAT_THEME="ansi"
fi


if (( $+commands[zoxide] )); then
  _cached_init zoxide $commands[zoxide] zoxide init zsh --cmd cd
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

# --- Aliases partagés (bash/zsh) ---
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

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
    unfunction nvm node npm npx 2>/dev/null
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }
  unalias nvm node npm npx 2>/dev/null
  nvm()  { lazy_nvm; nvm "$@"; }
  node() { lazy_nvm; node "$@"; }
  npm()  { lazy_nvm; npm "$@"; }
  npx()  { lazy_nvm; npx "$@"; }
fi

export TERM=xterm-256color

# --- Chargement asynchrone (après le premier prompt) ---
autoload -Uz add-zsh-hook
add-zsh-hook precmd _update_git_prompt
_update_git_prompt

_deferred_init() {
  # zsh-completions
  [[ -d "$ZSH_PLUGINS/zsh-completions/src" ]] && fpath=("$ZSH_PLUGINS/zsh-completions/src" $fpath)

  # Sans ce répertoire, compinit et le cache de complétion échouent en écriture :
  # le dump est reconstruit intégralement à chaque shell.
  [[ -d ~/.zsh/cache ]] || mkdir -p ~/.zsh/cache

  autoload -Uz compinit
  if [[ -n ~/.zsh/cache/zcompdump(#qN.mh+24) ]]; then
    compinit -d ~/.zsh/cache/zcompdump
  else
    compinit -C -d ~/.zsh/cache/zcompdump
  fi
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ~/.zsh/cache
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*:descriptions' format %B%d%b
  zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
      'local-directories named-directories'

  # zsh-autosuggestions (désactivé dans les terminaux IDE)
  if [[ -z "$DISABLE_ZSH_VISUAL_PLUGINS" ]] && [[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    bindkey '^f' autosuggest-accept
  fi

  # zsh-syntax-highlighting (désactivé dans les terminaux IDE, toujours en dernier)
  if [[ -z "$DISABLE_ZSH_VISUAL_PLUGINS" ]] && [[ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi

  # fzf keybindings
  # fzf.exe est un binaire Windows natif : il ne sait pas lire le /dev/fd/N
  # d'une substitution de processus MSYS. Passer par un fichier de cache.
  if (( $+commands[fzf] )); then
    _cached_init fzf $commands[fzf] fzf --zsh
  fi

  add-zsh-hook -d precmd _deferred_init
}

add-zsh-hook precmd _deferred_init
