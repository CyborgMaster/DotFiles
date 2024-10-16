### Added by Zinit's installer
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
      zdharma-continuum/zinit-annex-patch-dl \
      zdharma-continuum/zinit-annex-bin-gem-node

### End of Zinit's installer chunk

# Most themes use this option.
setopt promptsubst

# Load base OMZ (Oh My Zsh) lib and tools. Idea for loading the full lib from
#   https://github.com/zdharma/zinit/issues/176z. Make sure the symlink for
#   tools exists so OMZ plugins can find it (a similar symlink for the plugins
#   directory is automatically created).
#
# zinit wait lucid svn for \
#       as="null" compile="*.zsh" multisrc="*.zsh" OMZ::lib \
#       as="null" atclone='ln -shf OMZ::tools ../tools' OMZ::tools
#
# Since GitHub pulled SVN support the above no longer works and so we are
# loading the files individually for now.  Issue tracked here:
# https://github.com/zdharma-continuum/zinit/issues/504
zinit wait lucid for \
   OMZ::lib/async_prompt.zsh \
   OMZ::lib/bzr.zsh \
   OMZ::lib/cli.zsh \
   OMZ::lib/clipboard.zsh \
   OMZ::lib/compfix.zsh \
   OMZ::lib/completion.zsh \
   OMZ::lib/correction.zsh \
   OMZ::lib/diagnostics.zsh \
   OMZ::lib/directories.zsh \
   OMZ::lib/functions.zsh \
   OMZ::lib/git.zsh \
   OMZ::lib/grep.zsh \
   OMZ::lib/history.zsh \
   OMZ::lib/key-bindings.zsh \
   OMZ::lib/misc.zsh \
   OMZ::lib/nvm.zsh \
   OMZ::lib/prompt_info_functions.zsh \
   OMZ::lib/spectrum.zsh \
   OMZ::lib/termsupport.zsh \
   OMZ::lib/theme-and-appearance.zsh \
   OMZ::lib/vcs_info.zsh

# `osx` plugin loading idea from
# http://zdharma.org/zinit/wiki/GALLERY/#snippets.
#
# macos doesn't work without svn to load multiple files, see above issues.
# zinit wait lucid svn for OMZ::plugins/macos

# Load OMZ plugins
zinit wait lucid for \
      OMZP::git \
      OMZP::jump \
      OMZP::colored-man-pages \
      OMZP::ssh-agent \
      OMZP::extract \
      OMZP::bower \
      OMZP::mvn \
      OMZP::node \
      OMZP::nvm \
      OMZP::pip \
      OMZP::rand-quote \
      OMZP::systemadmin \
      OMZP::kubectl
      # OMZP::virtualenvwrapper

# Load immediately to set PATH
zinit lucid for \
      OMZP::brew

# Emacs - The plugin has multiple files so we have to download using SVN.
#
# Has to be loaded after OMZP::brew
#
# This used to be loaded over SVN as well, see above issue, but SVN isn't
# working so we aren't getting the extra file, so we manually download it.
# zinit wait lucid for OMZP::emacs
zinit ice lucid wait atclone'curl -Os https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/emacs/emacsclient.sh && chmod 755 emacsclient.sh'
zinit snippet https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/emacs/emacs.plugin.zsh

# This seems to fix a bug with the oh-my-zsh plugin that causes files to open in
# the terminal
# alias emacs="emacsclient --no-wait"

# Ruby plugins and config
if type rvm &> /dev/null; then
    zinit wait lucid for \
          OMZP::bundler \
          OMZP::rvm \
          OMZP::gem \
          OMZP::rails \
          OMZP::rake

    # Fix bug with ruby forking in macOS. See
    # https://blog.phusion.nl/2017/10/13/why-ruby-app-servers-break-on-macos-
    # high-sierra-and-what-can-be-done-about-it/
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
fi

# Go setup
if type go &> /dev/null; then
    goh() { go help $@ | less }
    export PATH=$PATH:$(go env GOPATH)/bin
    zinit wait lucid for OMZP::golang
fi

# Other Plugins (not OMZ)
zinit wait lucid for MichaelAquilina/zsh-you-should-use

# Setup completions and highlighting
zinit wait lucid light-mode for \
      atinit="zicompinit; zicdreplay" zdharma-continuum/fast-syntax-highlighting \
      atload="_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
      blockf atpull'zinit creinstall -q .'  zsh-users/zsh-completions

# fd:  a simple, fast and user-friendly alternative to find.
zinit wait lucid from"gh-r" as"null" sbin"**/fd" for @sharkdp/fd

# fzf is a fuzzy finder.  This integrates it into all zsh auto-completions.  The
# binary is installed via Homebrew (done that way because the OMZ plugin for fzf
# looks for it there).
zinit wait lucid for \
      OMZP::fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# I would like to use https://github.com/Aloxaf/fzf-tab, but it is currently
# crashing for me with the error:
#
# _fzf_tab_get_candidates:15: bad set of key/value pairs for associative array
#
# So Instead I'm using the following which turns on interactive search for built
# in zsh completion.  The main thing missing is the ability to search the help
# text of options.
zstyle ':completion:*' menu yes select interactive

# Set OMZ theme. Loaded separately because the theme needs the ! passed to the
# wait ice to reset the prompt after loading the snippet in Turbo.
#
# Idea from https://github.com/zdharma/zinit/issues/173
PS1="READY >" # provide a simple prompt till the theme loads
zinit ice lucid wait='!' pick='cyborg.zsh-theme'
zinit load ~/.oh-my-zsh-custom/themes

# bat: A cat(1) clone with wings.
zinit wait lucid from"gh-r" as"null" sbin"**/bat" for @sharkdp/bat

# eza: A modern version of ‘ls’. https://eza.rocks/
# Must be installed by brew
zinit wait lucid atinit="alias ls=eza; alias la='ls -lah'" nocd light-mode for zdharma-continuum/null

# Colorization of tab complete and exa
zinit ice wait lucid reset \
      atclone"local P=${${(M)OSTYPE:#*darwin*}:+g}
            \${P}sed -i \
            '/DIR/c\DIR 38;5;63;1' LS_COLORS; \
            \${P}dircolors -b LS_COLORS > c.zsh" \
            atpull'%atclone' pick"c.zsh" nocompile'!' \
            atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zinit light trapd00r/LS_COLORS

# SSH key config
zstyle :omz:plugins:ssh-agent identities id
if [ -f ~/.ssh/personal_id ]; then
    zstyle -s :omz:plugins:ssh-agent identities saved_identities
    zstyle :omz:plugins:ssh-agent identities `echo $saved_identities` personal_id
fi

export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/share/npm/bin:$PATH
export PATH=$PATH:~/Library/Python/2.7/bin
export PATH=$PATH:~/Library/Python/3.9/bin

# jenv - version manager for java
if type jenv &> /dev/null; then
    export PATH="$HOME/.jenv/bin:$PATH"
    eval "$(jenv init -)"
fi

# TODO: only do this if rust is installed
export PATH="$PATH:$HOME/.cargo/bin"

# GNU utils path overrides
PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"

if [ `launchctl limit maxfiles | awk '{print $2}'` = 256 ]; then
    echo "increasing maxfiles..."
    sudo launchctl limit maxfiles 65536 200000
fi

# Secrets that shouldn't be committed to source control
source ~/.secrets.sh

# Environment specific config
if [[ -f ~/.local.zshrc ]]; then
    source ~/.local.zshrc
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
if [[ -f ~/.rvm/bin/rvm ]]; then
    export PATH="$PATH:$HOME/.rvm/bin"
    # Load RVM into a shell session *as a function*
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi

export PATH="/usr/local/opt/openjdk/bin:$PATH"

# Make sure my personal bin is first on the path
# zinit wait'0c' lucid atinit='export PATH=~/bin:$PATH' nocd light-mode for zdharma-continuum/null
export PATH="$HOME/bin:$PATH"

### My Commands and Aliases ####################################################

alias j=jump
alias agr='alias | grep'
export LESS='-i -J -R -W -z-4'
export LESSOPEN="| pygmentize -f terminal256 %s"

alias ag="ag --pager='less -R'"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
rg() { command rg -p $@ | less -R }
replace() { command rg --color never $1 -l | xargs -n1 perl -pi -e "s|$1|$2|g" }
update_imports() { command rg --color never $1 -l -t go | xargs -n1 goimports -w }
replace_with_imports() { replace $1 $2 && update_imports $2 }

# Unzip wrapper to default to quiet and auto create matching directory
unzip() { command unzip -q $1 -d $1:r }

optimize-image() {
    convert -filter Triangle -define filter:support=2 -thumbnail $2 \
            -unsharp 0.25x0.25+8+0.065 -dither None -posterize 136 -quality 82 \
            -define jpeg:fancy-upsampling=off -define png:compression-filter=5 \
            -define png:compression-level=9 -define png:compression-strategy=1 \
            -define png:exclude-chunk=all -interlace none -colorspace sRGB \
            -strip $1 $3
}

git-stats-by-author() {
    # sort people by lines changed and put total at the top
    jq_cmd=$(cat <<'JQ'
to_entries |
[
  .[-1],
  (.[:-1] | sort_by(.value."lines changed"| sub("\\(.*\\)";"") | tonumber) | reverse)
] |
flatten |
from_entries
JQ
             )

    git quick-stats --detailed-git-stats |
        tail -n +3 | # skip past header
        sed $'s/\t/    /g' | # replace tabs with space to get valid YAML
        sed $'s/total/ total/g' | # total is one more indented than everything else
        yq -y $jq_cmd
}

alias git-unpushed='git log --branches --not --remotes --simplify-by-decoration --decorate --oneline'
alias new-todos="ack '"'^\+(?!\+).*TODO(?!:K)'"'"

# https://superuser.com/a/767491
# https://stackoverflow.com/a/37222377
# if [[ `uname` == Darwin ]]; then
#     MAX_MEMORY_UNITS=KB
# else
#     MAX_MEMORY_UNITS=MB
# fi

# TIMEFMT='%J   %U  user %S system %P cpu %*E total'$'\n' \
#        'avg shared (code):         %X KB'$'\n'\
#        'avg unshared (data/stack): %D KB'$'\n'\
#        'total (sum):               %K KB'$'\n'\
#        'max memory:                %M '$MAX_MEMORY_UNITS''$'\n'\
#        'page faults from disk:     %F'$'\n'\
#        'other page faults:         %R'
