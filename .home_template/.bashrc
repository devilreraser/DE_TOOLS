# Prefer the value coming from Windows, else derive from $HOME
if [ -n "$WINPORTABLE_USER" ]; then
  portable_user="$WINPORTABLE_USER"
else
  portable_user=$(basename "$HOME"); portable_user=${portable_user#.}
  [ "$portable_user" = "home_template" ] && portable_user=guest
fi

export USER="$portable_user"
export LOGNAME="$portable_user"

# Host label from BAT; fallback to real short hostname
portable_host="${WINPORTABLE_HOST:-$(hostname -s)}"

export HOSTNAME="$portable_host"

# --- Load git-prompt if available
for gp in /mingw64/share/git/completion/git-prompt.sh /usr/share/git/completion/git-prompt.sh; do
  [ -r "$gp" ] && . "$gp" && break
done
# Git helpers (optional)
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1

# Window Title
# --- Prompt tag (customizable from Windows via PROMPT_TAG)
# prompt_tag="${PROMPT_TAG:-${MSYSTEM:-MINGW64}}"
prompt_tag="${PROMPT_TAG:-${MSYSTEM:-MSYS}}"

# --- Update window title each prompt: TAG:HOST:/path
update_title() { printf '\e]0;%s: %s@%s:%s\a' "$prompt_tag" "$portable_user" "$portable_host" "$PWD"; }

# --- Build PS1 (note: \[ \] outside ANSI $'...' to keep them literal)
PS1_TITLE='\['$'\e]0;'"$prompt_tag"':'"$portable_host"$':\w'$'\a''\]'
PS1_BASE="$PS1_TITLE"
PS1_BASE+=$'\n''\['$'\e[32m''\]'"$USER"'@'"$portable_host"'\['$'\e[0m''\]'  # user@host (non-bold green)
PS1_BASE+=' '
PS1_BASE+='\['$'\e[35m''\]'"$prompt_tag"'\['$'\e[0m''\]'                   # tag (magenta)
PS1_BASE+=' '
PS1_BASE+='\['$'\e[33m''\]\w\['$'\e[0m''\]'                               # path (bright yellow)

# --- Append git branch safely (cyan) if git-prompt is available
__update_ps1() {
  local git_seg=""
  if type __git_ps1 >/dev/null 2>&1; then
    git_seg="$(__git_ps1 ' (%s)')"
    git_seg='\['$'\e[36m''\]'"$git_seg"'\['$'\e[0m''\]'
  fi
  PS1="${PS1_BASE}${git_seg}"$'\n$ '
}

# Chain both updaters each prompt (keep any existing PROMPT_COMMAND)
PROMPT_COMMAND="update_title; __update_ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
