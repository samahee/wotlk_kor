local Original_ChatFrame_OnEvent
local CopyCat_SetItemRef_Original

function CopyCat_OnLoad()
    Original_ChatFrame_OnEvent = ChatFrame_OnEvent
    ChatFrame_OnEvent = CopyCat_ChatFrame_OnEvent
    CopyCat_SetItemRef_Original = SetItemRef
    SetItemRef = CopyCat_SetItemRef
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("CopyCat loaded")
    end
end

function CopyCat_ChatFrame_OnEvent(self, event, ...)
    Original_ChatFrame_OnEvent(self, event, ...)
    if not self.Original_AddMessage then
        self.Original_AddMessage = self.AddMessage
        self.AddMessage = CopyCat_AddMessage
    end
end

-- 메시지 앞의 [채널] [작성자]: 제거 함수
local function RemovePrefix(linkedMsg)
    local msg = linkedMsg
    local changed = true
    while changed do
        changed = false
        local before = msg

        -- 색상코드 제거
        msg = msg:gsub("^|c%x%x%x%x%x%x%x%x", "")
        msg = msg:gsub("^|r", "")

        -- 링크로 감싼 채널/작성자 제거
        msg = msg:gsub("^|H.-|h%[[^%]]+%]|h%s*|H.-|h%[[^%]]+%]|h:%s*", "")
        msg = msg:gsub("^|H.-|h%[[^%]]+%]|h%s*|H.-|h[^:]-:%s*", "")

        if msg ~= before then
            changed = true
        end
    end

    -- 일반 텍스트 패턴 제거
    msg = msg:gsub("^%[%d+%.%s*[^%]]+%]%s*%[[^%]]+%]:%s*", "")
    msg = msg:gsub("^%[[^%]]+%]%s*%[[^%]]+%]:%s*", "")

    return msg
end

function CopyCat_AddMessage(self, msg, r, g, b, id)
    -- 링크용 텍스트만 앞부분 제거
    local linkText = UnlinkMessage(RemovePrefix(msg))

    -- 타임스탬프 대신 [*] 고정
    local timestamp = "[*]"
    local clickable = "|Hezc:" .. linkText .. "|h" .. timestamp .. "|h "

    -- 채팅창에는 원본 메시지 그대로 출력
    local newmsg = clickable .. msg
    self:Original_AddMessage(newmsg, r, g, b, id)
end

function UnlinkMessage(linkedmessage)
    local message = linkedmessage
    local part1, part2, part3, pos

    if strfind(message, "|c") then
        message = gsub(message, "|r", "")
        while strfind(message, "|c") do
            pos = strfind(message, "|c")
            part1 = strsub(message, 1, pos - 1)
            part2 = strsub(message, pos + 10)
            message = part1 .. part2
        end
    end

    if strfind(message, "|H") then
        while strfind(message, "|H") do
            pos = strfind(message, "|H")
            part1 = strsub(message, 1, pos - 1)
            part2 = strsub(message, pos + 2)
            pos = strfind(part2, "|h")
            part2 = strsub(part2, pos + 2)
            pos = strfind(part2, "|h")
            part3 = strsub(part2, pos + 2)
            part2 = strsub(part2, 1, pos - 1)
            message = part1 .. part2 .. part3
        end
    end

    message = gsub(message, "/", "/1")
    message = gsub(message, "|", "/2")
    return message
end

function CopyCat_SetItemRef(link, text, button, chatFrame)
    if strsub(link, 1, 3) == "ezc" then
        CopyCat_core:Show()
        CopyCatText:SetText(gsub(gsub(strsub(link, 5), "/2", "|"), "/1", "/"))
        CopyCatText:HighlightText()
        CopyCatText:SetFont(DEFAULT_CHAT_FRAME:GetFont())
        return
    end
    CopyCat_SetItemRef_Original(link, text, button, chatFrame)
end