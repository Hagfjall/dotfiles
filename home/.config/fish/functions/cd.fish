function cd --description "Change directory with support for multi-dot navigation (... for ../../, .... for ../../../, etc.)"
    # Handle multi-dot pattern for navigating up directories
    if string match -qr '^\\.{3,}$' -- $argv[1]
        # Count dots and convert to ../../../ format
        set -l dot_count (string length $argv[1])
        set -l path_parts
        for i in (seq 1 (math $dot_count - 1))
            set -a path_parts ".."
        end
        set argv[1] (string join "/" $path_parts)
    end

    # Call the built-in cd with all arguments
    builtin cd $argv
end
