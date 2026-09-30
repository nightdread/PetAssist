--[[
  PetAssist 1.4.0 — Classic Era

  PetAttack() is forbidden from addon code. Keybinds are overridden to secure
  proxy buttons whose macrotext is:

    /petattack [pet,@target,harm,nodead]   (damage / DoTs)
    /petpassive + /petfollow               (SoftCC: Fear, Banish, …)
    /cast|/use|macro body
    /petattack + /startattack              (Attack button only)

  Mouse / Dominos / Bartender / ElvUI: PreClick → secure helper click.
  Do not put /startattack on ranged spells — it spam "You are too far away".
]]

local ADDON_NAME = ...
local VERSION = "@project-version@"
-- Unpackaged working copy (placeholder not replaced by packager)
if VERSION:find("@", 1, true) then
  VERSION = "1.4.0-dev"
end

local MODE_ALL = "all"
local MODE_HARM = "harm"
local MODE_CUSTOM = "custom"

-- pa_allow on buttons: 0 = none, 1 = petattack, 2 = SoftCC (passive+follow)
local PA_NONE = 0
local PA_ASSIST = 1
local PA_SOFTCC = 2

local defaults = {
  enabled = true,
  mode = MODE_HARM, -- all | harm | custom
  softCC = true,    -- on Fear/Banish/… pull pet back (passive+follow)
  blacklist = {},   -- [lowerSpellName] = true (custom mode)
  recallKey = nil,  -- e.g. "SHIFT-F"
}

-- Classic Era: CC / utility that should not send the pet (localized via GetSpellInfo).
local BLOCK_SPELL_IDS = {
  -- Warlock CC / utility
  5782, 6213, 6215,           -- Fear
  710, 18647,                 -- Banish
  5484, 17928,                -- Howl of Terror
  6789, 17925, 17926,         -- Death Coil
  1098, 11725, 11726,         -- Enslave Demon
  6358,                       -- Seduction (if on action bar)
  126,                        -- Eye of Kilrogg
  1122,                       -- Inferno
  698,                        -- Ritual of Summoning
  18540,                      -- Ritual of Doom
  1454, 1455, 1456, 11687, 11688, 11689, -- Life Tap
  18220, 18937, 18938,        -- Dark Pact
  755, 3698, 3699, 3700, 11693, 11694, 11695, -- Health Funnel
  6229, 11739, 11740, 28610,  -- Shadow Ward
  687, 696,                   -- Demon Skin
  706, 1086, 11733, 11734, 11735, -- Demon Armor
  5500,                       -- Sense Demons
  132, 6512, 11743,           -- Detect Invisibility ranks
  5697,                       -- Unending Breath
  18708,                      -- Fel Domination
  19028,                      -- Soul Link
  18288,                      -- Amplify Curse
  6201, 6202, 5699, 11729, 11730, -- Create Healthstone
  693, 20752, 20755, 20756, 20757, -- Create Soulstone
  6366, 17951, 17952, 17953,  -- Create Firestone
  2362, 17727, 17728,         -- Create Spellstone
  -- Hunter CC / utility
  5384,                       -- Feign Death
  1002,                       -- Eyes of the Beast
  6197,                       -- Eagle Eye
  1513, 14326, 14327,         -- Scare Beast
  1499, 14310, 14311,         -- Freezing Trap
  13809,                      -- Frost Trap
  19386, 24132, 24133,        -- Wyvern Sting
  19503,                      -- Scatter Shot
  20736,                      -- Distracting Shot
  1543,                       -- Flare
  1515,                       -- Tame Beast
  1462,                       -- Beast Lore
  883,                        -- Call Pet
  2641,                       -- Dismiss Pet
  982,                        -- Revive Pet
  6991,                       -- Feed Pet
  136, 3111, 3661, 3662, 13542, 13543, 13544, -- Mend Pet
}

-- Spells where the pet must STOP (SoftCC Guard): passive + follow with the cast.
local SOFTCC_SPELL_IDS = {
  5782, 6213, 6215,           -- Fear
  710, 18647,                 -- Banish
  5484, 17928,                -- Howl of Terror
  6789, 17925, 17926,         -- Death Coil
  1098, 11725, 11726,         -- Enslave Demon
  6358,                       -- Seduction
  1513, 14326, 14327,         -- Scare Beast
  1499, 14310, 14311,         -- Freezing Trap
  13809,                      -- Frost Trap
  19386, 24132, 24133,        -- Wyvern Sting
  19503,                      -- Scatter Shot
}

local BARS = {
  { bind = "ACTIONBUTTON",          btn = "ActionButton",              firstSlot = 1 },
  { bind = "MULTIACTIONBAR1BUTTON", btn = "MultiBarBottomLeftButton",  firstSlot = 61 },
  { bind = "MULTIACTIONBAR2BUTTON", btn = "MultiBarBottomRightButton", firstSlot = 49 },
  { bind = "MULTIACTIONBAR3BUTTON", btn = "MultiBarRightButton",       firstSlot = 25 },
  { bind = "MULTIACTIONBAR4BUTTON", btn = "MultiBarLeftButton",        firstSlot = 37 },
}

-- Extra action buttons (keybinds usually CLICK the button → PreClick is enough)
local EXTRA_BUTTON_FORMATS = {
  "DominosActionButton%d",
  "BT4Button%d",
}
for bar = 1, 10 do
  EXTRA_BUTTON_FORMATS[#EXTRA_BUTTON_FORMATS + 1] = "ElvUI_Bar" .. bar .. "Button%d"
end

local binder = CreateFrame("Frame", "PetAssistBinder", UIParent, "SecureHandlerBaseTemplate")
local header = CreateFrame("Frame", "PetAssistHeader", UIParent, "SecureHandlerBaseTemplate")

local PET = "/petattack [pet,@target,harm,nodead]"
local SOFTCC = "/petpassive\n/petfollow"

local petOnly = CreateFrame("Button", "PetAssistPetOnly", UIParent, "SecureActionButtonTemplate")
petOnly:RegisterForClicks("AnyUp", "AnyDown")
petOnly:SetAttribute("type", "macro")
petOnly:SetAttribute("*type*", "macro")
petOnly:SetAttribute("macrotext", PET)
petOnly:SetAttribute("*macrotext*", PET)
petOnly:Hide()
header:SetFrameRef("petOnly", petOnly)

local softCcBtn = CreateFrame("Button", "PetAssistSoftCC", UIParent, "SecureActionButtonTemplate")
softCcBtn:RegisterForClicks("AnyUp", "AnyDown")
softCcBtn:SetAttribute("type", "macro")
softCcBtn:SetAttribute("*type*", "macro")
softCcBtn:SetAttribute("macrotext", SOFTCC)
softCcBtn:SetAttribute("*macrotext*", SOFTCC)
softCcBtn:Hide()
header:SetFrameRef("softCc", softCcBtn)

local recallBtn = CreateFrame("Button", "PetAssistRecall", UIParent, "SecureActionButtonTemplate")
recallBtn:RegisterForClicks("AnyUp", "AnyDown")
recallBtn:SetAttribute("type", "macro")
recallBtn:SetAttribute("*type*", "macro")
recallBtn:SetAttribute("macrotext", SOFTCC)
recallBtn:SetAttribute("*macrotext*", SOFTCC)
recallBtn:Hide()

local proxies = {}
local wrapped = {}
local blockedNames = {}
local softCcNames = {}
local pendingRefresh = false
local optionsFrame
local settingsCategory -- Settings API category (Classic Era Options → AddOns)

-- PreClick: pa_allow 1 = petattack, 2 = SoftCC (passive+follow)
local PRECLICK_PET = [[
  if not control:GetAttribute("pa_enabled") then
    return
  end
  local allow = self:GetAttribute("pa_allow")
  if allow ~= 1 and allow ~= 2 then
    return
  end
  local wantDown = control:GetAttribute("pa_keydown")
  if wantDown == 1 then
    if not down then return end
  else
    if down then return end
  end
  if allow == 1 then
    local pet = control:GetFrameRef("petOnly")
    if pet then
      pet:Click(button, down)
    end
  elseif allow == 2 then
    local soft = control:GetFrameRef("softCc")
    if soft then
      soft:Click(button, down)
    end
  end
]]

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff9966ffPetAssist|r: " .. msg)
end

local function DB()
  if not PetAssistDB then
    PetAssistDB = {}
  end
  for k, v in pairs(defaults) do
    if PetAssistDB[k] == nil then
      if type(v) == "table" then
        PetAssistDB[k] = {}
      else
        PetAssistDB[k] = v
      end
    end
  end
  if type(PetAssistDB.blacklist) ~= "table" then
    PetAssistDB.blacklist = {}
  end
  if PetAssistDB.mode ~= MODE_ALL and PetAssistDB.mode ~= MODE_HARM and PetAssistDB.mode ~= MODE_CUSTOM then
    PetAssistDB.mode = MODE_HARM
  end
  return PetAssistDB
end

local function SpellName(spellId)
  if not spellId then
    return nil
  end
  if GetSpellInfo then
    return GetSpellInfo(spellId)
  end
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(spellId)
  end
  return nil
end

local function RebuildBlockedNames()
  wipe(blockedNames)
  for _, spellId in ipairs(BLOCK_SPELL_IDS) do
    local name = SpellName(spellId)
    if name then
      blockedNames[name] = true
      blockedNames[name:lower()] = true
    end
  end
  wipe(softCcNames)
  for _, spellId in ipairs(SOFTCC_SPELL_IDS) do
    local name = SpellName(spellId)
    if name then
      softCcNames[name] = true
      softCcNames[name:lower()] = true
    end
  end
end

local function UseKeyDown()
  return GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false
end

local function SyncKeyDownAttr()
  if not InCombatLockdown() then
    header:SetAttribute("pa_keydown", UseKeyDown() and 1 or 0)
  end
end

local function IsAutoAttackSpell(name)
  if not name then
    return false
  end
  if ATTACK and name == ATTACK then
    return true
  end
  local lower = name:lower()
  return lower == "attack" or lower == "атака"
end

local function IsBlockedSpell(spellId, name)
  if spellId and blockedNames[SpellName(spellId) or ""] then
    return true
  end
  if name then
    if blockedNames[name] or blockedNames[name:lower()] then
      return true
    end
  end
  return false
end

local function IsSoftCCSpell(spellId, name)
  if spellId then
    local sn = SpellName(spellId)
    if sn and (softCcNames[sn] or softCcNames[sn:lower()]) then
      return true
    end
  end
  if name and (softCcNames[name] or softCcNames[name:lower()]) then
    return true
  end
  return false
end

local function IsCustomBlacklisted(name)
  if not name then
    return false
  end
  local bl = DB().blacklist
  return bl[name] or bl[name:lower()] or false
end

--- Decide whether this action should send /petattack
-- harm  = всё, кроме встроенного списка CC/utility (DoT/SB/курсы — да; Fear/камни — нет)
-- all   = любая кнопка
-- custom = всё, кроме /pa block
local function ShouldAssist(actionType, id)
  local db = DB()
  local mode = db.mode or MODE_HARM

  if mode == MODE_ALL then
    return true
  end

  if actionType == "spell" then
    local name = SpellName(id)
    if mode == MODE_CUSTOM then
      return not IsCustomBlacklisted(name)
    end
    -- harm: do NOT use IsHarmfulSpell — in Classic Era it often returns
    -- false for DoTs (Corruption, Curse of Agony, Immolate, …).
    return not IsBlockedSpell(id, name)
  end

  if actionType == "item" then
    if mode == MODE_CUSTOM then
      return true
    end
    -- harm: no pet on HS / potions / trinkets
    return false
  end

  if actionType == "macro" then
    if mode == MODE_CUSTOM then
      local mName = GetMacroInfo(id)
      if mName and IsCustomBlacklisted(mName) then
        return false
      end
    end
    return true
  end

  return false
end

--- Returns PA_ASSIST | PA_SOFTCC | PA_NONE (SoftCC wins over assist on Fear etc.)
local function ResolveAction(actionType, id)
  if not actionType then
    return PA_NONE
  end
  if actionType == "spell" then
    local name = SpellName(id)
    if DB().softCC and IsSoftCCSpell(id, name) then
      return PA_SOFTCC
    end
  end
  if ShouldAssist(actionType, id) then
    return PA_ASSIST
  end
  return PA_NONE
end

local function ActionSlotFor(bar, index, realBtn)
  if realBtn then
    if ActionButton_CalculateAction then
      local ok, slot = pcall(ActionButton_CalculateAction, realBtn)
      if ok and slot then
        return slot
      end
    end
    local attr = realBtn:GetAttribute("action")
    if attr then
      return attr
    end
  end
  if bar and bar.firstSlot then
    return bar.firstSlot + index - 1
  end
  return nil
end

local function SlotFromButton(btn)
  if not btn then
    return nil
  end
  if ActionButton_CalculateAction then
    local ok, slot = pcall(ActionButton_CalculateAction, btn)
    if ok and slot then
      return slot
    end
  end
  return btn:GetAttribute("action") or btn.action
end

local function BuildMacroText(slot, action)
  if not slot then
    return nil
  end

  local actionType, id = GetActionInfo(slot)
  if not actionType then
    return nil
  end

  local prefix = ""
  if action == PA_ASSIST then
    prefix = PET .. "\n"
  elseif action == PA_SOFTCC then
    prefix = SOFTCC .. "\n"
  end

  if actionType == "spell" then
    local name = SpellName(id)
    if not name then
      if action == PA_ASSIST then
        return PET
      elseif action == PA_SOFTCC then
        return SOFTCC
      end
      return nil
    end
    if IsAutoAttackSpell(name) then
      if action == PA_ASSIST then
        return PET .. "\n/startattack [@target,harm,nodead]"
      end
      return "/startattack [@target,harm,nodead]"
    end
    if action == PA_NONE then
      return nil -- leave native button
    end
    return prefix .. "/cast " .. name
  elseif actionType == "item" then
    if action == PA_NONE then
      return nil
    end
    return prefix .. "/use item:" .. id
  elseif actionType == "macro" then
    local _, _, body = GetMacroInfo(id)
    if body and body ~= "" then
      local lower = body:lower()
      if lower:find("petattack", 1, true) or lower:find("petpassive", 1, true) then
        return body
      end
      if action == PA_NONE then
        return nil
      end
      local out = prefix .. body
      if #out <= 255 then
        return out
      end
      return (action == PA_SOFTCC) and SOFTCC or PET
    end
  end

  return nil
end

local function SetButtonAction(btn, action)
  if btn and not InCombatLockdown() then
    btn:SetAttribute("pa_allow", action or PA_NONE)
  end
end

local function EnsureProxy(bar, index)
  local key = bar.btn .. index
  local proxy = proxies[key]
  if not proxy then
    proxy = CreateFrame(
      "Button",
      "PetAssistProxy_" .. key,
      UIParent,
      "SecureActionButtonTemplate"
    )
    proxy:RegisterForClicks("AnyUp", "AnyDown")
    proxy:SetAttribute("type", "macro")
    proxy:SetAttribute("*type*", "macro")
    proxy:Hide()
    proxies[key] = proxy
  end
  proxy.paBar = bar
  proxy.paIndex = index
  proxy.paReal = _G[key]
  return proxy
end

local function SetProxyMacro(proxy)
  if not proxy or InCombatLockdown() then
    return nil, PA_NONE
  end
  local slot = ActionSlotFor(proxy.paBar, proxy.paIndex, proxy.paReal)
  local actionType, id = slot and GetActionInfo(slot)
  local action = PA_NONE
  if actionType then
    action = ResolveAction(actionType, id)
  end
  local text = BuildMacroText(slot, action)
  proxy.paSlot = slot
  proxy.paMacro = text
  proxy.paAction = action
  if text then
    proxy:SetAttribute("macrotext", text)
    proxy:SetAttribute("macrotext1", text)
    proxy:SetAttribute("*macrotext*", text)
  end
  SetButtonAction(proxy.paReal, action)
  return text, action
end

local function WrapForMouse(realBtn)
  if not realBtn or wrapped[realBtn] or InCombatLockdown() then
    return
  end
  header:WrapScript(realBtn, "PreClick", PRECLICK_PET)
  wrapped[realBtn] = true
end

local function UnwrapAllMouse()
  if InCombatLockdown() then
    return
  end
  for btn in pairs(wrapped) do
    pcall(function()
      header:UnwrapScript(btn, "PreClick")
    end)
    pcall(function()
      btn:SetAttribute("pa_allow", nil)
    end)
  end
  wipe(wrapped)
end

local function UpdateExtraButton(btn)
  if not btn or InCombatLockdown() then
    return
  end
  local slot = SlotFromButton(btn)
  local action = PA_NONE
  if slot then
    local actionType, id = GetActionInfo(slot)
    if actionType then
      action = ResolveAction(actionType, id)
    end
  end
  SetButtonAction(btn, action)
  WrapForMouse(btn)
end

local function ScanExtraButtons()
  if InCombatLockdown() then
    return 0
  end
  local n = 0
  for _, fmt in ipairs(EXTRA_BUTTON_FORMATS) do
    if _G[string.format(fmt, 1)] then
      for i = 1, 120 do
        local btn = _G[string.format(fmt, i)]
        if btn then
          UpdateExtraButton(btn)
          n = n + 1
        end
      end
    end
  end
  return n
end

local function ApplyRecallBinding()
  if InCombatLockdown() then
    return
  end
  local key = DB().recallKey
  if key and key ~= "" then
    SetOverrideBindingClick(binder, true, key, "PetAssistRecall", "LeftButton")
  end
end

local function Apply()
  if InCombatLockdown() then
    pendingRefresh = true
    return false
  end

  RebuildBlockedNames()
  ClearOverrideBindings(binder)
  local db = DB()
  SyncKeyDownAttr()
  header:SetAttribute("pa_enabled", db.enabled and true or false)

  if not db.enabled then
    UnwrapAllMouse()
    return true, 0, 0, 0
  end

  local proxyCount, keyCount, extraCount = 0, 0, 0

  for _, bar in ipairs(BARS) do
    for i = 1, 12 do
      local realBtn = _G[bar.btn .. i]
      local proxy = EnsureProxy(bar, i)
      local text, action = SetProxyMacro(proxy)
      proxyCount = proxyCount + 1

      if realBtn then
        WrapForMouse(realBtn)
        SetButtonAction(realBtn, action)
      end

      -- Steal key for assist (petattack) or SoftCC (passive+follow)
      if text and (action == PA_ASSIST or action == PA_SOFTCC) then
        local key1, key2 = GetBindingKey(bar.bind .. i)
        if key1 then
          SetOverrideBindingClick(binder, true, key1, proxy:GetName(), "LeftButton")
          keyCount = keyCount + 1
        end
        if key2 then
          SetOverrideBindingClick(binder, true, key2, proxy:GetName(), "LeftButton")
          keyCount = keyCount + 1
        end
      end
    end
  end

  extraCount = ScanExtraButtons()
  ApplyRecallBinding()

  return true, proxyCount, keyCount, extraCount
end

local function Refresh(quiet)
  if InCombatLockdown() then
    pendingRefresh = true
    Print("обновление после боя…")
    return
  end
  pendingRefresh = false
  local ok, proxiesN, keysN, extraN = Apply()
  if ok and DB().enabled and not quiet then
    Print(string.format(
      "v%s готов [%s]: proxy %d, клавиш %d, extra %d.",
      VERSION, DB().mode or MODE_HARM, proxiesN or 0, keysN or 0, extraN or 0
    ))
  end
end

-- ---------------------------------------------------------------------------
-- Options UI (Esc → Options → AddOns → PetAssist)
-- ---------------------------------------------------------------------------

local function ModeLabel(mode)
  if mode == MODE_ALL then
    return "all — пет на КАЖДУЮ кнопку (включая Fear)"
  elseif mode == MODE_CUSTOM then
    return "custom — пет всегда, кроме /pa block"
  end
  return "harm — пет на урон/DoT, НЕ на Fear/камни/баффы"
end

local function RefreshOptionsUI()
  if not optionsFrame then
    return
  end
  local db = DB()
  optionsFrame.enableCheck:SetChecked(db.enabled)
  if optionsFrame.softCcCheck then
    optionsFrame.softCcCheck:SetChecked(db.softCC ~= false)
  end
  optionsFrame.modeText:SetText("Режим: " .. ModeLabel(db.mode))
  if optionsFrame.modeHint then
    if db.mode == MODE_ALL then
      optionsFrame.modeHint:SetText("Пет полетит даже от Life Tap / камней. SoftCC всё равно отзовёт на Fear.")
    elseif db.mode == MODE_CUSTOM then
      optionsFrame.modeHint:SetText("Свой список: /pa block Имя  |  /pa unblock Имя")
    else
      optionsFrame.modeHint:SetText("Corruption, курсы, SB — да. Fear/Banish — SoftCC (passive+follow). Камни — нет.")
    end
  end
  optionsFrame.recallText:SetText("Recall (отзыв пета): " .. (db.recallKey or "|cff888888не назначен|r"))
  local blCount = 0
  for _ in pairs(db.blacklist) do
    blCount = blCount + 1
  end
  optionsFrame.blText:SetText(string.format(
    "Custom blacklist: %d имён (только для режима custom)",
    blCount
  ))
end

local function CreateOptions()
  if optionsFrame then
    return optionsFrame
  end

  -- Canvas panel for Settings / Interface Options (fills the AddOns content area)
  local f = CreateFrame("Frame", "PetAssistOptionsPanel")
  f.name = "PetAssist"
  f:Hide()

  local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("PetAssist " .. VERSION)

  local sub = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Питомец атакует цель вместе с твоим кастом (Warlock / Hunter)")

  local enableCheck = CreateFrame("CheckButton", "PetAssistEnableCheck", f, "UICheckButtonTemplate")
  enableCheck:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -16)
  local enableLabel = _G["PetAssistEnableCheckText"]
  if enableLabel then
    enableLabel:SetText("Включён")
  end
  enableCheck:SetScript("OnClick", function(self)
    DB().enabled = self:GetChecked() and true or false
    if DB().enabled then
      Refresh(false)
    else
      if not InCombatLockdown() then
        ClearOverrideBindings(binder)
        header:SetAttribute("pa_enabled", false)
        UnwrapAllMouse()
      else
        pendingRefresh = true
      end
      Print("выключен.")
    end
    RefreshOptionsUI()
  end)
  f.enableCheck = enableCheck

  local softCcCheck = CreateFrame("CheckButton", "PetAssistSoftCcCheck", f, "UICheckButtonTemplate")
  softCcCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -4)
  local softCcLabel = _G["PetAssistSoftCcCheckText"]
  if softCcLabel then
    softCcLabel:SetText("SoftCC Guard — на Fear/Banish отзывать пета (passive+follow)")
  end
  softCcCheck:SetScript("OnClick", function(self)
    DB().softCC = self:GetChecked() and true or false
    Refresh(false)
    Print(DB().softCC and "SoftCC включён." or "SoftCC выключен.")
    RefreshOptionsUI()
  end)
  f.softCcCheck = softCcCheck

  local modeText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  modeText:SetPoint("TOPLEFT", softCcCheck, "BOTTOMLEFT", 4, -14)
  modeText:SetWidth(520)
  modeText:SetJustifyH("LEFT")
  f.modeText = modeText

  local function SetMode(mode)
    DB().mode = mode
    Refresh(false)
    RefreshOptionsUI()
    Print("режим → " .. ModeLabel(mode))
  end

  local btnHarm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnHarm:SetSize(140, 24)
  btnHarm:SetPoint("TOPLEFT", modeText, "BOTTOMLEFT", 0, -8)
  btnHarm:SetText("harm (DoT+урон)")
  btnHarm:SetScript("OnClick", function() SetMode(MODE_HARM) end)

  local btnAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnAll:SetSize(100, 24)
  btnAll:SetPoint("LEFT", btnHarm, "RIGHT", 8, 0)
  btnAll:SetText("all")
  btnAll:SetScript("OnClick", function() SetMode(MODE_ALL) end)

  local btnCustom = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnCustom:SetSize(100, 24)
  btnCustom:SetPoint("LEFT", btnAll, "RIGHT", 8, 0)
  btnCustom:SetText("custom")
  btnCustom:SetScript("OnClick", function() SetMode(MODE_CUSTOM) end)

  local modeHint = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  modeHint:SetPoint("TOPLEFT", btnHarm, "BOTTOMLEFT", 0, -8)
  modeHint:SetWidth(520)
  modeHint:SetJustifyH("LEFT")
  f.modeHint = modeHint

  local blText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  blText:SetPoint("TOPLEFT", modeHint, "BOTTOMLEFT", 0, -12)
  blText:SetWidth(520)
  blText:SetJustifyH("LEFT")
  f.blText = blText

  local recallText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  recallText:SetPoint("TOPLEFT", blText, "BOTTOMLEFT", 0, -16)
  recallText:SetWidth(520)
  recallText:SetJustifyH("LEFT")
  f.recallText = recallText

  local bindBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  bindBtn:SetSize(160, 24)
  bindBtn:SetPoint("TOPLEFT", recallText, "BOTTOMLEFT", 0, -8)
  bindBtn:SetText("Назначить Recall")
  bindBtn:SetScript("OnClick", function(self)
    if InCombatLockdown() then
      Print("нельзя менять бинд в бою.")
      return
    end
    self:SetText("Нажми клавишу…")
    local binderFrame = CreateFrame("Frame", nil, f)
    binderFrame:EnableKeyboard(true)
    if binderFrame.SetPropagateKeyboardInput then
      binderFrame:SetPropagateKeyboardInput(false)
    end
    binderFrame:SetScript("OnKeyDown", function(_, key)
      if key == "ESCAPE" then
        self:SetText("Назначить Recall")
        binderFrame:Hide()
        return
      end
      if key == "UNKNOWN" or key == "LSHIFT" or key == "RSHIFT"
        or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
        return
      end
      local parts = {}
      if IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
      if IsControlKeyDown() then parts[#parts + 1] = "CTRL" end
      if IsAltKeyDown() then parts[#parts + 1] = "ALT" end
      parts[#parts + 1] = key
      local binding = table.concat(parts, "-")
      DB().recallKey = binding
      Refresh(true)
      ApplyRecallBinding()
      self:SetText("Назначить Recall")
      Print("Recall → " .. binding .. " (/petpassive + /petfollow)")
      RefreshOptionsUI()
      binderFrame:Hide()
    end)
    binderFrame:Show()
  end)

  local clearBind = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBind:SetSize(100, 24)
  clearBind:SetPoint("LEFT", bindBtn, "RIGHT", 8, 0)
  clearBind:SetText("Сброс")
  clearBind:SetScript("OnClick", function()
    DB().recallKey = nil
    Refresh(true)
    Print("Recall бинд сброшен.")
    RefreshOptionsUI()
  end)

  local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  refreshBtn:SetSize(120, 24)
  refreshBtn:SetPoint("TOPLEFT", bindBtn, "BOTTOMLEFT", 0, -20)
  refreshBtn:SetText("Refresh")
  refreshBtn:SetScript("OnClick", function() Refresh(false) end)

  local hint = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  hint:SetPoint("TOPLEFT", refreshBtn, "BOTTOMLEFT", 0, -20)
  hint:SetWidth(520)
  hint:SetJustifyH("LEFT")
  hint:SetText("/pa softcc on|off  |  /pa block Fear  |  /pa mode harm\nEsc → Options → AddOns → PetAssist")

  f:SetScript("OnShow", RefreshOptionsUI)

  optionsFrame = f
  RefreshOptionsUI()
  return f
end

local function RegisterOptionsPanel()
  local panel = CreateOptions()
  if settingsCategory then
    return
  end

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(settingsCategory)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

local function ToggleOptions()
  RegisterOptionsPanel()
  RefreshOptionsUI()

  if settingsCategory and Settings and Settings.OpenToCategory then
    -- Classic Era accepts category ID; some builds accept the category object
    if settingsCategory.GetID then
      Settings.OpenToCategory(settingsCategory:GetID())
    else
      Settings.OpenToCategory(settingsCategory)
    end
    return
  end

  if InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(optionsFrame) -- Classic quirk: call twice
    return
  end

  -- Fallback: show panel as floating window
  if not optionsFrame:GetParent() or optionsFrame:GetParent() == UIParent then
    optionsFrame:SetParent(UIParent)
    optionsFrame:ClearAllPoints()
    optionsFrame:SetSize(480, 360)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
  end
  optionsFrame:Show()
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:RegisterEvent("UNIT_PET")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then
      DB()
      RebuildBlockedNames()
      RegisterOptionsPanel()
    end
    return
  end

  if event == "CVAR_UPDATE" then
    if arg1 == "ActionButtonUseKeyDown" then
      SyncKeyDownAttr()
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    if DB().enabled then
      C_Timer.After(0.75, function()
        Refresh(false)
      end)
      -- Late scan for Dominos/ElvUI that load after us
      C_Timer.After(2.5, function()
        if DB().enabled and not InCombatLockdown() then
          ScanExtraButtons()
        end
      end)
    end
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if pendingRefresh or DB().enabled then
      Refresh(true)
    end
    return
  end

  if event == "UNIT_PET" and arg1 ~= "player" then
    return
  end

  if not DB().enabled then
    return
  end

  if InCombatLockdown() then
    pendingRefresh = true
    return
  end

  Apply()
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

SLASH_PETASSIST1 = "/petassist"
SLASH_PETASSIST2 = "/pa"
SlashCmdList.PETASSIST = function(msg)
  local db = DB()
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""
  rest = rest or ""

  if cmd == "" or cmd == "help" or cmd == "помощь" then
    Print("Команды: on|off|refresh|test|status|config|mode|softcc|block|unblock|recall")
    Print("Режим: " .. ModeLabel(db.mode) .. " | SoftCC: " .. (db.softCC ~= false and "on" or "off"))
  elseif cmd == "on" or cmd == "вкл" then
    db.enabled = true
    Refresh(false)
  elseif cmd == "off" or cmd == "выкл" then
    db.enabled = false
    if not InCombatLockdown() then
      ClearOverrideBindings(binder)
      header:SetAttribute("pa_enabled", false)
      UnwrapAllMouse()
    else
      pendingRefresh = true
    end
    Print("выключен.")
  elseif cmd == "refresh" or cmd == "rewrap" or cmd == "обновить" then
    Refresh(false)
  elseif cmd == "config" or cmd == "options" or cmd == "настройки" then
    ToggleOptions()
  elseif cmd == "softcc" or cmd == "cc" then
    local m = rest:lower()
    if m == "on" or m == "вкл" or m == "1" then
      db.softCC = true
    elseif m == "off" or m == "выкл" or m == "0" then
      db.softCC = false
    else
      db.softCC = not (db.softCC ~= false)
    end
    Refresh(false)
    Print("SoftCC → " .. (db.softCC and "on (Fear/Banish отзывают пета)" or "off"))
  elseif cmd == "mode" or cmd == "режим" then
    local m = rest:lower()
    if m == MODE_ALL or m == MODE_HARM or m == MODE_CUSTOM then
      db.mode = m
      Refresh(false)
      Print("режим → " .. ModeLabel(m))
    else
      Print("Использование: /pa mode all|harm|custom (сейчас: " .. tostring(db.mode) .. ")")
    end
  elseif cmd == "block" or cmd == "блок" then
    if rest == "" then
      Print("Использование: /pa block ИмяСпелла")
      return
    end
    db.blacklist[rest] = true
    db.blacklist[rest:lower()] = true
    if db.mode ~= MODE_CUSTOM then
      Print("Добавлено в blacklist. Включи custom: /pa mode custom")
    end
    Refresh(true)
    Print("block: " .. rest)
  elseif cmd == "unblock" or cmd == "разблок" then
    if rest == "" then
      Print("Использование: /pa unblock ИмяСпелла")
      return
    end
    db.blacklist[rest] = nil
    db.blacklist[rest:lower()] = nil
    Refresh(true)
    Print("unblock: " .. rest)
  elseif cmd == "recall" or cmd == "отзыв" then
    if rest == "" or rest:lower() == "clear" or rest:lower() == "сброс" then
      db.recallKey = nil
      Refresh(true)
      Print("Recall бинд сброшен. Назначить: /pa recall SHIFT-F")
    else
      db.recallKey = rest:upper():gsub("%s+", "")
      Refresh(true)
      Print("Recall → " .. db.recallKey)
    end
  elseif cmd == "test" or cmd == "тест" then
    local nProxy, nWrap = 0, 0
    for _ in pairs(proxies) do
      nProxy = nProxy + 1
    end
    for _ in pairs(wrapped) do
      nWrap = nWrap + 1
    end
    local p = proxies["ActionButton1"]
    Print(string.format(
      "v%s | on=%s | mode=%s | softCC=%s | proxy=%d | wrap=%d | keyDown=%s | lockdown=%s | recall=%s",
      VERSION, tostring(db.enabled), tostring(db.mode), tostring(db.softCC ~= false),
      nProxy, nWrap, tostring(UseKeyDown()), tostring(InCombatLockdown()), tostring(db.recallKey)
    ))
    if p then
      local actionName = ({ [0] = "none", [1] = "assist", [2] = "softcc" })[p.paAction or 0] or "?"
      Print("ActionButton1 action=" .. actionName .. " macro:\n" .. tostring(p.paMacro or p:GetAttribute("macrotext")))
    else
      Print("ActionButton1 proxy ещё нет — /petassist refresh")
    end
  elseif cmd == "status" or cmd == "статус" then
    Print((db.enabled and ("включён v" .. VERSION) or "выключен")
      .. " | " .. ModeLabel(db.mode)
      .. " | SoftCC " .. (db.softCC ~= false and "on" or "off"))
  else
    Print("Неизвестная команда. /pa help")
  end
end
