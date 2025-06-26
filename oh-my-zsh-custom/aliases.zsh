alias uupdate='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo snap refresh && sudo snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; done'
alias st='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gac='git add -A && git commit -m'
