/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1

if [ -t 1 ]; then
  exec zsh
fi

# Prioritize ~/.bin over system PATH
export PATH="$HOME/.bin:$PATH"

alias a="artisan"
alias art="php artisan"
alias dump="composer dump-autoload -o"
alias gs="git status"
alias gl="git log --oneline -n 8"
alias gl1="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias gca="git commit -a --amend --no-edit"
alias gcf="git commit --fixup"
alias gr="git rebase"
alias gpof="git push origin --force"
alias gri="git rebase -i"
alias gra="git rebase --abort"
alias grc="git rebase --continue"
alias grs="git rebase --skip"

function fixup() {
    git commit -a --fixup="$1"
    GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$1"~1
}