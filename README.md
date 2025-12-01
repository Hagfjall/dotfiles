TODO

- [ ]  Clean git branches ```
        git fetch --prune && \
        ( \
          git branch --merged origin/main | grep -vE '^\*|main|master'; \
          comm -23 <(git branch | sed 's/^..//' | sort) <(git branch -r | sed 's|origin/||' | sort) | grep -vE 'main|master' \
        ) | sort | uniq | xargs -n 1 git branch -d```
