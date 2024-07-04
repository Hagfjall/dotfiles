#!/bin/bash
# shellcheck disable=SC2034
# https://zenn.dev/odan/articles/17a86574b724c9
set -eu

# zsh
if [ -e "/tmp/zsh-bench" ]; then
  rm -rf "/tmp/zsh-bench"
fi
git clone --depth 1  https://github.com/romkatv/zsh-bench.git /tmp/zsh-bench
ZSHRC_BENCH=true /tmp/zsh-bench/zsh-bench -i 1 | tee /tmp/zsh-bench.txt
first_prompt_lag_ms="$(cat /tmp/zsh-bench.txt | grep 'first_prompt_lag_ms' | sed -n 's/.*=\(.*\)/\1/p')"
first_command_lag_ms="$(cat /tmp/zsh-bench.txt | grep 'first_command_lag_ms' | sed -n 's/.*=\(.*\)/\1/p')"

# result
cat <<EOJ | tee /tmp/result-benchmark.json
[
    {
        "name": "zsh first prompt",
        "unit": "ms",
        "value": ${first_prompt_lag_ms}
    },
    {
        "name": "zsh first command",
        "unit": "ms",
        "value": ${first_command_lag_ms}
    }
]
EOJ
