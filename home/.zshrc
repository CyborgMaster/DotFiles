### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
            print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
      zinit-zsh/z-a-patch-dl \
      zinit-zsh/z-a-as-monitor \
      zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

# Most themes use this option.
setopt promptsubst

# Load base OMZ (Oh My Zsh) lib and tools. Idea for loading the full lib from
#   https://github.com/zdharma/zinit/issues/176z. Make sure the symlink for
#   tools exists so OMZ plugins can find it (a similar symlink for the plugins
#   directory is automatically created).
zinit wait lucid svn for \
      as="null" compile="*.zsh" multisrc="*.zsh" OMZ::lib \
      as="null" atclone='ln -shf OMZ::tools ../tools' OMZ::tools

# Emacs - The plugin has multiple files so we have to download using SVN.
zinit wait lucid svn for OMZ::plugins/emacs
# This seems to fix a bug with the oh-my-zsh plugin that causes files to open in
# the terminal
alias emacs="emacsclient --no-wait"

# `osx` plugin loading idea from
# http://zdharma.org/zinit/wiki/GALLERY/#snippets.
zinit wait lucid svn for OMZ::plugins/osx

# Load OMZ plugins
zinit wait lucid for \
      OMZP::git \
      OMZP::jump \
      OMZP::colored-man-pages \
      OMZP::brew \
      OMZP::ssh-agent \
      OMZP::extract \
      OMZP::bower \
      OMZP::mvn \
      OMZP::node \
      OMZP::nvm \
      OMZP::pip \
      OMZP::rand-quote \
      OMZP::systemadmin

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
      atinit="zicompinit; zicdreplay" zdharma/fast-syntax-highlighting \
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

# exa: A modern version of ‘ls’. https://the.exa.website/
# `0z` to make sure it loads after the OMZ less aliases
zinit wait"0z" lucid from"gh-r" as"null" sbin"exa* -> exa" \
      atinit="alias ls=exa; alias la='ls -lah'" for ogham/exa

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
zstyle :omz:plugins:ssh-agent identities id_rsa
if [ -f ~/.ssh/personal_id_rsa ]; then
    zstyle -s :omz:plugins:ssh-agent identities saved_identities
    zstyle :omz:plugins:ssh-agent identities `echo $saved_identities` personal_id_rsa
fi

export PATH=~/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/share/npm/bin:$PATH
export PATH=~/Library/Python/2.7/bin:$PATH

alias j=jump
alias agr='alias | grep'
export LESS='-i -J -R -W -z-4'
export LESSOPEN="| pygmentize -f terminal256 %s"

alias ag="ag --pager='less -R'"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
rg() { command rg -p $@ | less -R }
replace() { command rg --color never $1 -l | xargs -n1 perl -pi -e "s|$1|$2|" }
update_imports() { command rg --color never $1 -l -t go | xargs -n1 goimports -w }
replace_with_imports() { replace $1 $2 && update_imports $2 }

# TODO: only do this if rust is installed
export PATH="$HOME/.cargo/bin:$PATH"

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
  (.[:-1] | sort_by(.value."lines changed") | reverse)
] |
flatten |
from_entries
JQ
             )

    git quick-stats detailedGitStats |
        tail -n +3 | # skip past header
        sed $'s/\t/    /g' | # replace tabs with space to get valid YAML
        yq -y $jq_cmd
}
alias git-unpushed='git log --branches --not --remotes --simplify-by-decoration --decorate --oneline'

# jenv - version manager for java
if type jenv &> /dev/null; then
    export PATH="$HOME/.jenv/bin:$PATH"
    eval "$(jenv init -)"
fi

# GNU utils path overrides
PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"

if [ `launchctl limit maxfiles | awk '{print $2}'` = 256 ]; then
    echo "increasing maxfiles..."
    sudo launchctl limit maxfiles 65536 200000
fi

# Secrets that shouldn't be committed to source control
source ~/.secrets.sh

# Environment specific config
if [ -f ~/.local.zshrc ]; then
    source ~/.local.zshrc
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
if type rvm &> /dev/null; then
    export PATH="$PATH:$HOME/.rvm/bin"
    # Load RVM into a shell session *as a function*
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi
