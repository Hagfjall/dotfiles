function existsCommand() {
	builtin command -v $1 > /dev/null 2>&1
}

function source-safe() { if [ -f "$1" ]; then source "$1"; fi }

#==============================================================#
## Apply XDG
#==============================================================#
mkdir -p "$XDG_CACHE_HOME"/less
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history
mkdir -p "$XDG_CACHE_HOME"/gdb
export SQLITE_HISTORY="$XDG_CACHE_HOME"/sqlite_history

