
export ZSH=$HOME/.oh-my-zsh


ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(history)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=1

HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

plugins=(
   artisan
   composer
   command-not-found
#   extract
   git
   github
   gitignore
   history-substring-search
#   node
   npm
#   nvm
#   vscode
   web-search
   z
   zsh-autosuggestions
   zsh-syntax-highlighting
   ohmyzsh-full-autoupdate
)

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------

# Decrease delay that vi-mode waits for the end of a key sequence
export KEYTIMEOUT=15

typeset -U path cdpath fpath
path=(
    $HOME/.bin
    $APPDATA/Composer/vendor/bin
    ./vendor/bin
    $path
)

setopt auto_cd
cdpath=(
    $HOME/sites
)

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format %d
zstyle ':completion:*:descriptions' format %B%d%b
zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
    'local-directories named-directories'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

