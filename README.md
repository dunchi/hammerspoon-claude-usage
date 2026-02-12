# Hammerspoon Claude Usage Widget

Claude Code CLI의 사용량을 화면에 표시하는 Hammerspoon 위젯입니다.

## 구성 요소

- `claude-usage.sh` - tmux를 통해 Claude CLI `/usage` 명령 실행 및 데이터 추출
- `claude-usage.lua` - Hammerspoon 위젯 + 데이터 수집 (30초마다)

## 동작 방식

1. Hammerspoon 위젯이 30초마다 `claude-usage.sh` 실행
2. 스크립트가 tmux 세션에서 Claude CLI `/usage` 명령 실행
3. 결과를 `~/.claude-usage.json`에 저장
4. 위젯이 10초마다 JSON 읽어서 화면 표시
5. Hammerspoon 종료 시 데이터 수집도 중지

## 설치

```bash
# 스크립트 복사
cp claude-usage.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-usage.sh

# Hammerspoon 모듈 복사
cp claude-usage.lua ~/.hammerspoon/
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

## Legacy

이전 구현은 `legacy-*` 파일들에 보존되어 있습니다.
