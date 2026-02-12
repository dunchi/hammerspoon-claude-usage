# hammerspoon-claude-usage

macOS에서 Claude 사용량을 실시간으로 모니터링하는 Hammerspoon 위젯

## 스크린샷

```
┌─────────────┐ ┌─────────────┐
│   current   │ │   weekly    │
│ 92% (3h19m) │ │ 41% (4h19m) │
└─────────────┘ └─────────────┘
```

## 특징

- 10초마다 자동 갱신
- Safari 백그라운드 탭에서 동작 (다른 작업 방해 없음)
- Safari가 꺼져있으면 자동으로 실행 및 페이지 열기
- 남은 사용량(%) 표시로 직관적 확인
- 로딩/에러 상태 구분 표시

## 요구 사항

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- Safari
- Claude Pro 계정 (claude.ai 로그인 필요)

## 설치

### 1. Safari 설정

1. Safari 실행
2. 메뉴바 → Safari → 설정 (또는 `Cmd + ,`)
3. **Developer** 탭 선택
4. **Allow JavaScript from Apple Events** 체크

> Developer 탭이 안 보이면: 설정 → Advanced → "Show features for web developers" 체크

### 2. 파일 복사

```bash
# 레포 클론
git clone https://github.com/dunchi/hammerspoon-claude-usage.git
cd hammerspoon-claude-usage

# Hammerspoon 스크립트
cp claude-usage.lua ~/.hammerspoon/

# 데이터 추출 스크립트
mkdir -p ~/.local/bin
cp claude-usage.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-usage.sh

# LaunchAgent (10초마다 자동 실행)
cp com.user.claude-usage.plist ~/Library/LaunchAgents/
```

### 3. init.lua에 추가

`~/.hammerspoon/init.lua` 파일에 다음 추가:

```lua
local claudeUsage = require("claude-usage")
claudeUsage.start()
```

### 4. 서비스 시작

```bash
# LaunchAgent 로드
launchctl load ~/Library/LaunchAgents/com.user.claude-usage.plist
```

Hammerspoon 메뉴바 아이콘 → **Reload Config** 클릭

### 5. Safari에서 Claude 로그인

Safari에서 https://claude.ai 에 로그인해두면 끝.
(usage 페이지는 자동으로 열림)

## 표시 정보

| 위젯 | 설명 |
|------|------|
| **current** | 현재 세션 남은 사용량 (%), 리셋까지 남은 시간 |
| **weekly** | 주간 남은 사용량 (%), 리셋까지 남은 시간 |

### 상태 표시

| 색상 | 상태 |
|------|------|
| 녹색 | 정상 |
| 주황색 | 로딩 중 (Safari 자동 실행 중 등) |
| 빨간색 | 에러 |

## 제거

```bash
launchctl unload ~/Library/LaunchAgents/com.user.claude-usage.plist
rm ~/Library/LaunchAgents/com.user.claude-usage.plist
rm ~/.local/bin/claude-usage.sh
rm ~/.hammerspoon/claude-usage.lua
rm ~/.claude-usage.json
```

`~/.hammerspoon/init.lua`에서 추가한 코드도 삭제

## 문제 해결

### "error" 표시될 때
- Safari에서 claude.ai에 로그인되어 있는지 확인
- Safari 설정에서 "Allow JavaScript from Apple Events" 체크 확인

### 위젯이 안 보일 때
- Hammerspoon이 실행 중인지 확인
- Hammerspoon 메뉴바 → Reload Config 시도
