function cdr --description 'Change directory to the git root'
    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        echo "Error: Not inside a git repository"
        return 1
    end
    cd $git_root
end
