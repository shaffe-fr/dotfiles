if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -t 1 ] && command -v zsh &>/dev/null && [ -z "$ZSH_VERSION" ]; then
  exec zsh
fi

export PATH="$HOME/.bin:$PATH"
export TERM=xterm-256color