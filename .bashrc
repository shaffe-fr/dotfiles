if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1

#export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\$ '

export PATH="$HOME/.bin:$PATH"

# Launch zsh if available and we're in an interactive terminal
if [ -t 1 ] && command -v zsh &>/dev/null && [ -z "$ZSH_VERSION" ]; then
  exec zsh -i
fi


export TERM=xterm-256color
export ANSICON=true
shopt -s checkwinsize
export COLUMNS=200

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"
