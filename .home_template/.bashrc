# Run the rest of this file only for interactive shells
case $- in
  *i*) : ;;   # $- contains 'i' → interactive → continue
  *)   return ;;  # not interactive → stop sourcing this file
esac

# ~/.bashrc guard multiple use
[[ -n "$MY_PROMPT_LOADED" ]] && return
MY_PROMPT_LOADED=1

# -------------------------------
# Portable user / host resolution
# -------------------------------
# Prefer the value coming from Windows, else derive from $HOME
if [ -n "$WINPORTABLE_USER" ]; then
  portable_user="$WINPORTABLE_USER"
else
  portable_user=$(basename "$HOME"); portable_user=${portable_user#.}
  [ "$portable_user" = "home_template" ] && portable_user=guest
fi

export USER="$portable_user"
export LOGNAME="$portable_user"

# Host label from Windows (WINPORTABLE_HOST); fallback to real short hostname
portable_host="${WINPORTABLE_HOST:-$(hostname -s)}"
export HOSTNAME="$portable_host"

# -------------------------------
# Git prompt helpers (optional)
# -------------------------------
# Try common locations for git-prompt.sh
for gp in /mingw64/share/git/completion/git-prompt.sh /usr/share/git/completion/git-prompt.sh; do
  [ -r "$gp" ] && . "$gp" && break
done

# Show dirty state (*) and untracked files (%)
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
# (Optional extras)
# GIT_PS1_SHOWSTASHSTATE=1
# GIT_PS1_SHOWUPSTREAM=auto


# -------------------------------
# Prompt tag (customizable) from Windows via PROMPT_TAG
# -------------------------------
# Order: PROMPT_TAG (custom) → MSYSTEM (MSYS2) → default "MSYS"
prompt_tag="${PROMPT_TAG:-${MSYSTEM:-MSYS}}"


PROMPT_PWD="${PWD/#$HOME/~}"   # but remember to refresh it each prompt too


# -------------------------------
# Window title (spaces as separators; optional ~)
# -------------------------------
# Set TITLE_TILDE=0 to force full absolute path in the title.
: "${TITLE_TILDE:=1}"

# Title format: TAG USER@HOST PATH
update_title() {
  printf '\e]0;%s %s@%s %s\a' "$prompt_tag" "$portable_user" "$portable_host" "$PROMPT_PWD"
}

# keep a tilde-ified path in PROMPT_PWD
prompt_pwd_update() {
  local p="${PWD%/}" h="${HOME%/}"

  # If HOME is Windows-style, convert to MSYS (/c/...)
  if [[ "$h" == *:\\* ]]; then
    command -v cygpath >/dev/null 2>&1 && h="$(cygpath -u "$HOME")"
    h="${h%/}"
  fi

  # Case-insensitive prefix match with boundary
  local lp="${p,,}" lh="${h,,}"
  if [[ -n "$h" && ( "$lp" == "$lh" || "$lp" == "$lh"/* ) ]]; then
    PROMPT_PWD="~${p:${#h}}"
    [[ "$PROMPT_PWD" == "~" ]] || PROMPT_PWD="~${PROMPT_PWD#~}"
  else
    PROMPT_PWD="$PWD"
  fi
}

# --- Prompt path shortening (affects \w) - used in PS1
PROMPT_DIRTRIM=${PROMPT_DIRTRIM:-3}

# -------------------------------
# PS1 (no title here; colors only)
# -------------------------------
# Keep PS1 free of OSC 0 to avoid overriding update_title
PS1_BASE=''
PS1_BASE+=$'\n''\['$'\e[32m''\]'"$USER"'@'"$portable_host"'\['$'\e[0m''\]'  # user@host (green)
PS1_BASE+=' '
PS1_BASE+='\['$'\e[35m''\]'"$prompt_tag"'\['$'\e[0m''\]'                   # tag (magenta)
PS1_BASE+=' '
PS1_BASE+='\['$'\e[33m''\]\w\['$'\e[0m''\]'                               # path (yellow)
if (( EUID == 0 )); then
  PS1_BASE=${PS1_BASE//$'\e[32m'/$'\e[31m'}   # swap green → red
fi

# Append git branch (cyan) safely if __git_ps1 is available
update_ps1() {
  local last=$?  # capture immediately
  local err_seg=""
  if (( last != 0 )); then
    err_seg='\['$'\e[31m''\]✗'"$last"'\['$'\e[0m''\] '
  fi

  local git_seg=""
  if type __git_ps1 >/dev/null 2>&1; then
    git_seg="$(__git_ps1 ' (%s)')"
    git_seg='\['$'\e[36m''\]'"$git_seg"'\['$'\e[0m''\]'
  fi
  PS1="${PS1_BASE}${git_seg}"$'\n'"${err_seg}"'$ '
}

# -------------------------------
# PROMPT_COMMAND (idempotent)
# -------------------------------
# Ensure __update_ps1 appears once
case ";$PROMPT_COMMAND;" in
  *";update_ps1;"*) : ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }update_ps1" ;;
esac

# Ensure update_title appears once, and LAST so it wins if others set OSC 0
case ";$PROMPT_COMMAND;" in
  *";prompt_pwd_update;"*) : ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }prompt_pwd_update" ;;
esac
case ";$PROMPT_COMMAND;" in
  *";update_title;"*) : ;;
  *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }update_title" ;;
esac
#PROMPT_COMMAND="prompt_pwd_update; update_ps1; update_title"
