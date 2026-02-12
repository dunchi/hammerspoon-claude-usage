#!/bin/bash

# Claude Usage Fetcher (tmux 기반)
# tmux 세션에서 claude /usage 명령어로 사용량 조회

# LaunchAgent 환경용 PATH 설정
export PATH="/opt/homebrew/bin:/Users/hanju/.local/bin:$PATH"

OUTPUT_FILE="$HOME/.claude-usage.json"
SESSION_NAME="claude-usage"

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

# 시간 문자열을 남은 시간으로 변환 (예: "10:59pm (Asia/Seoul)" -> "3hr 19min")
calc_remaining() {
    local reset_str="$1"

    # 시간 추출 (예: "10:59pm" 또는 "11pm")
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

    # 현재 시간 (초 단위)
    local now_sec
    now_sec=$(date +%s)

    # 리셋 시간 파싱
    local reset_sec
    reset_sec=$(date -j -f "%H:%M" "$time_24" +%s 2>/dev/null)

    if [[ -z "$reset_sec" ]]; then
        echo "--"
        return
    fi

    # 리셋이 과거면 내일로
    if [[ $reset_sec -le $now_sec ]]; then
        reset_sec=$((reset_sec + 86400))
    fi

    # 남은 시간 계산
    local diff=$((reset_sec - now_sec))
    local hours=$((diff / 3600))
    local mins=$(((diff % 3600) / 60))

    echo "${hours}h ${mins}m"
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
ensure_session
output=$(get_usage)
result=$(parse_usage "$output")
echo "$result" > "$OUTPUT_FILE"
