#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code status line — reads JSON from stdin, prints a single line.
# Optimized: single jq call, minimal subprocesses, cached git/PR lookups.
# Compatible with Claude Code ≥2.1.79
#
# Install: cp hooks/statusline/statusline-command.sh ~/.claude/statusline-command.sh

# --- Single jq call extracts all fields ---
# NOTE: Uses unit separator (\x1f) instead of tab. Bash `read` with IFS=$'\t'
# collapses consecutive tabs, eating empty fields. \x1f is non-whitespace so
# `read` preserves every empty field correctly.
SEP=$'\x1f'
IFS="$SEP" read -r cwd model used vim_mode worktree wt_branch wt_orig_branch agent cost lines_add lines_rm added_dirs api_dur version rl_5h rl_7d cache_read cache_write ctx_size <<< \
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
  ] | join("\u001f")')"

# --- ANSI codes ---
RST='\033[0m'; DIM='\033[2m'; BOLD='\033[1m'
CYN='\033[36m'; GRN='\033[32m'; YLW='\033[33m'; BLU='\033[34m'; MAG='\033[35m'; RED='\033[31m'

# --- Git branch ---
git_branch=""
if [[ -n "$cwd" ]]; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi
[[ -z "$git_branch" && -n "$wt_branch" ]] && git_branch="$wt_branch"

# --- Git status (cached, 5s TTL) ---
git_dirty=""
if [[ -n "$cwd" && -d "$cwd/.git" ]] || git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  cache_file="/tmp/claude-statusline-git"
  now=$(date +%s)
  refresh=1
  if [[ -f "$cache_file" ]]; then
    cache_age=$(( now - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
    cache_cwd=$(head -1 "$cache_file")
    [[ "$cache_cwd" == "$cwd" && "$cache_age" -lt 5 ]] && refresh=0
  fi
  if [[ "$refresh" -eq 1 ]]; then
    counts=$(git -C "$cwd" status --porcelain 2>/dev/null | awk '
      { total++ }
      /^[MADRCU]/ { staged++ }
      /^.[MADRCU?]/ { unstaged++ }
      END { printf "%d\t%d\t%d", total+0, staged+0, unstaged+0 }
    ')
    printf "%s\n%s\n" "$cwd" "$counts" > "$cache_file"
  fi
  IFS=$'\t' read -r gt_total gt_staged gt_unstaged <<< "$(tail -1 "$cache_file")"
  if [[ "$gt_total" -gt 0 ]] 2>/dev/null; then
    git_dirty="$(printf "${YLW}●${gt_staged:-0}${RST}${RED}+${gt_unstaged:-0}${RST}")"
  else
    git_dirty="$(printf "${GRN}✓${RST}")"
  fi
fi

# --- PR number (cached, 60s TTL) ---
pr_num=""
if [[ -n "$git_branch" && "$git_branch" != "main" && "$git_branch" != "master" ]]; then
  pr_cache="/tmp/claude-statusline-pr"
  now=${now:-$(date +%s)}
  pr_refresh=1
  if [[ -f "$pr_cache" ]]; then
    pr_age=$(( now - $(stat -f %m "$pr_cache" 2>/dev/null || echo 0) ))
    pr_cached_branch=$(head -1 "$pr_cache")
    [[ "$pr_cached_branch" == "$git_branch" && "$pr_age" -lt 60 ]] && pr_refresh=0
  fi
  if [[ "$pr_refresh" -eq 1 ]]; then
    fetched_pr=$(gh pr view "$git_branch" --json number -q .number 2>/dev/null || echo "")
    printf "%s\n%s\n" "$git_branch" "$fetched_pr" > "$pr_cache"
  fi
  pr_num=$(tail -1 "$pr_cache")
fi

# --- Absolute path (tilde-contracted) ---
if [[ "$cwd" == "$HOME"* ]]; then
  display_path="~${cwd#$HOME}"
else
  display_path="$cwd"
fi

parts=()

# Vim mode
if [[ -n "$vim_mode" ]]; then
  [[ "$vim_mode" == "NORMAL" ]] && parts+=("$(printf "${BOLD}${YLW}[N]${RST}")") || parts+=("$(printf "${BOLD}${GRN}[I]${RST}")")
fi

# Agent badge
[[ -n "$agent" ]] && parts+=("$(printf "${BOLD}${MAG}@${agent}${RST}")")

# Worktree badge
if [[ -n "$worktree" ]]; then
  wt_label="WORKTREE: ${worktree}"
  [[ -n "$wt_orig_branch" ]] && wt_label="${wt_label} (from ${wt_orig_branch})"
  parts+=("$(printf "\033[1;7;34m %s \033[0m" "$wt_label")")
fi

# Absolute path (tilde-contracted)
parts+=("$(printf "${CYN}${display_path}${RST}")")

# Added dirs count
if [[ -n "$added_dirs" && "$added_dirs" != "0" ]]; then
  parts+=("$(printf "${DIM}+${added_dirs} dirs${RST}")")
fi

# Git branch + PR number
if [[ -n "$git_branch" ]]; then
  branch_segment=""
  if [[ -n "$worktree" ]]; then
    branch_segment="$(printf "${BOLD}${BLU} ${git_branch}${RST}")"
  else
    branch_segment="$(printf "${GRN} ${git_branch}${RST}")"
  fi
  if [[ -n "$pr_num" ]]; then
    branch_segment="${branch_segment}$(printf "${DIM}#${pr_num}${RST}")"
  fi
  parts+=("$branch_segment")
fi

# Git status indicator
[[ -n "$git_dirty" ]] && parts+=("$git_dirty")

# Model
short_model="${model#Claude }"
short_model="${short_model%% (*}"
[[ -n "$short_model" ]] && parts+=("$(printf "${DIM}${short_model}${RST}")")

# Claude Code version
[[ -n "$version" ]] && parts+=("$(printf "${DIM}v${version}${RST}")")

# Context usage bar
if [[ -n "$used" ]]; then
  used_int=${used%.*}
  if (( used_int >= 80 )); then ctx_c="$RED"
  elif (( used_int >= 50 )); then ctx_c="$YLW"
  else ctx_c="$GRN"; fi
  filled=$(( used_int / 10 ))
  bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=filled; i<10; i++ )); do bar+="░"; done
  ctx_label=""
  if [[ -n "$ctx_size" && "$ctx_size" -ge 1000000 ]] 2>/dev/null; then
    ctx_label=" 1M"
  fi
  parts+=("$(printf "${ctx_c}${bar} ${used_int}%%${ctx_label}${RST}")")
fi

# Prompt cache hit ratio
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

# API duration
if [[ -n "$api_dur" && "$api_dur" != "0" ]]; then
  if (( api_dur >= 60 )); then
    parts+=("$(printf "${DIM}⏱ $((api_dur/60))m$((api_dur%60))s${RST}")")
  else
    parts+=("$(printf "${DIM}⏱ ${api_dur}s${RST}")")
  fi
fi

# Lines changed
if [[ -n "$lines_add" && "$lines_add" != "0" ]] || [[ -n "$lines_rm" && "$lines_rm" != "0" ]]; then
  parts+=("$(printf "${GRN}+${lines_add:-0}${RST}${DIM}/${RST}${RED}-${lines_rm:-0}${RST}")")
fi

# Rate limits
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
