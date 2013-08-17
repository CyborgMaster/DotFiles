alias sudo='sudo '
alias be='bundle exec'

alias ec='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient -n'
sec() {
    if [[ "$@" = /* ]]
    then
        # absolute path
        ec -t /sudo::"$@"
    else
        # Relative path
        ec -t /sudo::`pwd`/"$@"
    fi
}

svndiff()
{
  svn diff "${@}" | colordiff | less -R
}

hgdiff()
{
  hg diff "${@}" | colordiff | less -R
}

ccMonitor() {
  while ~/bin/sleep_until_modified.py "$1" ; do
    echo -n 'copying...'
    scp -q $1 js:/cygdrive/c/inetpub/wwwroot/ComputerCraft/$1.txt
    echo ' done'
  done
}

ccMonitor2() {
  while ~/bin/sleep_until_modified.py "$1" ; do
    echo -n 'copying...'
    cat "$1" | ssh js "cat > /cygdrive/c/inetpub/wwwroot/ComputerCraft/$1.txt"
    echo ' done'
  done

}
