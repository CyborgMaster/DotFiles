#!/usr/bin/env bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
[ -n "$model" ] && echo "$model"
