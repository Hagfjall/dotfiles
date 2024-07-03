
#==============================================================#
##          Aliases                                           ##
#==============================================================#

## common ##
alias cp='cp -irf'
alias mv='mv -i'
alias ..='cd ..'
alias zcompile_zshrc='zcompile ~/.zshrc'
alias rez='exec zsh'
alias sc='screen'
alias l='ls -ahl'
alias less-plain='LESS="" less'
alias sudo='sudo -H '
alias cl='clear'
alias dircolor='eval `dircolors -b $ZHOMEDIR/dircolors`'
alias quit='exit'
alias truecolor-terminal='export COLORTERM=truecolor'
alias osc52='printf "\x1b]52;;%s\x1b\\" "$(base64 <<< "$(date +"%Y/%m/%d %H:%M:%S"): hello")"'
alias makej='make -j$(nproc)'
alias arch='uname -m'

# history
alias history-mem='fc -rl'
alias history-import='fc -RI'

# ls
alias la='ls -aF --color=auto'
alias lla='ls -alF --color=auto'
alias lal='ls -alF --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias l.='ls -d .[a-zA-Z]* --color=auto'

# chmod
alias 644='chmod 644'
alias 755='chmod 755'
alias 777='chmod 777'

# grep display filename, display line count, do not process binary files
alias gre='grep -H -n -I --color=auto'

## application ##

## development ##

# tmux
alias t='\tmux -2'
alias tmux='\tmux -2'
alias ta='\tmux -2 attach -d'

# xauth
alias xauth-copy="xauth list | tail -n 1 | awk '{printf \$3}' | pbcopy"

# udev
alias reload-udev-hwdb='sudo systemd-hwdb update && sudo udevadm trigger'


#==============================================================#
##          Global alias                                      ##
#==============================================================#

alias -g G='| grep '  # e.x. dmesg lG CPU
alias -g L='| $PAGER '
alias -g W='| wc'
alias -g H='| head'
alias -g T='| tail'
if [ "$WAYLAND_DISPLAY" != "" ]; then
	if builtin command -v wl-copy > /dev/null 2>&1; then
		alias -g Y='| wl-copy'
	fi
else
	if builtin command -v xsel > /dev/null 2>&1; then
		alias -g Y='| xsel -i -b'
	elif builtin command -v xclip > /dev/null 2>&1; then
		alias -g Y='| xclip -i -selection clipboard'
	fi
fi


#==============================================================#
##          Suffix                                            ##
#==============================================================#

alias -s {md,markdown,txt}="$EDITOR"
alias -s {html,gif,mp4}='x-www-browser'
alias -s rb='ruby'
alias -s py='python'
alias -s hs='runhaskell'
alias -s php='php -f'
alias -s {jpg,jpeg,png,bmp}='feh'
alias -s mp3='mplayer'
function extract() {
	case $1 in
		*.tar.gz|*.tgz) tar xzvf "$1" ;;
		*.tar.xz) tar Jxvf "$1" ;;
		*.zip) unzip "$1" ;;
		*.lzh) lha e "$1" ;;
		*.tar.bz2|*.tbz) tar xjvf "$1" ;;
		*.tar.Z) tar zxvf "$1" ;;
		*.gz) gzip -d "$1" ;;
		*.bz2) bzip2 -dc "$1" ;;
		*.Z) uncompress "$1" ;;
		*.tar) tar xvf "$1" ;;
		*.arj) unarj "$1" ;;
	esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract


#==============================================================#
##          App                                               ##
#==============================================================#

# urxvt
alias Xresources-reload="xrdb -remove && xrdb -DHOME_ENV=\"$HOME\" -merge ~/.config/X11/Xresources"

# web-server
alias web-server='python -m SimpleHTTPServer 8000'

# generate password
alias generate-passowrd='openssl rand -base64 20'

# hdd mount
alias mount-myself='sudo mount -o uid=$(id -u),gid=$(id -g)'

# xhost
alias xhost-local='xhost local:'

# move bottom
alias move-bottom='tput cup $(($(stty size|cut -d " " -f 1))) 0 && tput ed'

# luajit patch https://github.com/LuaJIT/LuaJIT/issues/369
alias luajit="rlwrap luajit"

if builtin command -v nerdctl > /dev/null 2>&1; then
	alias docker='nerdctl'
fi

#==============================================================#
##          improvement command                               ##
#==============================================================#

function alias-improve() {
	if builtin command -v $(echo $2 | cut -d ' ' -f 1) > /dev/null 2>&1; then
		alias $1=$2
	fi
}

alias hdu='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias disk-usage='sudo ncdu --color dark -rr -x --exclude .git --exclude node_modules /'


alias screencast='wf-recorder -g "$(slurp)" -f ~/Pictures/wf_$(date "+%y%m%d-%H%M%S").mp4'
alias xterm-modifyOtherKyes='xterm -xrm "*modifyOtherKeys:1"'
# alias xterm-modifyOtherKyes='xterm -xrm "*modifyOtherKeys:1" -xrm "*formatOtherKeys:1"'


#==============================================================#
##          Hash                                              ##
#==============================================================#

hash -d data=$XDG_DATA_HOME
hash -d zshdata=$XDG_DATA_HOME/zsh
hash -d zshplugins=$XDG_DATA_HOME/zsh/zinit/plugins
hash -d nvimdata=$XDG_DATA_HOME/nvim
hash -d nvimplugins=$XDG_DATA_HOME/nvim/lazy
