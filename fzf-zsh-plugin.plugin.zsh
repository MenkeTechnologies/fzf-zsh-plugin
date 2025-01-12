# Copyright 2020-2021 Joseph Block <jpb@unixorn.net>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Add our plugin's bin diretory to the user's path
local FZF_PLUGIN_BIN="$(dirname $0)/bin"
export PATH="${PATH}:${FZF_PLUGIN_BIN}"
unset FZF_PLUGIN_BIN

local FZF_COMPLETIONS_D="$(dirname $0)/completions"
export fpath=($FZF_COMPLETIONS_D "${fpath[@]}" )
unset FZF_COMPLETIONS_D

function has() {
  which "$@" > /dev/null 2>&1
}

function debugOut() {
  if [[ -n "$DEBUG" ]]; then
    echo "$@"
  fi
}

# Install fzf, and enable it for command line history searching and
# file searching.

# Install fzf into ~ if it hasn't already been installed.
#if ! has fzf; then
  #if [[ ! -d ~/.fzf ]]; then
    #git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  #fi
#fi

# Install some default settings if user doesn't already have fzf
# settings configured.
#if [[ ! -f ~/.fzf.zsh ]]; then
  #cp "$(dirname $0)/fzf-settings.zsh" ~/.fzf.zsh
#fi


# Source this before we start examining things so we can override the
# defaults cleanly.
#[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Reasonable defaults. Exclude .git directory and the node_modules cesspit.
FZF_DEFAULT_COMMAND='find . -type f ( -path .git -o -path node_modules ) -prune'

if has rg; then
  # rg is faster than find, so use it instead.
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
fi

export FZF_DEFAULT_OPTS="--layout=reverse
--info=inline
--height=80%
--multi
--preview-window=:hidden
--color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
--prompt='∼ ' --pointer='▶' --marker='✓'
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-e:execute(echo {+} | xargs -o vim)'
--bind 'ctrl-v:execute(code {+})'
"

if has bat; then
  # bat will syntax colorize files for you
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'"
fi

if has pbcopy; then
  # on macOS, make ^Y yank the selection to the system clipboard
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'"
fi

# If fd command is installed, use it instead of find
if has 'fd'; then  
  # Show hidden, and exclude .git and the pigsty node_modules files
  export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude '.git' --exclude 'node_modules'"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"

  _fzf_compgen_dir() {
    fd --type d . "$1"
  }

  _fzf_compgen_path() {
    fd . "$1"
  }

fi

if has tree; then
  function fzf-change-directory() {
    local directory=$(
      fd --type d | \
      fzf --query="$1" --no-multi --select-1 --exit-0 \
        --preview 'tree -C {} | head -100'
      )
    if [[ -n "$directory" ]]; then
      cd "$directory"
    fi
  }
  alias fcd=fzf-change-directory
fi

alias fkill='fzf-kill'

if [[ -d ~/.fzf/man ]]; then
  export MANPATH="$MANPATH:~/.fzf/man"
fi

if has z; then
  #unalias z 2> /dev/null
  # like normal z when used with arguments but displays an fzf prompt when used without.
  function zz() {
    [ $# -gt 0 ] && _zshz "$*" && return
    cd "$(_zshz -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
  }
fi

export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"

# From fzf wiki
# cdf - cd into the directory of the selected file
function cdf() {
  local file
  local dir
  file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
}

# Cleanup internal functions
unset -f debugOut
unset -f has

if (( ${+ZPWR_VERBS} )); then
    ZPWR_VERBS[chromehistory]='chrome-history=bookmarks into fzf'
    ZPWR_VERBS[chromebookmarks]='chrome-bookmark-browser=history into fzf'
    if (( ${+commands[brew]} )); then
        ZPWR_VERBS[brewinstall]='fzf-brew-install=brew install into fzf'
        ZPWR_VERBS[brewuninstall]='fzf-brew-uninstall=brew uninstall into fzf'
        ZPWR_VERBS[brewcaskinstall]='fzf-brew-cask-install=brew install --cask into fzf'
        ZPWR_VERBS[brewcaskuninstall]='fzf-brew-cask-uninstall=brew uninstall --cask into fzf'
        ZPWR_VERBS[brewupdate]='fzf-brew-update=brew update into fzf'
    fi
fi
