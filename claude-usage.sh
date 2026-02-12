#!/bin/bash

# Claude Usage Fetcher
# Safari에서 claude.ai/settings/usage 데이터를 추출하여 JSON으로 저장

OUTPUT_FILE="$HOME/.claude-usage.json"
TARGET_URL="https://claude.ai/settings/usage"

# Safari에서 데이터 추출 (백그라운드 탭 지원, 자동 열기)
DATA=$(osascript <<'APPLESCRIPT'
tell application "Safari"
    set targetURL to "claude.ai/settings/usage"
    set foundTab to missing value
    set foundWindow to missing value

    -- 모든 윈도우의 모든 탭에서 usage 페이지 찾기
    repeat with w in windows
        repeat with t in tabs of w
            if URL of t contains targetURL then
                set foundTab to t
                set foundWindow to w
                exit repeat
            end if
        end repeat
        if foundTab is not missing value then exit repeat
    end repeat

    -- 페이지를 찾지 못하면 새 탭에서 열기
    if foundTab is missing value then
        -- Safari가 열려있지 않으면 실행
        if not running then
            activate
            delay 1
        end if

        -- 새 탭에서 usage 페이지 열기
        if (count of windows) = 0 then
            make new document with properties {URL:"https://claude.ai/settings/usage"}
            delay 3
        else
            tell front window
                set newTab to make new tab with properties {URL:"https://claude.ai/settings/usage"}
                delay 3
            end tell
        end if

        return "{\"error\": \"Opening page, wait...\"}"
    end if

    -- 찾은 탭에서 JavaScript 실행
    try
        set jsResult to do JavaScript "
(function() {
    var data = {};
    var text = document.body.innerText;

    var sessionMatch = text.match(/Current session[\\s\\S]*?(\\d+)% used/);
    if (sessionMatch) data.sessionPercent = parseInt(sessionMatch[1]);

    var allModelsMatch = text.match(/All models[\\s\\S]*?(\\d+)% used/);
    if (allModelsMatch) data.weeklyPercent = parseInt(allModelsMatch[1]);

    var resetSession = text.match(/Current session[\\s\\S]*?Resets in ([0-9]+ hr [0-9]+ min|[0-9]+ hr|[0-9]+ min)/);
    if (resetSession) data.sessionReset = resetSession[1];

    var resetAllModels = text.match(/All models[\\s\\S]*?Resets in ([0-9]+ hr [0-9]+ min|[0-9]+ hr|[0-9]+ min)/);
    if (resetAllModels) data.weeklyReset = resetAllModels[1];

    data.timestamp = new Date().toISOString();
    return JSON.stringify(data);
})();
" in foundTab

        return jsResult
    on error errMsg
        return "{\"error\": \"" & errMsg & "\"}"
    end try
end tell
APPLESCRIPT
)

# 결과 저장
echo "$DATA" > "$OUTPUT_FILE"
