# Claude Usage Widget 설치 가이드 (for LLM)

이 문서는 완전히 새로운 macOS 환경에서 Claude Usage Widget을 설치하기 위한 단계별 가이드입니다.
AI/LLM이 이 문서를 읽고 사용자의 컴퓨터에 설치를 도울 수 있도록 작성되었습니다.

## 전제 조건

- macOS (Ventura 13.0 이상 권장)
- 관리자 권한
- 인터넷 연결
- Claude Pro 계정

## 설치 순서

### Step 1: Homebrew 설치

macOS 패키지 관리자인 Homebrew가 필요합니다.

```bash
# Homebrew 설치 확인
which brew

# 설치되어 있지 않으면 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Apple Silicon Mac (M1/M2/M3)의 경우 설치 후 PATH 설정:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Step 2: Git 설치

```bash
# Git 설치 확인
git --version

# 설치되어 있지 않으면 설치
brew install git
```

### Step 3: Hammerspoon 설치

```bash
brew install --cask hammerspoon
```

### Step 4: Hammerspoon 실행 및 접근성 권한 부여

1. Hammerspoon 앱 실행 (Applications 폴더 또는 Spotlight에서 검색)
2. 메뉴바에 Hammerspoon 아이콘이 나타남
3. 시스템이 접근성 권한을 요청하면 허용:
   - System Settings → Privacy & Security → Accessibility
   - Hammerspoon 체크 활성화

**중요**: 접근성 권한이 없으면 위젯이 동작하지 않습니다.

### Step 5: Safari 개발자 모드 활성화

Safari에서 JavaScript 실행을 허용해야 합니다.

1. Safari 실행
2. 메뉴바 → Safari → Settings (또는 `Cmd + ,`)
3. **Advanced** 탭 선택
4. 하단의 **"Show features for web developers"** 체크
5. **Developer** 탭이 새로 나타남
6. **Developer** 탭 선택
7. **"Allow JavaScript from Apple Events"** 체크

### Step 6: 레포 클론 및 파일 복사

```bash
# 작업 디렉토리 생성 (선택사항)
mkdir -p ~/Projects
cd ~/Projects

# 레포 클론
git clone https://github.com/dunchi/hammerspoon-claude-usage.git
cd hammerspoon-claude-usage

# Hammerspoon 설정 디렉토리 생성 (없으면)
mkdir -p ~/.hammerspoon

# Hammerspoon 스크립트 복사
cp claude-usage.lua ~/.hammerspoon/

# 데이터 추출 스크립트 복사
mkdir -p ~/.local/bin
cp claude-usage.sh ~/.local/bin/
chmod +x ~/.local/bin/claude-usage.sh

# LaunchAgent 복사
cp com.user.claude-usage.plist ~/Library/LaunchAgents/
```

### Step 7: Hammerspoon init.lua 설정

`~/.hammerspoon/init.lua` 파일을 생성하거나 편집:

```bash
# init.lua가 없으면 생성
touch ~/.hammerspoon/init.lua
```

`~/.hammerspoon/init.lua`에 다음 내용 추가:

```lua
local claudeUsage = require("claude-usage")
claudeUsage.start()
```

**주의**: 기존에 init.lua가 있다면 기존 내용을 유지하고 위 코드를 추가합니다.

### Step 8: LaunchAgent 로드

```bash
launchctl load ~/Library/LaunchAgents/com.user.claude-usage.plist
```

### Step 9: Hammerspoon 설정 리로드

1. 메뉴바의 Hammerspoon 아이콘 클릭
2. **Reload Config** 클릭

또는 Hammerspoon 콘솔에서:

```lua
hs.reload()
```

### Step 10: Safari에서 Claude 로그인

1. Safari 실행
2. https://claude.ai 접속
3. Claude 계정으로 로그인
4. 로그인 상태 유지 (Safari가 세션을 기억함)

## 설치 확인

1. 화면 오른쪽 하단에 두 개의 위젯이 표시되어야 함:
   - `current`: 현재 세션 남은 사용량
   - `weekly`: 주간 남은 사용량

2. 처음에는 `loading...` (주황색)이 표시될 수 있음
   - Safari가 자동으로 usage 페이지를 열고 데이터를 가져오는 중
   - 약 10-30초 후 정상 데이터 표시

3. 정상 동작 시 녹색으로 `XX% (XhXXm)` 형식 표시

## 문제 해결

### 위젯이 안 보이는 경우

```bash
# Hammerspoon이 실행 중인지 확인
pgrep -x Hammerspoon

# 실행 중이 아니면 실행
open -a Hammerspoon
```

### "error" (빨간색) 표시되는 경우

1. Safari에서 claude.ai 로그인 상태 확인
2. Safari 설정에서 "Allow JavaScript from Apple Events" 체크 확인
3. 수동으로 스크립트 실행하여 에러 확인:

```bash
~/.local/bin/claude-usage.sh
cat ~/.claude-usage.json
```

### "loading..." 상태가 계속되는 경우

1. Safari가 실행되었는지 확인
2. Safari에 claude.ai/settings/usage 탭이 열렸는지 확인
3. Claude 로그인 상태 확인

### LaunchAgent가 동작하지 않는 경우

```bash
# LaunchAgent 상태 확인
launchctl list | grep claude-usage

# 다시 로드
launchctl unload ~/Library/LaunchAgents/com.user.claude-usage.plist
launchctl load ~/Library/LaunchAgents/com.user.claude-usage.plist
```

## 파일 구조

```
~/.hammerspoon/
├── init.lua              # Hammerspoon 메인 설정
└── claude-usage.lua      # Claude 위젯 스크립트

~/.local/bin/
└── claude-usage.sh       # Safari 데이터 추출 스크립트

~/Library/LaunchAgents/
└── com.user.claude-usage.plist  # 10초마다 자동 실행

~/.claude-usage.json      # 추출된 사용량 데이터 (자동 생성)
```

## 완전 제거

```bash
# LaunchAgent 중지 및 제거
launchctl unload ~/Library/LaunchAgents/com.user.claude-usage.plist
rm ~/Library/LaunchAgents/com.user.claude-usage.plist

# 스크립트 제거
rm ~/.local/bin/claude-usage.sh
rm ~/.hammerspoon/claude-usage.lua

# 데이터 파일 제거
rm ~/.claude-usage.json
```

`~/.hammerspoon/init.lua`에서 추가한 코드도 제거:

```lua
-- 아래 두 줄 삭제
local claudeUsage = require("claude-usage")
claudeUsage.start()
```

Hammerspoon 메뉴바 → Reload Config
