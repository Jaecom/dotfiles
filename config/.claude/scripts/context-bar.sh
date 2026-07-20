#!/bin/bash

# Color theme: gray, orange, blue, teal, green, lavender, rose, gold, slate, cyan
# Preview colors with: bash scripts/color-preview.sh
COLOR="orange"

# Color codes
C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'  # explicit gray for default text
C_BAR_EMPTY='\033[38;5;238m'
case "$COLOR" in
    orange)   C_ACCENT='\033[38;5;173m' ;;
    blue)     C_ACCENT='\033[38;5;74m' ;;
    teal)     C_ACCENT='\033[38;5;66m' ;;
    green)    C_ACCENT='\033[38;5;71m' ;;
    lavender) C_ACCENT='\033[38;5;139m' ;;
    rose)     C_ACCENT='\033[38;5;132m' ;;
    gold)     C_ACCENT='\033[38;5;136m' ;;
    slate)    C_ACCENT='\033[38;5;60m' ;;
    cyan)     C_ACCENT='\033[38;5;37m' ;;
    *)        C_ACCENT="$C_GRAY" ;;  # gray: all same color
esac

input=$(cat)

# Extract model, directory, and cwd
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
cwd=$(echo "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd" 2>/dev/null || echo "?")

# Get git branch, uncommitted file count, and sync status
branch=""
git_status=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        # Count uncommitted files
        file_count=$(git -C "$cwd" --no-optional-locks status --porcelain -uall 2>/dev/null | wc -l | tr -d ' ')

        # Check sync status with upstream
        sync_status=""
        upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            # Get last fetch time
            fetch_head="$cwd/.git/FETCH_HEAD"
            fetch_ago=""
            if [[ -f "$fetch_head" ]]; then
                fetch_time=$(stat -f %m "$fetch_head" 2>/dev/null || stat -c %Y "$fetch_head" 2>/dev/null)
                if [[ -n "$fetch_time" ]]; then
                    now=$(date +%s)
                    diff=$((now - fetch_time))
                    if [[ $diff -lt 60 ]]; then
                        fetch_ago="<1m ago"
                    elif [[ $diff -lt 3600 ]]; then
                        fetch_ago="$((diff / 60))m ago"
                    elif [[ $diff -lt 86400 ]]; then
                        fetch_ago="$((diff / 3600))h ago"
                    else
                        fetch_ago="$((diff / 86400))d ago"
                    fi
                fi
            fi

            counts=$(git -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
            ahead=$(echo "$counts" | cut -f1)
            behind=$(echo "$counts" | cut -f2)
            if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
                if [[ -n "$fetch_ago" ]]; then
                    sync_status="synced ${fetch_ago}"
                else
                    sync_status="synced"
                fi
            elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
                sync_status="${ahead} ahead"
            elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
                sync_status="${behind} behind"
            else
                sync_status="${ahead} ahead, ${behind} behind"
            fi
        else
            sync_status="no upstream"
        fi

        # Build git status string
        if [[ "$file_count" -eq 0 ]]; then
            git_status="(0 files uncommitted, ${sync_status})"
        elif [[ "$file_count" -eq 1 ]]; then
            # Show the actual filename when only one file is uncommitted
            single_file=$(git -C "$cwd" --no-optional-locks status --porcelain -uall 2>/dev/null | head -1 | sed 's/^...//')
            git_status="(${single_file} uncommitted, ${sync_status})"
        else
            git_status="(${file_count} files uncommitted, ${sync_status})"
        fi
    fi
fi

# Get transcript path for context calculation and last message feature
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Get context window size from JSON (accurate), but calculate tokens from transcript
# (more accurate than total_input_tokens which excludes system prompt/tools/memory)
# See: github.com/anthropics/claude-code/issues/13652
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
max_k=$((max_context / 1000))

# Calculate context bar from transcript
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    context_length=$(jq -s '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        last |
        if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end
    ' < "$transcript_path")

    # 20k baseline: includes system prompt (~3k), tools (~15k), memory (~300),
    # plus ~2k for git status, env block, XML framing, and other dynamic context
    baseline=20000

    if [[ "$context_length" -gt 0 ]]; then
        pct=$((context_length * 100 / max_context))
        pct_prefix=""
    else
        # At conversation start, ~20k baseline is already loaded
        pct=$((baseline * 100 / max_context))
        pct_prefix="~"
    fi

    [[ $pct -gt 100 ]] && pct=100

    bar=""
    for ((i=0; i<5; i++)); do
        progress=$((pct - i * 20))
        if [[ $progress -ge 15 ]]; then
            bar+="${C_ACCENT}█${C_RESET}"
        elif [[ $progress -ge 5 ]]; then
            bar+="${C_ACCENT}▄${C_RESET}"
        else
            bar+="${C_BAR_EMPTY}░${C_RESET}"
        fi
    done

    ctx="${bar} ${C_GRAY}${pct_prefix}${pct}% (${max_k}k)"
else
    # Transcript not available yet - show baseline estimate
    baseline=20000
    pct=$((baseline * 100 / max_context))
    [[ $pct -gt 100 ]] && pct=100

    bar=""
    for ((i=0; i<5; i++)); do
        progress=$((pct - i * 20))
        if [[ $progress -ge 15 ]]; then
            bar+="${C_ACCENT}█${C_RESET}"
        elif [[ $progress -ge 5 ]]; then
            bar+="${C_ACCENT}▄${C_RESET}"
        else
            bar+="${C_BAR_EMPTY}░${C_RESET}"
        fi
    done

    ctx="${bar} ${C_GRAY}~${pct}% of ${max_k}k tokens"
fi

# Build rate limit bars from statusLine JSON (subscription usage)
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

five_hour_str=""
if [[ -n "$five_hour_pct" ]]; then
    if [[ "$five_hour_pct" -ge 80 ]]; then
        C_RATE='\033[38;5;196m'
    elif [[ "$five_hour_pct" -ge 60 ]]; then
        C_RATE='\033[38;5;214m'
    else
        C_RATE="$C_ACCENT"
    fi

    bar_5h=""
    for ((i=0; i<5; i++)); do
        progress=$((five_hour_pct - i * 20))
        if [[ $progress -ge 15 ]]; then
            bar_5h+="${C_RATE}█${C_RESET}"
        elif [[ $progress -ge 5 ]]; then
            bar_5h+="${C_RATE}▄${C_RESET}"
        else
            bar_5h+="${C_BAR_EMPTY}░${C_RESET}"
        fi
    done

    reset_str=""
    if [[ -n "$five_hour_resets" ]]; then
        now=$(date +%s)
        left=$((five_hour_resets - now))
        if [[ $left -gt 0 ]]; then
            h=$((left / 3600))
            m=$(( (left % 3600) / 60 ))
            [[ $h -gt 0 ]] && reset_str=" (resets ${h}h ${m}m)" || reset_str=" (resets ${m}m)"
        fi
    fi

    five_hour_str="${bar_5h} ${C_GRAY}5h ${five_hour_pct}%${reset_str}"
fi

seven_day_str=""
if [[ -n "$seven_day_pct" ]]; then
    bar_7d=""
    for ((i=0; i<5; i++)); do
        progress=$((seven_day_pct - i * 20))
        if [[ $progress -ge 15 ]]; then
            bar_7d+="${C_ACCENT}█${C_RESET}"
        elif [[ $progress -ge 5 ]]; then
            bar_7d+="${C_ACCENT}▄${C_RESET}"
        else
            bar_7d+="${C_BAR_EMPTY}░${C_RESET}"
        fi
    done
    seven_day_str="${bar_7d} ${C_GRAY}7d ${seven_day_pct}%"
fi

# Line 1: Model | Dir | Branch (git_status)
line1="${C_ACCENT}${model}${C_GRAY} | 📁 ${dir}"
[[ -n "$branch" ]] && line1+=" | 🔀 ${branch} ${git_status}"
line1+="${C_RESET}"

# Line 2: indented to align with content after model name, then context · 5h · 7d
indent=$(printf '%*s' $((${#model} + 1)) '')
line2="${C_GRAY}${indent}| ${C_RESET}${ctx}"
[[ -n "$five_hour_str" ]] && line2+="${C_GRAY} | ${C_RESET}${five_hour_str}"
[[ -n "$seven_day_str" ]] && line2+="${C_GRAY} | ${C_RESET}${seven_day_str}"
line2+="${C_RESET}"

printf '%b\n' "$line1"
printf '%b\n' "$line2"

# Get user's last message (text only, not tool results, skip unhelpful messages)
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    # Calculate visible length (without ANSI codes) - 10 chars for bar + content
    plain_output="${model} | 📁${dir}"
    [[ -n "$branch" ]] && plain_output+=" | 🔀${branch} ${git_status}"
    max_len=${#plain_output}
    last_user_msg=$(jq -rs '
        # Messages to skip (not useful as context)
        def is_unhelpful:
            startswith("[Request interrupted") or
            startswith("[Request cancelled") or
            . == "";

        [.[] | select(.type == "user") |
         select(.message.content | type == "string" or
                (type == "array" and any(.[]; .type == "text")))] |
        reverse |
        map(.message.content |
            if type == "string" then .
            else [.[] | select(.type == "text") | .text] | join(" ") end |
            gsub("\n"; " ") | gsub("  +"; " ")) |
        map(select(is_unhelpful | not)) |
        first // ""
    ' < "$transcript_path" 2>/dev/null)

    if [[ -n "$last_user_msg" ]]; then
        if [[ ${#last_user_msg} -gt $max_len ]]; then
            echo "💬 ${last_user_msg:0:$((max_len - 3))}..."
        else
            echo "💬 ${last_user_msg}"
        fi
    fi
fi
