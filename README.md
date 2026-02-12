# hammerspoon-claude-usage

macOS에서 Claude 사용량을 실시간으로 모니터링하는 Hammerspoon 위젯

## 스크린샷

```
┌─────────────┐ ┌─────────────┐
│   current   │ │   weekly    │
│ 92% (3h19m) │ │ 41% (4h19m) │
└─────────────┘ └─────────────┘
```

## 요구 사항

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- Safari (claude.ai 로그인 상태 유지)

## 설치

### 1. Safari 설정

Safari → 설정 → Developer → **Allow JavaScript from Apple Events** 체크

### 2. 파일 복사

```bash
# Hammerspoon 스크립트
cp claude-usage.lua ~/.hammerspoon/

# 데이터 추출 스크립트
mkdir -p ~/.local/bin
cp claude-usage.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-usage.sh

# LaunchAgent (1분마다 자동 실행)
cp com.user.claude-usage.plist ~/Library/LaunchAgents/
```

### 3. init.lua에 추가

`~/.hammerspoon/init.lua`에 다음 추가:

```lua
local claudeUsage = require("claude-usage")
claudeUsage.start()
```

### 4. 서비스 시작

```bash
# LaunchAgent 로드
launchctl load ~/Library/LaunchAgents/com.user.claude-usage.plist

# Hammerspoon 리로드
# 메뉴바 아이콘 → Reload Config
```

## 사용법

1. Safari에서 https://claude.ai/settings/usage 페이지를 열어둠
2. 위젯이 자동으로 사용량 표시 (1분마다 갱신)

## 표시 정보

- **current**: 현재 세션 남은 사용량 (%)
- **weekly**: 주간 남은 사용량 (%)
- 괄호 안: 리셋까지 남은 시간

## 제거

```bash
launchctl unload ~/Library/LaunchAgents/com.user.claude-usage.plist
rm ~/Library/LaunchAgents/com.user.claude-usage.plist
rm ~/.local/bin/claude-usage.sh
rm ~/.hammerspoon/claude-usage.lua
rm ~/.claude-usage.json
```
