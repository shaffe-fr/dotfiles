alias php="php.bat"
alias herd="herd.bat"
alias laravel="laravel.bat"
alias composer="composer.bat"
alias outdated="composer outdated --direct --major-only --strict"
alias gl="git log --oneline -n 8"
alias gl1="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias gca="git commit -a --amend --no-edit"
alias gcf="git commit --fixup"
alias gr="git rebase"
alias gri="git rebase -i"
alias gra="git rebase --abort"
alias grc="git rebase --continue"
alias grs="git rebase --skip"
alias gcc="git cherry-pick --continue"
alias gcs="git cherry-pick --skip"
alias gpo='git push origin $(git branch --show-current) -u'
alias gpaf='git push origin --all --force-with-lease'
alias gpof='git push origin $(git branch --show-current) --force-with-lease -u'

function fixup() {
    git commit -a --fixup="$1"
    GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$1"~1
}

function gdb() {
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    LAST_BACKUP=$(git branch -l | grep "backup/$BRANCH_NAME" | tail -n 1)
    echo "Diff with last backup at $LAST_BACKUP..."
    git diff $LAST_BACKUP HEAD
}

open() {
    winpath=$(cygpath -wal "$*")
    explorer "$winpath";
}

gpatch() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    local ROOT="$(git rev-parse --show-toplevel)"
  else
    local ROOT="$(pwd)"
  fi

  local PATCH_DIR="$ROOT/patches"
  mkdir -p "$PATCH_DIR"

  local TS
  TS="$(date +"%Y%m%d-%H%M%S")"
  local PATCH_FILE="$PATCH_DIR/${1:-gpatch}-$TS.patch"

  echo "────────────────────────────────────────────────────────"
  echo "Collez ou saisissez votre patch unifié (format 'diff --git')."
  echo "Quand vous avez terminé, validez avec  Ctrl+D  (fin de saisie)."
  echo "Le patch sera sauvegardé dans: $PATCH_FILE"
  echo "────────────────────────────────────────────────────────"
  tee "$PATCH_FILE" >/dev/null

  echo "🔧 Application du patch…"
  if git apply -p0 --index "$PATCH_FILE" 2>"$PATCH_FILE.err"; then
    echo "✅ Patch appliqué et index mis à jour."
    echo "   ➜ Fichiers modifiés :"
    git status --porcelain
  else
    echo "❌ Échec de l'application du patch."
    echo "   Journal d'erreur (abrégé) :"
    sed -n '1,120p' "$PATCH_FILE.err"
    echo "   Le patch est conservé: $PATCH_FILE"
    echo "   Astuces:"
    echo "     - Vérifie le niveau de strip: git apply -p0|p1|p2 \"$PATCH_FILE\""
    echo "     - Ou applique en mode rejet: git apply --reject \"$PATCH_FILE\""
    echo "     - Ou ouvre-le pour inspection: less \"$PATCH_FILE\""
    return 1
  fi
}
alias gp='gpatch'

toggle_xdebug() {
  php_ini=$(php --ini | awk -F': ' '/Loaded Configuration File/ {print $2}' | sed 's/^[[:space:]]*//')
  if [[ "$php_ini" =~ ^C: ]]; then
    php_ini=$(cygpath -u "$php_ini")
  fi

  if [[ -z "$php_ini" || "$php_ini" == "(none)" ]]; then
    php_ini=$(php --ini | awk -F': ' '/Additional .ini files parsed/ {print $2}' | sed 's/^[[:space:]]*//')
    if [[ "$php_ini" =~ ^C: ]]; then
      php_ini=$(cygpath -u "$php_ini")
    fi
  fi

  if [[ -z "$php_ini" || "$php_ini" == "(none)" ]]; then
    echo "Chemin php.ini non trouvé: '$php_ini'."
    return 1
  fi

  echo "Chemin php.ini trouvé: '$php_ini'"

  if [ ! -f "$php_ini" ]; then
    echo "Fichier php.ini introuvable à l'emplacement : '$php_ini'"
    return 1
  fi

  if grep -q '^;zend_extension=.*xdebug.*\.\(so\|dll\)' "$php_ini"; then
    echo "Activation de xdebug..."
    sed 's|^;zend_extension=|zend_extension=|' "$php_ini" > "$php_ini.tmp"
    mv "$php_ini.tmp" "$php_ini"
  elif grep -q '^zend_extension=.*xdebug.*\.\(so\|dll\)' "$php_ini"; then
    echo "Désactivation de xdebug..."
    sed 's|^zend_extension=|;zend_extension=|' "$php_ini" > "$php_ini.tmp"
    mv "$php_ini.tmp" "$php_ini"
  else
    echo "Ligne zend_extension pour xdebug non trouvée dans $php_ini"
  fi
}