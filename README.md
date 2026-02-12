# Hammerspoon Claude Usage Widget

Claude Code CLI의 사용량을 화면에 표시하는 Hammerspoon 위젯입니다.

## 구성 요소

- `claude-usage.sh` - tmux를 통해 Claude CLI `/usage` 명령 실행 및 데이터 추출
- `claude-usage.lua` - Hammerspoon 위젯 (current/weekly 2개)
- `com.user.claude-usage.plist` - LaunchAgent (30초마다 실행)

## 동작 방식

1. LaunchAgent가 30초마다 `claude-usage.sh` 실행
2. 스크립트가 tmux 세션에서 Claude CLI `/usage` 명령 실행
3. 결과를 `~/.claude-usage.json`에 저장
4. Hammerspoon 위젯이 10초마다 JSON 읽어서 화면 표시

## 설치

```bash
# 스크립트 복사
cp claude-usage.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-usage.sh

# Hammerspoon 모듈 복사
cp claude-usage.lua ~/.hammerspoon/

# LaunchAgent 등록
cp com.user.claude-usage.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.claude-usage.plist
```

## Hammerspoon 설정

`~/.hammerspoon/init.lua`에 추가:

```lua
local claudeUsage = require("claude-usage")
claudeUsage.start()
```

## 위젯 표시

- **current**: 현재 세션 남은 사용량 (%)
- **weekly**: 주간 남은 사용량 (%)
- 초록색: 정상
- 주황색: 로딩 중
- 빨간색: 에러

## 요구사항

- macOS
- Hammerspoon
- Claude Code CLI (`claude` 명령)
- tmux

## Legacy (Safari 기반)

이전 Safari 기반 구현은 `legacy-*` 파일들에 보존되어 있습니다.
