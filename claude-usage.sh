#!/bin/bash

# Claude Usage Fetcher
# Safari에서 claude.ai/settings/usage 데이터를 추출하여 JSON으로 저장

OUTPUT_FILE="$HOME/.claude-usage.json"

# Safari가 실행 중인지 확인
if ! pgrep -x "Safari" > /dev/null; then
    echo '{"error": "Safari not running"}' > "$OUTPUT_FILE"
    exit 1
fi

# Safari에서 JavaScript로 데이터 추출
DATA=$(osascript <<'APPLESCRIPT'
tell application "Safari"
    try
        set currentURL to URL of current tab of front window
        if currentURL does not contain "claude.ai/settings/usage" then
            return "{\"error\": \"Wrong page\"}"
        end if

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
" in current tab of front window

        return jsResult
    on error errMsg
        return "{\"error\": \"" & errMsg & "\"}"
    end try
end tell
APPLESCRIPT
)

# 결과 저장
echo "$DATA" > "$OUTPUT_FILE"
