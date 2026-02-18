#!/bin/bash

# Claude Usage Fetcher (tmux 기반)
# tmux 세션에서 claude /usage 명령어로 사용량 조회

# LaunchAgent 환경용 PATH 설정
export PATH="/opt/homebrew/bin:/Users/hanju/.local/bin:$PATH"

OUTPUT_FILE="$HOME/.claude-usage.json"
SESSION_NAME="claude-usage"
ERROR_COUNT_FILE="$HOME/.claude-usage-error-count"
MAX_ERROR_COUNT=6

# 에러 카운트 읽기
get_error_count() {
    if [[ -f "$ERROR_COUNT_FILE" ]]; then
        cat "$ERROR_COUNT_FILE"
    else
        echo 0
    fi
}

# 에러 카운트 증가
increment_error_count() {
    local count
    count=$(get_error_count)
    echo $((count + 1)) > "$ERROR_COUNT_FILE"
}

# 에러 카운트 리셋
reset_error_count() {
    echo 0 > "$ERROR_COUNT_FILE"
}

# 세션 강제 재시작
force_restart_session() {
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    reset_error_count
    # 새 세션은 ensure_session에서 생성됨
}

# tmux 세션 확인 및 생성
ensure_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # 세션 생성 및 claude 실행
        tmux new-session -d -s "$SESSION_NAME" -x 120 -y 30
        tmux send-keys -t "$SESSION_NAME" "cd ~ && claude" Enter

        # claude 시작 대기 (trust 확인 포함)
        sleep 5
        tmux send-keys -t "$SESSION_NAME" Enter  # trust 확인
        sleep 5

        echo '{"error": "Session starting, wait..."}' > "$OUTPUT_FILE"
        exit 0
    fi
}

# /usage 실행 및 결과 캡처
get_usage() {
    # 입력 초기화
    tmux send-keys -t "$SESSION_NAME" C-c
    sleep 1

    # /usage 명령어 전송 (자동완성 메뉴 표시)
    tmux send-keys -t "$SESSION_NAME" "/usage" Enter
    sleep 1

    # 자동완성 선택 (다이얼로그 열기)
    tmux send-keys -t "$SESSION_NAME" Enter
    sleep 2

    # 화면 캡처 (다이얼로그가 열린 상태)
    local output
    output=$(tmux capture-pane -t "$SESSION_NAME" -p)

    # ESC로 닫기
    tmux send-keys -t "$SESSION_NAME" Escape

    echo "$output"
}

# 12시간 형식을 24시간으로 변환 (예: "10:59pm" -> "22:59")
convert_to_24h() {
    local time_12="$1"
    local hour min ampm

    if [[ "$time_12" =~ ^([0-9]+):([0-9]+)(am|pm)$ ]]; then
        hour="${BASH_REMATCH[1]}"
        min="${BASH_REMATCH[2]}"
        ampm="${BASH_REMATCH[3]}"
    elif [[ "$time_12" =~ ^([0-9]+)(am|pm)$ ]]; then
        hour="${BASH_REMATCH[1]}"
        min="00"
        ampm="${BASH_REMATCH[2]}"
    else
        echo ""
        return
    fi

    # 12시간 -> 24시간 변환
    if [[ "$ampm" == "pm" && "$hour" -ne 12 ]]; then
        hour=$((hour + 12))
    elif [[ "$ampm" == "am" && "$hour" -eq 12 ]]; then
        hour=0
    fi

    printf "%02d:%02d" "$hour" "$min"
}

# 시간 문자열을 남은 시간으로 변환
# 입력 형식: "10:59pm (Asia/Seoul)" 또는 "Feb 19 at 6:59pm (Asia/Seoul)"
# 출력 형식: "3h 49m" (24시간 미만) 또는 "6d 23h" (1일 이상)
calc_remaining() {
    local reset_str="$1"

    # 현재 시간 (초 단위)
    local now_sec
    now_sec=$(date +%s)

    local reset_sec=""

    # 날짜가 포함된 형식인지 확인 (Feb 19 at 6:59pm)
    if echo "$reset_str" | grep -qE "[A-Za-z]+ [0-9]+ at"; then
        # grep으로 파싱
        local month_name month_num day time_12 hour min ampm
        month_name=$(echo "$reset_str" | grep -oE "^[A-Za-z]+" | head -1)
        day=$(echo "$reset_str" | grep -oE "[A-Za-z]+ ([0-9]+) at" | grep -oE "[0-9]+")
        time_12=$(echo "$reset_str" | grep -oE "[0-9]+:?[0-9]*[ap]m" | head -1)

        if [[ -z "$month_name" || -z "$day" || -z "$time_12" ]]; then
            echo "--"
            return
        fi

        # 월 이름을 숫자로 변환
        case "$month_name" in
            Jan) month_num=01 ;; Feb) month_num=02 ;; Mar) month_num=03 ;;
            Apr) month_num=04 ;; May) month_num=05 ;; Jun) month_num=06 ;;
            Jul) month_num=07 ;; Aug) month_num=08 ;; Sep) month_num=09 ;;
            Oct) month_num=10 ;; Nov) month_num=11 ;; Dec) month_num=12 ;;
            *) echo "--"; return ;;
        esac

        # 시간 파싱 (sed 사용)
        hour=$(echo "$time_12" | sed -E 's/^([0-9]+):?[0-9]*(am|pm)$/\1/')
        min=$(echo "$time_12" | sed -E 's/^[0-9]+:([0-9]+)(am|pm)$/\1/')
        ampm=$(echo "$time_12" | sed -E 's/^[0-9]+:?[0-9]*(am|pm)$/\1/')

        # 분이 없으면 00
        if [[ "$min" == "$time_12" ]]; then
            min="00"
        fi

        if [[ -z "$hour" || -z "$ampm" ]]; then
            echo "--"
            return
        fi

        # 12시간 -> 24시간 변환
        if [[ "$ampm" == "pm" && "$hour" -ne 12 ]]; then
            hour=$((hour + 12))
        elif [[ "$ampm" == "am" && "$hour" -eq 12 ]]; then
            hour=0
        fi

        # 현재 연도
        local year
        year=$(date +%Y)

        # 리셋 시간 파싱 (MM/dd/YYYY HH:MM 형식 사용)
        reset_sec=$(date -j -f "%m/%d/%Y %H:%M" "$month_num/$day/$year $(printf "%02d" "$hour"):$(printf "%02d" "$min")" +%s 2>/dev/null)

        # 리셋이 과거면 내년으로
        if [[ -n "$reset_sec" && $reset_sec -le $now_sec ]]; then
            year=$((year + 1))
            reset_sec=$(date -j -f "%m/%d/%Y %H:%M" "$month_num/$day/$year $(printf "%02d" "$hour"):$(printf "%02d" "$min")" +%s 2>/dev/null)
        fi
    else
        # 시간만 있는 형식 (10:59pm)
        local time_12
        time_12=$(echo "$reset_str" | grep -oE "[0-9]+:?[0-9]*[ap]m" | head -1)

        if [[ -z "$time_12" ]]; then
            echo "--"
            return
        fi

        # 24시간 형식으로 변환
        local time_24
        time_24=$(convert_to_24h "$time_12")

        if [[ -z "$time_24" ]]; then
            echo "--"
            return
        fi

        # 리셋 시간 파싱
        reset_sec=$(date -j -f "%H:%M" "$time_24" +%s 2>/dev/null)

        # 리셋이 과거면 내일로
        if [[ -n "$reset_sec" && $reset_sec -le $now_sec ]]; then
            reset_sec=$((reset_sec + 86400))
        fi
    fi

    if [[ -z "$reset_sec" ]]; then
        echo "--"
        return
    fi

    # 남은 시간 계산
    local diff=$((reset_sec - now_sec))
    local days=$((diff / 86400))
    local hours=$(((diff % 86400) / 3600))
    local mins=$(((diff % 3600) / 60))

    # 1일 이상이면 "Xd Xh", 아니면 "Xh Xm"
    if [[ $days -ge 1 ]]; then
        echo "${days}d ${hours}h"
    else
        echo "${hours}h ${mins}m"
    fi
}

# 출력 파싱
parse_usage() {
    local output="$1"

    # Current session 퍼센트 추출
    local session_percent
    session_percent=$(echo "$output" | grep -A1 "Current session" | grep -oE "[0-9]+% used" | grep -oE "[0-9]+")

    # Current week (all models) 퍼센트 추출
    local weekly_percent
    weekly_percent=$(echo "$output" | grep -A1 "Current week (all models)" | grep -oE "[0-9]+% used" | grep -oE "[0-9]+")

    # 리셋 시간 추출
    local session_reset_raw
    session_reset_raw=$(echo "$output" | grep -A2 "Current session" | grep "Resets" | sed 's/.*Resets //' | tr -d '\n')

    local weekly_reset_raw
    weekly_reset_raw=$(echo "$output" | grep -A2 "Current week (all models)" | grep "Resets" | sed 's/.*Resets //' | tr -d '\n')

    # 남은 시간으로 변환
    local session_reset
    session_reset=$(calc_remaining "$session_reset_raw")

    local weekly_reset
    weekly_reset=$(calc_remaining "$weekly_reset_raw")

    # JSON 생성
    if [[ -n "$session_percent" && -n "$weekly_percent" ]]; then
        cat << EOF
{"sessionPercent":$session_percent,"weeklyPercent":$weekly_percent,"sessionReset":"$session_reset","weeklyReset":"$weekly_reset","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"}
EOF
    else
        echo '{"error": "Parse failed"}'
    fi
}

# 메인

# 연속 에러 체크 및 세션 재시작
error_count=$(get_error_count)
if [[ $error_count -ge $MAX_ERROR_COUNT ]]; then
    force_restart_session
fi

ensure_session
output=$(get_usage)
result=$(parse_usage "$output")

# 에러 여부에 따라 카운트 관리
if echo "$result" | grep -q '"error"'; then
    increment_error_count
else
    reset_error_count
fi

echo "$result" > "$OUTPUT_FILE"
