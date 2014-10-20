# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# source all files in .bash.d
if [[ -d ~/.bash.d && ! -z `ls -A ~/.bash.d` ]]; then
  . ~/.bash.d/*
fi

PATH=/usr/local/bin:/usr/bin:/bin:~/bin:$PATH
export PATH

BREW_PREFIX=`brew --prefix`
export PATH=$BREW_PREFIX/share/python:$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH
export PYTHONPATH=$BREW_PREFIX/lib/python2.7/site-packages:$PYTHONPATH

#defines for NodeJS
export NODE_PATH=/usr/local/share/npm/lib/node_modules/
export PATH=$PATH:/usr/local/share/npm/bin

export EDITOR=nano

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
   # if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
   #      # We have color support; assume it's compliant with Ecma-48
   #      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
   #      # a case would tend to support setf rather than setaf.)
   #      color_prompt=yes
   #  else
   #      color_prompt=
   #  fi
    color_prompt=yes
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
#if [ -x /usr/bin/dircolors ]; then
#    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias ls='ls -G'

    #OSX ls color schemes
    #export LSCOLORS=exfxcxdxbxegedabagacad #for light terminal background
    export LSCOLORS=GxFxCxDxBxegedabagaced #for dark terminal background

    #alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
#fi



# some more ls aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
alias apt-cygports='apt-cyg -m ftp://sourceware.org/pub/cygwinports/'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Enable ssh agent
export SSH_AUTH_SOCK=/tmp/.ssh-socket
SSH_ENV=$HOME/.ssh/environment

function start_agent {
     echo "Initialising new SSH agent..."
     rm -f $SSH_AUTH_SOCK
     /usr/bin/ssh-agent -a $SSH_AUTH_SOCK | sed 's/^echo/#echo/' > ${SSH_ENV}
     echo succeeded
     chmod 600 ${SSH_ENV}
     . ${SSH_ENV} > /dev/null
     /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
     . ${SSH_ENV} > /dev/null
     #ps ${SSH_AGENT_PID} doesn't work under cywgin
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent > /dev/null || {
         start_agent;
     }
else
     start_agent;
fi

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # This loads RVM into a shell session.

# Colorize maven output
source ~/projects/colorize-maven/colorize-maven.sh

# Aliases to help moving around the filesystem
export MARKPATH=$HOME/.marks
function jump {
    cd -P $MARKPATH/$1 2>/dev/null || echo "No such mark: $1"
}
function mark {
    mkdir -p $MARKPATH; ln -s $(pwd) $MARKPATH/$1
}
function unmark {
    rm -i $MARKPATH/$1
}
function marks {
    ls -l $MARKPATH | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/	-/g' && echo
}

#use homeshick for managing dotfiles in git
alias homeshick="$HOME/.homesick/repos/homeshick/home/.homeshick"
