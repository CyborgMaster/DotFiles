# Path to your oh-my-zsh installation.
export ZSH=/Users/jeremy/.oh-my-zsh
export ZSH_CUSTOM=/Users/jeremy/.oh-my-zsh-custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="cyborg"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git jump emacs colored-man-pages brew osx ssh-agent
         extract bower mvn node nvm bundler rvm gem rails rake pip rand-quote)

# User configuration

export PATH="/Users/jeremy/bin:/Users/jeremy/.jenv/shims:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/share/npm/bin"
export PATH=~/Library/Python/2.7/bin:$PATH
export HOMEBREW_GITHUB_API_TOKEN="c99aa2bfcfc4f2ca3f66f076b985a29d41f50d3c"

# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias j=jump
alias agr='alias | grep'

export LESS='-i -J -R -W -z-4'
export LESSOPEN="| pygmentize -f terminal256 %s"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export PATH="$HOME/.cargo/bin:$PATH"

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

# This seems to fix a bug with the oh-my-zsh plugin that causes files to open in
# the terminal
alias emacs="emacsclient"
