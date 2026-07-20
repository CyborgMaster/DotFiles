#!/usr/bin/env bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)
line="$model"
[ -n "$ctx" ] && line="$line | ${ctx}% ctx"
[ -n "$line" ] && echo "$line"
