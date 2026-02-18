-- Claude Usage Widget
-- ~/.claude-usage.json 파일을 읽어서 화면에 표시
-- 2개 위젯: current (왼쪽), weekly (오른쪽)

local M = {}

local canvasCurrent = nil
local canvasWeekly = nil
local updateTimer = nil
local fetchTimer = nil
local wakeWatcher = nil
local JSON_PATH = os.getenv("HOME") .. "/.claude-usage.json"
local SCRIPT_PATH = os.getenv("HOME") .. "/.local/bin/claude-usage.sh"
local SESSION_NAME = "claude-usage"

-- 사용량 데이터 가져오기 (sh 스크립트 실행)
local function fetchUsage()
    hs.task.new(SCRIPT_PATH, nil):start()
end

-- tmux 세션 강제 재시작
local function restartSession()
    -- tmux 세션 종료
    hs.execute("/opt/homebrew/bin/tmux kill-session -t " .. SESSION_NAME .. " 2>/dev/null", true)
    -- 에러 카운트 리셋
    hs.execute("echo 0 > " .. os.getenv("HOME") .. "/.claude-usage-error-count", true)
    -- JSON 삭제 (loading 상태로 전환)
    os.remove(JSON_PATH)
    -- 새 세션 시작
    fetchUsage()
end

-- macOS wake 이벤트 핸들러
local function handleWakeEvent(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        hs.timer.doAfter(2, function()
            restartSession()
        end)
    end
end

-- JSON 파일 읽기
local function readJSON()
    local file = io.open(JSON_PATH, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()

    local ok, data = pcall(hs.json.decode, content)
    if ok and data then
        return data
    end
    return nil
end

-- 단일 위젯 생성
local function createSingleWidget(x, y, width, height, label)
    local canvas = hs.canvas.new({x = x, y = y, w = width, h = height})

    -- 배경 (finger-gym과 동일)
    canvas[1] = {
        type = "rectangle",
        fillColor = {red = 0.1, green = 0.1, blue = 0.1, alpha = 0.7},
    }

    -- 라벨 (상단, 작은 글씨)
    canvas[2] = {
        type = "text",
        text = label,
        textFont = "Menlo",
        textSize = 12,
        textColor = {red = 0.3, green = 0.9, blue = 0.4, alpha = 1},
        textAlignment = "center",
        frame = {x = 0, y = 5, w = width, h = 16}
    }

    -- 값 (하단)
    canvas[3] = {
        type = "text",
        text = "--% (--)",
        textFont = "Menlo",
        textSize = 16,
        textColor = {red = 0.3, green = 0.9, blue = 0.4, alpha = 1},
        textAlignment = "center",
        frame = {x = 0, y = 24, w = width, h = 24}
    }

    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    return canvas
end

-- 위젯 생성
local function createWidgets()
    local screen = hs.screen.primaryScreen()
    local frame = screen:frame()

    local width = 150
    local height = 50
    local padding = 20
    local gap = 10

    local y = frame.y + frame.h - height - padding

    -- weekly: 오른쪽 하단
    local weeklyX = frame.x + frame.w - width - padding
    canvasWeekly = createSingleWidget(weeklyX, y, width, height, "weekly")

    -- current: weekly 왼쪽
    local currentX = weeklyX - width - gap
    canvasCurrent = createSingleWidget(currentX, y, width, height, "current")

    return canvasCurrent, canvasWeekly
end

-- 색상
local colorNormal = {red = 0.3, green = 0.9, blue = 0.4, alpha = 1}
local colorLoading = {red = 1.0, green = 0.6, blue = 0.0, alpha = 1}
local colorError = {red = 0.9, green = 0.3, blue = 0.3, alpha = 1}

-- 위젯 업데이트
local function updateWidget()
    if not canvasCurrent or not canvasWeekly then return end

    local data = readJSON()

    if data and not data.error and data.sessionPercent and data.weeklyPercent then
        local sp = data.sessionPercent
        local wp = data.weeklyPercent
        local sr = data.sessionReset or "--"
        local wr = data.weeklyReset or "--"

        -- 남은 퍼센트 계산
        local remainSession = 100 - sp
        local remainWeekly = 100 - wp

        -- 시간은 이미 "3hr 19min" 형식으로 전달됨

        canvasCurrent[3].text = string.format("%d%% (%s)", remainSession, sr)
        canvasCurrent[3].textColor = colorNormal

        canvasWeekly[3].text = string.format("%d%% (%s)", remainWeekly, wr)
        canvasWeekly[3].textColor = colorNormal
    else
        -- 로딩 vs 에러 구분
        local errMsg = "loading..."
        local errColor = colorLoading

        if data and data.error then
            if data.error:find("Session starting") or data.error:find("wait") then
                errMsg = "loading..."
                errColor = colorLoading
            else
                -- 실제 에러
                errMsg = "error"
                errColor = colorError
            end
        elseif data and not data.sessionPercent then
            -- 데이터 불완전 (로딩 중)
            errMsg = "loading..."
            errColor = colorLoading
        elseif not data then
            -- JSON 파일 없음 (초기 로딩)
            errMsg = "loading..."
            errColor = colorLoading
        end

        canvasCurrent[3].text = errMsg
        canvasCurrent[3].textColor = errColor

        canvasWeekly[3].text = errMsg
        canvasWeekly[3].textColor = errColor
    end
end

-- 시작
function M.start()
    if canvasCurrent then
        canvasCurrent:delete()
    end
    if canvasWeekly then
        canvasWeekly:delete()
    end

    -- 기존 tmux 세션 종료 후 새로 시작
    restartSession()

    createWidgets()
    canvasCurrent:show()
    canvasWeekly:show()

    updateWidget()

    if updateTimer then
        updateTimer:stop()
    end
    updateTimer = hs.timer.doEvery(10, updateWidget)

    -- 데이터 수집 타이머 (30초마다)
    if fetchTimer then
        fetchTimer:stop()
    end
    -- restartSession()에서 이미 fetchUsage() 호출됨
    fetchTimer = hs.timer.doEvery(30, fetchUsage)

    -- wake 이벤트 감지
    if wakeWatcher then
        wakeWatcher:stop()
    end
    wakeWatcher = hs.caffeinate.watcher.new(handleWakeEvent)
    wakeWatcher:start()
end

-- 중지
function M.stop()
    if updateTimer then
        updateTimer:stop()
        updateTimer = nil
    end
    if fetchTimer then
        fetchTimer:stop()
        fetchTimer = nil
    end
    if wakeWatcher then
        wakeWatcher:stop()
        wakeWatcher = nil
    end
    if canvasCurrent then
        canvasCurrent:hide()
    end
    if canvasWeekly then
        canvasWeekly:hide()
    end
end

-- 토글
function M.toggle()
    if canvasCurrent and canvasCurrent:isShowing() then
        M.stop()
    else
        M.start()
    end
end

return M
