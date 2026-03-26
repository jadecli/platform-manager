#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code status line — reads JSON from stdin, prints a single line.
# Optimized: single jq call, minimal subprocesses.
# Compatible with Claude Code ≥2.1.79

# --- Single jq call extracts all fields as tab-separated values ---
IFS=$'\t' read -r cwd model used vim_mode worktree wt_branch wt_orig_branch agent cost lines_add lines_rm added_dirs api_dur version rl_5h rl_7d cache_read cache_write ctx_size <<< \
  "$(jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.context_window.used_percentage // ""),
    (.vim.mode // ""),
    (.worktree.name // ""),
    (.worktree.branch // ""),
    (.worktree.original_branch // ""),
    (.agent.name // ""),
    (if .cost.total_cost_usd then (.cost.total_cost_usd * 100 | round / 100 | tostring) else "" end),
    (.cost.total_lines_added // "" | tostring),
    (.cost.total_lines_removed // "" | tostring),
    ((.workspace.added_dirs // []) | length | tostring),
    (if .cost.total_api_duration_ms then (.cost.total_api_duration_ms / 1000 | floor | tostring) else "" end),
    (.version // ""),
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring),
    (.context_window.current_usage.cache_read_input_tokens // "" | tostring),
    (.context_window.current_usage.cache_creation_input_tokens // "" | tostring),
    (.context_window.context_window_size // "" | tostring)
  ] | join("\t")')"

# --- Git branch (only external subprocess besides jq) ---
git_branch=""
if [[ -n "$cwd" ]]; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi
[[ -z "$git_branch" && -n "$wt_branch" ]] && git_branch="$wt_branch"

# --- Directory: last 2 path components ---
if [[ "$cwd" == "$HOME" ]]; then
  short_dir="~"
else
  short_dir=$(echo "$cwd" | awk -F'/' '{n=NF; if(n>=2) print $(n-1)"/"$n; else print $n}')
fi

# --- ANSI codes ---
RST='\033[0m'; DIM='\033[2m'; BOLD='\033[1m'
CYN='\033[36m'; GRN='\033[32m'; YLW='\033[33m'; BLU='\033[34m'; MAG='\033[35m'; RED='\033[31m'

parts=()

# Vim mode
if [[ -n "$vim_mode" ]]; then
  [[ "$vim_mode" == "NORMAL" ]] && parts+=("$(printf "${BOLD}${YLW}[N]${RST}")") || parts+=("$(printf "${BOLD}${GRN}[I]${RST}")")
fi

# Agent badge
[[ -n "$agent" ]] && parts+=("$(printf "${BOLD}${MAG}@${agent}${RST}")")

# Worktree badge (v2.1.69+) — bold inverse so it's unmissable
if [[ -n "$worktree" ]]; then
  wt_label="WORKTREE: ${worktree}"
  [[ -n "$wt_orig_branch" ]] && wt_label="${wt_label} (from ${wt_orig_branch})"
  parts+=("$(printf "\033[1;7;34m %s \033[0m" "$wt_label")")
fi

# Directory
parts+=("$(printf "${CYN}${short_dir}${RST}")")

# Added dirs count (v2.1.47+ workspace.added_dirs)
if [[ -n "$added_dirs" && "$added_dirs" != "0" ]]; then
  parts+=("$(printf "${DIM}+${added_dirs} dirs${RST}")")
fi

# Git branch
if [[ -n "$git_branch" ]]; then
  if [[ -n "$worktree" ]]; then
    parts+=("$(printf "${BOLD}${BLU} ${git_branch}${RST}")")
  else
    parts+=("$(printf "${GRN} ${git_branch}${RST}")")
  fi
fi

# Model (drop "Claude " prefix and parenthetical suffixes)
short_model="${model#Claude }"
short_model="${short_model%% (*}"
[[ -n "$short_model" ]] && parts+=("$(printf "${DIM}${short_model}${RST}")")

# Claude Code version
[[ -n "$version" ]] && parts+=("$(printf "${DIM}v${version}${RST}")")

# Context usage — color shifts green→yellow→red
if [[ -n "$used" ]]; then
  used_int=${used%.*}
  if (( used_int >= 80 )); then ctx_c="$RED"
  elif (( used_int >= 50 )); then ctx_c="$YLW"
  else ctx_c="$GRN"; fi
  # 10-char block bar
  filled=$(( used_int / 10 ))
  bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=filled; i<10; i++ )); do bar+="░"; done
  # Context window size indicator (200K vs 1M)
  ctx_label=""
  if [[ -n "$ctx_size" && "$ctx_size" -ge 1000000 ]] 2>/dev/null; then
    ctx_label=" 1M"
  fi
  parts+=("$(printf "${ctx_c}${bar} ${used_int}%%${ctx_label}${RST}")")
fi

# Prompt cache hit ratio — shows how much of input is served from cache
if [[ -n "$cache_read" && "$cache_read" != "0" ]]; then
  cache_read_k=$(( cache_read / 1000 ))
  if [[ -n "$cache_write" && "$cache_write" != "0" ]]; then
    cache_total=$(( cache_read + cache_write ))
    cache_pct=$(( cache_read * 100 / cache_total ))
    parts+=("$(printf "${DIM}cache:${RST}${GRN}${cache_pct}%%${RST}${DIM}(${cache_read_k}k)${RST}")")
  else
    parts+=("$(printf "${GRN}cache:${cache_read_k}k${RST}")")
  fi
elif [[ -n "$cache_write" && "$cache_write" != "0" ]]; then
  cache_write_k=$(( cache_write / 1000 ))
  parts+=("$(printf "${DIM}cache:w${cache_write_k}k${RST}")")
fi

# Cost
if [[ -n "$cost" && "$cost" != "0" ]]; then
  parts+=("$(printf "${DIM}\$${cost}${RST}")")
fi

# API duration (seconds) — complements 2.1.79 "show turn duration" config
if [[ -n "$api_dur" && "$api_dur" != "0" ]]; then
  if (( api_dur >= 60 )); then
    parts+=("$(printf "${DIM}⏱ $((api_dur/60))m$((api_dur%60))s${RST}")")
  else
    parts+=("$(printf "${DIM}⏱ ${api_dur}s${RST}")")
  fi
fi

# Lines changed (compact +N/-M)
if [[ -n "$lines_add" && "$lines_add" != "0" ]] || [[ -n "$lines_rm" && "$lines_rm" != "0" ]]; then
  parts+=("$(printf "${GRN}+${lines_add:-0}${RST}${DIM}/${RST}${RED}-${lines_rm:-0}${RST}")")
fi

# Rate limits (v2.1.80+ rate_limits.five_hour / seven_day)
if [[ -n "$rl_5h" && "$rl_5h" != "0" ]] || [[ -n "$rl_7d" && "$rl_7d" != "0" ]]; then
  rl_parts=""
  if [[ -n "$rl_5h" && "$rl_5h" != "0" ]]; then
    rl_5h_int=${rl_5h%.*}
    if (( rl_5h_int >= 80 )); then rl5c="$RED"
    elif (( rl_5h_int >= 50 )); then rl5c="$YLW"
    else rl5c="$GRN"; fi
    rl_parts="$(printf "${rl5c}5h:${rl_5h_int}%%${RST}")"
  fi
  if [[ -n "$rl_7d" && "$rl_7d" != "0" ]]; then
    rl_7d_int=${rl_7d%.*}
    if (( rl_7d_int >= 80 )); then rl7c="$RED"
    elif (( rl_7d_int >= 50 )); then rl7c="$YLW"
    else rl7c="$GRN"; fi
    [[ -n "$rl_parts" ]] && rl_parts="${rl_parts} "
    rl_parts="${rl_parts}$(printf "${rl7c}7d:${rl_7d_int}%%${RST}")"
  fi
  parts+=("$rl_parts")
fi

# --- Join with separator ---
sep="$(printf "${DIM} · ${RST}")"
line=""
for part in "${parts[@]}"; do
  [[ -z "$line" ]] && line="$part" || line="${line}${sep}${part}"
done

printf "%s\n" "$line"
