/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1

if [ -t 1 ]; then
  exec zsh
fi

export NODE_PATH="C:\Users\Karel\AppData\Roaming\npm\node_modules"
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
alias php74="/c/tools/php74/php"
alias php80="/c/tools/php80/php"
alias php81="/c/tools/php81/php"
alias c74="php74 /c/ProgramData/ComposerSetup/bin/composer.phar"
alias c80="php80 /c/ProgramData/ComposerSetup/bin/composer.phar"
alias c81="php81 /c/ProgramData/ComposerSetup/bin/composer.phar"

function fixup() {
    git commit -a --fixup="$1"
    GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$1"~1
}

