#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
dir=$(echo "$input" | jq -r '.workspace.current_dir')
pct=$(echo "$input" | jq -r '.context_window.used_percentage')
branch=$(echo "$input" | jq -r '.git.branch // empty')
added=$(echo "$input" | jq -r '.metrics.files.total_lines_added')
removed=$(echo "$input" | jq -r '.metrics.files.total_lines_removed')
total_tokens=$(echo "$input" | jq -r --arg m "$model" '.metrics.models[$m].tokens.total // 0')
input_tokens=$(echo "$input" | jq -r --arg m "$model" '.metrics.models[$m].tokens.prompt // 0')
output_tokens=$(echo "$input" | jq -r --arg m "$model" '.metrics.models[$m].tokens.completion // 0')
cache_tokens=$(echo "$input" | jq -r --arg m "$model" '.metrics.models[$m].tokens.cached // 0')
thoughts_tokens=$(echo "$input" | jq -r --arg m "$model" '.metrics.models[$m].tokens.thoughts // 0')

if [ "$input_tokens" -gt 0 ] 2>/dev/null; then
  cache_hit_rate=$(awk "BEGIN {printf \"%.1f\", ($cache_tokens / $input_tokens) * 100}")
else
  cache_hit_rate="0.0"
fi

parts=()
[ -n "$model" ] && parts+=("$model")
[ -n "$branch" ] && parts+=("($branch)")
[ "$pct" != "0" ] 2>/dev/null && parts+=("ctx:${pct}%")
([ "$added" -gt 0 ] || [ "$removed" -gt 0 ]) 2>/dev/null && parts+=("+${added}/-${removed}")
 
echo "Models: $model | Dir: $dir | Env: $CONDA_DEFAULT_ENV"
echo "Tokens: $total_tokens | Input: $input_tokens | Output: $output_tokens | Cache: $cache_tokens (${cache_hit_rate}%) | Thoughts: $thoughts_tokens"
