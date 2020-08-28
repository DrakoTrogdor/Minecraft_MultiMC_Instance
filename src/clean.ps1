$sourcedir = Split-Path ($MyInvocation.MyCommand.Path)
Set-Location -Path $sourcedir
git submodule foreach 'remote="$(git remote)";branch="$(git branch|sed -n ''s/^\* \(.*\)$/\1/p'');echo $remote/$branch;git reset --hard $remote/$branch;git clean -xfd;echo'