alias update_structure='git checkout master db/structure.sql &&
  RAILS_ENV=test spring rake db:drop db:create db:structure:load db:migrate'

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
    cp $1 /Volumes/www/htdocs/ComputerCraft/
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

optimize-image() {
  convert -filter Triangle -define filter:support=2 -thumbnail $2 \
    -unsharp 0.25x0.25+8+0.065 -dither None -posterize 136 -quality 82 \
    -define jpeg:fancy-upsampling=off -define png:compression-filter=5 \
    -define png:compression-level=9 -define png:compression-strategy=1 \
    -define png:exclude-chunk=all -interlace none -colorspace sRGB -strip $1 $3
}
