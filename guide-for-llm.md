# Claude Usage Widget 설치 가이드 (for LLM)

이 문서는 완전히 새로운 macOS 환경에서 Claude Usage Widget을 설치하기 위한 단계별 가이드입니다.
AI/LLM이 이 문서를 읽고 사용자의 컴퓨터에 설치를 도울 수 있도록 작성되었습니다.

## 전제 조건

- macOS (Ventura 13.0 이상 권장)
- 관리자 권한
- 인터넷 연결
- Claude Max 구독 (Claude Code CLI 사용)

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

### Step 2: Git 및 tmux 설치

```bash
# Git 설치 확인
git --version

# 설치되어 있지 않으면 설치
brew install git

# tmux 설치
brew install tmux
```

### Step 3: Claude Code CLI 설치

Claude Code CLI가 필요합니다. 공식 설치 방법을 따르세요:

```bash
# Claude Code CLI 설치 확인
which claude

# 설치되어 있지 않으면 공식 가이드 참고
# https://docs.anthropic.com/en/docs/claude-code
```

Claude Code CLI 설치 후 인증을 완료해야 합니다.

### Step 4: Hammerspoon 설치

```bash
brew install --cask hammerspoon
```

### Step 5: Hammerspoon 실행 및 접근성 권한 부여

1. Hammerspoon 앱 실행 (Applications 폴더 또는 Spotlight에서 검색)
2. 메뉴바에 Hammerspoon 아이콘이 나타남
3. 시스템이 접근성 권한을 요청하면 허용:
   - System Settings → Privacy & Security → Accessibility
   - Hammerspoon 체크 활성화

**중요**: 접근성 권한이 없으면 위젯이 동작하지 않습니다.

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

# 중요: 스크립트 내 사용자명 수정
# 아래 명령어로 자신의 사용자명으로 변경
sed -i '' "s|/Users/hanju|$HOME|g" ~/.local/bin/claude-usage.sh
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

### Step 8: Hammerspoon 설정 리로드

1. 메뉴바의 Hammerspoon 아이콘 클릭
2. **Reload Config** 클릭

또는 Hammerspoon 콘솔에서:

```lua
hs.reload()
```

## 설치 확인

1. 화면 오른쪽 하단에 두 개의 위젯이 표시되어야 함:
   - `current`: 현재 세션 남은 사용량 (%)
   - `weekly`: 주간 남은 사용량 (%)

2. 처음에는 `loading...` (주황색)이 표시됨
   - tmux 세션이 생성되고 Claude CLI가 시작되는 중
   - 약 10-30초 후 정상 데이터 표시

3. 정상 동작 시 녹색으로 `XX% (XhXXm)` 형식 표시
   - current: `88% (3h 49m)` - 세션 남은 %, 리셋까지 시간
   - weekly: `99% (6d 23h)` - 주간 남은 %, 리셋까지 시간

## 동작 방식

1. Hammerspoon이 30초마다 `claude-usage.sh` 스크립트 실행
2. 스크립트가 tmux 세션(`claude-usage`)에서 Claude CLI `/usage` 명령 실행
3. 결과를 `~/.claude-usage.json`에 저장
4. Hammerspoon 위젯이 10초마다 JSON 읽어서 화면 표시
5. Hammerspoon 종료 시 데이터 수집도 중지

## 문제 해결

### 위젯이 안 보이는 경우

```bash
# Hammerspoon이 실행 중인지 확인
pgrep -x Hammerspoon

# 실행 중이 아니면 실행
open -a Hammerspoon
```

### "error" (빨간색) 표시되는 경우

1. Claude Code CLI 설치 및 인증 확인:
   ```bash
   which claude
   claude --version
   ```

2. tmux 설치 확인:
   ```bash
   which tmux
   ```

3. 수동으로 스크립트 실행하여 에러 확인:
   ```bash
   ~/.local/bin/claude-usage.sh
   cat ~/.claude-usage.json
   ```

### "loading..." 상태가 계속되는 경우

1. tmux 세션 확인:
   ```bash
   tmux list-sessions
   ```

2. tmux 세션에 접속하여 상태 확인:
   ```bash
   tmux attach -t claude-usage
   ```

3. Claude CLI가 정상 실행 중인지 확인

### tmux 세션이 생성되지 않는 경우

```bash
# 스크립트 PATH 확인
head -10 ~/.local/bin/claude-usage.sh
```

스크립트 상단에 PATH 설정이 있어야 함. **자신의 사용자명으로 수정 필요**:
```bash
export PATH="/opt/homebrew/bin:/Users/YOUR_USERNAME/.local/bin:$PATH"
```

예: 사용자명이 `john`이면:
```bash
export PATH="/opt/homebrew/bin:/Users/john/.local/bin:$PATH"
```

## 파일 구조

```
~/.hammerspoon/
├── init.lua              # Hammerspoon 메인 설정
└── claude-usage.lua      # Claude 위젯 + 데이터 수집 (30초마다)

~/.local/bin/
└── claude-usage.sh       # tmux/Claude CLI 데이터 추출 스크립트

~/.claude-usage.json      # 추출된 사용량 데이터 (자동 생성)
```

## 완전 제거

```bash
# tmux 세션 종료
tmux kill-session -t claude-usage 2>/dev/null

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
