-- Native action execution is modeled, not Blizzard's protected environment.
-- This suite exercises real addon initialization, events, bindings and snippets.
local frames, bindings, actions, macros, spellNames = {}, {}, {}, {}, {
  [5782] = "Fear", [172] = "Corruption", [1454] = "Life Tap",
  [5484] = "Howl of Terror", [13809] = "Frost Trap", [6603] = "Attack",
}
local combat, secure, keyDown, page = false, false, true, 1
local executed, petCommands, messages, timers = {}, {}, {}, {}
local Frame = {}
Frame.__index = Frame
function Frame:GetName() return self.name end
function Frame:GetID() return self.id or 0 end
function Frame:SetAttribute(name, value)
  assert(not combat or secure, "insecure protected attribute write in combat: " .. name)
  self.attrs[name] = value
end
function Frame:GetAttribute(name) return self.attrs[name] end
function Frame:GetEffectiveAttribute(name, button)
  local suffix = button == "PetAssist" and "-PetAssist" or (button == "RightButton" and "2" or "1")
  local value = self.attrs["*" .. name .. (suffix == "-PetAssist" and suffix or "")] or self.attrs[name .. suffix] or self.attrs["*" .. name .. "*"]
  if value == nil then value = self.attrs[name] end
  if value == nil and self.attrs["useparent-" .. name] and self.parent then
    value = self.parent:GetEffectiveAttribute(name, button)
  end
  return value
end
function Frame:SetFrameRef(name, value) self.refs[name] = value end
function Frame:GetFrameRef(name) return self.refs[name] end
local allowed = { GetAttribute=true, SetAttribute=true, GetEffectiveAttribute=true, GetID=true, GetName=true, GetFrameRef=true }
local function restricted(frame)
  return setmetatable({}, {__index=function(_, method)
    assert(allowed[method], "method unavailable in restricted environment: " .. method)
    return function(_, ...)
      local value=frame[method](frame, ...)
      if method=="GetFrameRef" and value then return restricted(value) end
      return value
    end
  end})
end
function Frame:WrapScript(btn, script, pre, post)
  assert(not combat)
  if FORCE_SNIPPET_FAIL then error("loadstring_untainted missing") end
  assert(not btn.wrapper, "double wrapping")
  btn.wrapper = assert(loadstring("local self, control, button, down = ...\n" .. pre))
  btn.control = self
  btn.post = post and assert(loadstring("local self, control, message, button, down = ...\n" .. post))
end
function Frame:UnwrapScript(btn) assert(not combat); btn.wrapper = nil; btn.post = nil end
function Frame:CalculateAction()
  if self.native then
    return self:GetID() + ((self:GetEffectiveAttribute("actionpage", "LeftButton") or page) - 1) * 12
  end
  return self:GetAttribute("action")
end
function Frame:Click(button, down, mouse)
  local previous = secure
  secure = true
  local message
  if self.wrapper then
    local newbutton
    newbutton, message = self.wrapper(restricted(self), restricted(self.control), button, down)
    button = newbutton or button
  end
  local useDown = self:GetEffectiveAttribute("useOnKeyDown", button)
  if useDown == nil then useDown = keyDown end
  -- Blizzard's ActionBarActionButtonMixin:OnClick always forwards these
  -- clicks (including /click and override bindings) as secure mouse input.
  -- Its native keybindings use a separate TryUseActionButton path.
  if down == (not (self.native or mouse) and useDown) then
    if self:GetEffectiveAttribute("type", button) == "action" then
      executed[#executed + 1] = self:CalculateAction()
    elseif self:GetEffectiveAttribute("type", button) == "macro" then
      local text = self:GetEffectiveAttribute("macrotext", button)
      local prefix, target, mouseButton, phase = text:match("^(.-)\n/click (%S+) (%S+) (%d)$")
      petCommands[#petCommands + 1] = prefix or text
      -- Re-entering the currently executing macro button is not a reliable
      -- native action dispatch path. Model rejection instead of allowing it.
      if target and target ~= self:GetName() then _G[target]:Click(mouseButton, phase == "1") end
    end
  end
  if message and self.post then self.post(restricted(self), restricted(self.control), message, button, down) end
  if self.scripts.PostClick then self.scripts.PostClick(self, button, down) end
  secure = previous
end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:HookScript(name, hook)
  local original=self.scripts[name]
  self.scripts[name]=function(self, ...)
    if original then original(self, ...) end
    hook(self, ...)
  end
end
function Frame:CreateFontString() return setmetatable({ attrs={}, scripts={}, refs={} }, Frame) end
function Frame:CreateTexture() return setmetatable({ attrs={}, scripts={}, refs={} }, Frame) end
function Frame:SetColorTexture(...) self.color = {...} end
function Frame:SetChecked(value) self.checked = value end
function Frame:GetChecked() return self.checked end
function Frame:SetText(value) self.text = value end
function Frame:GetText() return self.text or "" end
function Frame:IsShown() return self.shown == true end
function Frame:GetParent() return self.parent end
function Frame:SetParent(value) self.parent = value end
function Frame:Hide()
  local shown = self.shown
  self.shown = false
  if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:EnableKeyboard(value) self.keyboard = value end
function Frame:Enable() self.disabled = false end
function Frame:Disable() self.disabled = true end
function Frame:SetScrollChild(child) self.scrollChild = child end
function Frame:SetVerticalScroll(value) self.scrollOffset = value end
function Frame:GetStringHeight() return 28 end
function Frame:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
for _, method in ipairs({"RegisterForClicks", "RegisterForDrag", "RegisterEvent", "SetPoint", "SetSize",
  "SetWidth", "SetHeight", "SetJustifyH", "SetBackdrop", "SetMultiLine", "SetFontObject", "SetMaxLetters", "SetFocus", "HighlightText", "SetPropagateKeyboardInput", "ClearAllPoints",
  "SetFrameStrata", "SetAutoFocus", "ClearFocus", "SetAllPoints", "SetTexture"}) do Frame[method] = function() end end
function CreateFrame(kind, name, parent, template)
  local f = setmetatable({name=name, parent=parent, attrs={}, refs={}, scripts={}, shown=true}, Frame)
  if name then _G[name] = f end
  frames[#frames + 1] = f
  if template == "UICheckButtonTemplate" then _G[name .. "Text"] = f:CreateFontString() end
  return f
end
UIParent = CreateFrame("Frame", "UIParent")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, value) messages[#messages + 1] = value end }
SlashCmdList = {}
BOOKTYPE_SPELL = "spell"
ATTACK = "Attack"
function GetBuildInfo()
  local interface = CLIENT_INTERFACE or 11509
  if interface >= 16000 then
    return "1.60.1", "70338", "Oct 12 2026", interface
  end
  return "1.15.9", "123456", "Oct 10 2026", interface
end
function GetServerTime() return 1791660000 end
function IsAddOnLoaded(name) return name=="Bartender4" end
function GetAddOnMetadata() return "test-version" end
function GetLocale() return TEST_LOCALE or "enUS" end
function UnitClass() return "Player", TEST_CLASS or "WARLOCK" end
function InCombatLockdown() return combat end
function GetCVarBool() return keyDown end
local function SpellNameFromId(id)
  if spellNames[id] then return spellNames[id] end
  for _, name in pairs(spellNames) do if name == id then return name end end
end
if CLIENT_INTERFACE and CLIENT_INTERFACE >= 16000 then
  GetSpellInfo = nil
  C_Spell = {
    GetSpellName = SpellNameFromId,
    GetSpellInfo = function(id)
      local name = SpellNameFromId(id)
      if name then return { name = name } end
    end,
  }
else
  function GetSpellInfo(id) return SpellNameFromId(id) end
end
function GetActionInfo(slot)
  local action = actions[slot]
  if action then return action[1], action[2] end
end
function GetMacroInfo(id)
  assert(id ~= nil, "lost macro ID")
  local macro = macros[id]
  if macro then return macro[1], nil, macro[2] end
end
function wipe(t) for k in pairs(t) do t[k] = nil end end
function RegisterStateDriver(f, name, driver) f:SetAttribute("state-" .. name, "1") end
function GetBindingKey(command)
  if command == "ACTIONBUTTON1" then return "1", "SHIFT-1" end
  if command == "ACTIONBUTTON2" then return "2" end
end
function GetBindingAction(key) return key == "SHIFT-F" and "TARGETFOCUS" or "" end
function SetOverrideBindingClick(_, _, key, name, button)
  assert(not combat, "binding changed in combat")
  bindings[key] = {name, button}
end
function ClearOverrideBindings() assert(not combat); wipe(bindings) end
C_Timer = {
  NewTimer = function(_, fn)
    local timer = {fn=fn, Cancel=function(self) self.cancelled=true end}
    timers[#timers + 1] = timer
    return timer
  end,
  After = function(_, fn) timers[#timers + 1] = {fn=fn} end,
}
Settings = {
  RegisterCanvasLayoutCategory = function() return {GetID=function() return 1 end} end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() if PetAssistOptionsPanel then PetAssistOptionsPanel:Show() end end,
}
local bar = CreateFrame("Frame", "TestBar")
bar:SetAttribute("actionpage", 1)
for i = 1, 12 do
  local btn = CreateFrame("Button", "ActionButton" .. i, bar)
  btn.id, btn.native = i, true
  btn:SetAttribute("type", "action")
  btn:SetAttribute("useparent-actionpage", true)
end
local extra = CreateFrame("Button", "BT4Button1")
extra:SetAttribute("type", "action")
extra:SetAttribute("action", 25)
actions[1], actions[2], actions[13], actions[25] = {"spell",5782}, {"spell",172}, {"spell",1454}, {"spell",172}
if PRELOAD_SOURCE then assert(loadstring(PRELOAD_SOURCE))() end
assert(loadstring(ADDON_SOURCE))("PetAssist")
local eventFrame
for _, frame in ipairs(frames) do if frame.scripts.OnEvent then eventFrame = frame end end
local function event(name, ...) eventFrame.scripts.OnEvent(eventFrame, name, ...) end
local function flush()
  local current = timers; timers = {}
  for _, timer in ipairs(current) do if not timer.cancelled then timer.fn() end end
end
local function command(text) SlashCmdList.PETASSIST(text) end
local function click(key)
  wipe(executed); wipe(petCommands)
  local binding = assert(bindings[key])
  _G[binding[1]]:Click(binding[2], true)
  _G[binding[1]]:Click(binding[2], false)
end
local passed = 0
local function check(name, fn)
  fn(); passed = passed + 1; print("ok " .. passed .. " - " .. name)
end
if FOREVER_ONLY then
  event("ADDON_LOADED", "PetAssist")
  event("PLAYER_ENTERING_WORLD")
  flush()
  check("Forever compat loads and detects forever client", function()
    assert(PetAssistCompat and PetAssistCompat.isForever)
    assert(PetAssistCompat.DetectForever())
    assert(PetAssistCompat.SupportsAssistStance())
  end)
  check("Forever compartment click opens settings", function()
    PetAssistOptionsPanel:Hide()
    PetAssist_CompartmentClick("PetAssist", "LeftButton")
    assert(PetAssistOptionsPanel:IsShown())
  end)
  if FORCE_SNIPPET_FAIL then
    check("snippet failure keeps Recall path and disables wraps", function()
      assert(not bindings["1"])
      local joined = table.concat(messages, "\n")
      assert(joined:find("Secure action-bar wrapping is unavailable", 1, true)
        or joined:find("Обёртка панелей недоступна", 1, true))
      assert(PetAssistHeader:GetAttribute("pa_enabled") == false)
    end)
  else
    check("Forever SoftCC Fear still recalls", function()
      click("1")
      assert(#petCommands == 1 and petCommands[1] == "/petpassive\n/petfollow")
      assert(#executed == 1 and executed[1] == 1)
    end)
    check("Forever status ticker notes SoftCC recall and attack", function()
      click("1")
      assert(_G.PetAssistStatus.text:GetText():find("recalled", 1, true))
      click("2")
      assert(_G.PetAssistStatus.text:GetText():find("attack", 1, true))
      flush()
      assert(not _G.PetAssistStatus:IsShown())
    end)
    check("Forever assist stance prefixes petattack", function()
      command("stance assist")
      click("2")
      assert(#petCommands == 1)
      assert(petCommands[1]:find("/petassist", 1, true))
      assert(petCommands[1]:find("/petattack", 1, true))
      assert(#executed == 1 and executed[1] == 2)
    end)
    check("Forever aggressive stance is selectable and restored on eligible actions", function()
      command("stance aggressive")
      assert(PetAssistDB.stance == "aggressive" and PetAssistDB.restoreStance)
      assert(PetAssistOptionsPanel.stanceChoices.buttons.aggressive:GetChecked())
      click("2")
      assert(petCommands[1]:find("/petaggressive [pet,@target,harm,nodead]", 1, true))
      assert(petCommands[1]:find("/petattack", 1, true) and #executed == 1)
      click("1"); assert(petCommands[1] == "/petpassive\n/petfollow")
      click("2"); assert(petCommands[1]:find("/petaggressive", 1, true))
      command("stance assist")
    end)
    check("Forever preferred stances precede attacks with keep-target enabled", function()
      command("keeptarget on")
      for _, entry in ipairs({{"passive", "/petpassive"}, {"defensive", "/petdefensive"},
          {"assist", "/petassist"}, {"aggressive", "/petaggressive"}}) do
        command("stance " .. entry[1])
        click("2")
        assert(petCommands[1]:find(entry[2] .. " [pet,@target,harm,nodead]", 1, true) == 1)
        assert(petCommands[1]:find("/petattack [@pettarget,noexists][@pettarget,dead] target", 1, true))
        assert(#executed == 1)
      end
      command("keeptarget off"); command("stance assist")
    end)
    check("Forever uses the client Defensive Assist alias when available", function()
      SLASH_PET_DEFENSIVE1 = "/petdefensive"
      SLASH_PET_DEFENSIVEASSIST1 = "/testdefensiveassist"
      command("keeptarget on")
      command("stance defensive")
      click("2")
      assert(#petCommands == 1 and petCommands[1] == "/testdefensiveassist [pet,@target,harm,nodead]\n"
        .. "/petattack [@pettarget,noexists][@pettarget,dead] target")
      assert(#executed == 1 and executed[1] == 2)
      command("report")
      assert(PetAssistDebugReport.edit:GetText():find("preparedStanceCommand=/testdefensiveassist", 1, true))
      assert(PetAssistDebugReport.edit:GetText():find("defensiveAssistAlias=/testdefensiveassist defensiveAlias=/petdefensive", 1, true))
      SLASH_PET_DEFENSIVE1, SLASH_PET_DEFENSIVEASSIST1 = nil, nil
      command("keeptarget off"); command("stance assist")
    end)
    check("Forever Defensive leaves the only click for the player spell", function()
      NUM_PET_ACTION_SLOTS = 10
      GetPetActionInfo = function(slot)
        if slot == 4 then return "PET_MODE_DEFENSIVEASSIST", nil, true end
      end
      command("stance defensive")
      local expected = "/petdefensive [pet,@target,harm,nodead]\n/petattack [pet,@target,harm,nodead]"
      click("2")
      assert(#petCommands == 1 and petCommands[1] == expected)
      assert(#executed == 1 and executed[1] == 2)
      assert(not PetAssistDefensiveStance)
      wipe(executed); wipe(petCommands)
      combat = true
      ActionButton2:Click("LeftButton", true, true)
      ActionButton2:Click("LeftButton", false, true)
      combat = false
      assert(#petCommands == 1 and petCommands[1] == expected)
      assert(#executed == 1 and executed[1] == 2)
      GetPetActionInfo, NUM_PET_ACTION_SLOTS = nil, nil
      command("stance assist")
    end)
    check("Forever keep-target setting preserves assist and SoftCC", function()
      command("keeptarget on")
      click("2")
      assert(petCommands[1]:find("/petassist", 1, true))
      assert(petCommands[1]:find("/petattack [@pettarget,noexists][@pettarget,dead] target", 1, true))
      assert(#executed == 1 and executed[1] == 2)
      click("1"); assert(petCommands[1] == "/petpassive\n/petfollow" and #executed == 1)
      command("keeptarget off")
    end)
    check("Forever C_Spell names resolve SoftCC ids", function()
      assert(not GetSpellInfo)
      assert(C_Spell.GetSpellName(5782) == "Fear")
      assert(PetAssistCompat.SpellName(5782) == "Fear")
    end)
  end
  print("Passed " .. passed .. " Forever scenarios (" .. _VERSION .. ")")
  return
end
event("ADDON_LOADED", "PetAssist")
event("PLAYER_ENTERING_WORLD")
flush()
PetAssistOptionsPanel:Show()
check("Fear recalls once and executes original action", function()
  click("1")
  assert(#petCommands == 1 and petCommands[1] == "/petpassive\n/petfollow")
  assert(#executed == 1 and executed[1] == 1)
  assert(bindings["1"][1] == "ActionButton1")
end)
check("onboarding welcome shows once per character", function()
  local joined = table.concat(messages, "\n")
  assert(joined:find("PetAssist is on", 1, true))
  assert(joined:find("Recall key", 1, true))
  assert(joined:find("/pa ticker off", 1, true))
  assert(PetAssistDB.welcomeShown == true)
  wipe(messages)
  event("PLAYER_ENTERING_WORLD")
  flush()
  assert(#messages == 0) -- no welcome repeat on later logins
end)
check("status ticker mirrors SoftCC recall and attack dispatch", function()
  command("ticker on")
  click("1")
  assert(_G.PetAssistStatus.text:GetText():find("recalled", 1, true))
  assert(_G.PetAssistStatus:IsShown())
  click("2")
  assert(_G.PetAssistStatus.text:GetText():find("attack", 1, true))
  flush() -- the 2.5s hide timer
  assert(not _G.PetAssistStatus:IsShown())
  command("ticker off")
  click("1")
  assert(not _G.PetAssistStatus:IsShown()) -- setting suppresses the note
  assert(PetAssistDB.statusTicker == false)
  command("ticker on")
  assert(PetAssistDB.statusTicker == true)
  PetAssistOptionsPanel:Show()
  assert(PetAssistOptionsPanel.tickerCheck:GetChecked() == true)
end)
check("assisted slots use a distinct native action delegate", function()
  click("2")
  local delegate=PetAssistHeader:GetFrameRef("pa_action_ActionButton2")
  assert(delegate and delegate~=ActionButton2 and delegate:GetAttribute("type")=="action")
  assert(delegate:GetAttribute("action")==2)
  assert(ActionButton2:GetAttribute("*macrotext-PetAssist"):find(delegate:GetName(),1,true))
  assert(not ActionButton2:GetAttribute("*macrotext-PetAssist"):find("/click ActionButton2 ",1,true))
  assert(#executed==1 and #petCommands==1)
end)
check("missing action delegate leaves native skill execution intact", function()
  local name="pa_action_ActionButton2"
  local delegate=PetAssistHeader:GetFrameRef(name)
  PetAssistHeader:SetFrameRef(name,nil)
  click("2"); assert(#executed==1 and #petCommands==0)
  PetAssistHeader:SetFrameRef(name,delegate)
end)
check("delegate carries modified native targeting attributes", function()
  ActionButton2:SetAttribute("unit1","focus")
  ActionButton2:SetAttribute("checkselfcast",true)
  click("2")
  local delegate=PetAssistHeader:GetFrameRef("pa_action_ActionButton2")
  assert(delegate:GetAttribute("*unit*")=="focus" and delegate:GetAttribute("checkselfcast"))
  ActionButton2:SetAttribute("unit1",nil); ActionButton2:SetAttribute("checkselfcast",nil)
end)
check("native mouse-up preserves cast and pet command with key-down enabled", function()
  wipe(petCommands); wipe(executed)
  ActionButton2:Click("LeftButton",true,true)
  ActionButton2:Click("LeftButton",false,true)
  assert(#petCommands==1 and #executed==1 and executed[1]==2)
end)
check("Blizzard bar casts once for mouse and bound keys with either CVar phase", function()
  for _, phase in ipairs({true, false}) do
    keyDown=phase; event("CVAR_UPDATE", "ActionButtonUseKeyDown")
    for _, key in ipairs({"1", "2", "SHIFT-1"}) do
      click(key); assert(#executed==1 and #petCommands==1)
    end
    for _, btn in ipairs({ActionButton1, ActionButton2}) do
      wipe(executed); wipe(petCommands)
      btn:Click("LeftButton",true,true); btn:Click("LeftButton",false,true)
      assert(#executed==1 and #petCommands==1)
      assert(btn:GetAttribute("*macrotext-PetAssist"):match(" 0$"))
    end
  end
  keyDown=true; event("CVAR_UPDATE", "ActionButtonUseKeyDown")
end)
check("damage restores stance for both keys and mouse", function()
  click("2"); assert(petCommands[1]:find("/petdefensive",1,true))
  wipe(petCommands); extra:Click("LeftButton", true); extra:Click("LeftButton",false)
  assert(#petCommands == 1 and petCommands[1]:find("/petdefensive",1,true))
end)
-- The test harness records macro text; it does not evaluate WoW's unit
-- conditionals. Pet target behavior must also be checked in the game client.
check("keep target toggles attack command while preserving SoftCC", function()
  local normal = "/petattack [pet,@target,harm,nodead]"
  local keep = "/petattack [@pettarget,noexists][@pettarget,dead] target"
  assert(PetAssistDB.keepTarget == false)
  click("2"); assert(petCommands[1]:find(normal, 1, true) and #executed == 1)
  command("keeptarget on")
  assert(PetAssistDB.keepTarget == true and PetAssistOptionsPanel.keepTargetCheck:GetChecked())
  click("2"); assert(petCommands[1]:find(keep, 1, true) and #executed == 1)
  click("1"); assert(petCommands[1] == "/petpassive\n/petfollow" and #executed == 1)
  command("keeptarget off")
  assert(PetAssistDB.keepTarget == false and not PetAssistOptionsPanel.keepTargetCheck:GetChecked())
  click("2"); assert(petCommands[1]:find(normal, 1, true) and #executed == 1)
end)
check("keep target changes during combat apply after combat", function()
  local normal = "/petattack [pet,@target,harm,nodead]"
  local keep = "/petattack [@pettarget,noexists][@pettarget,dead] target"
  combat = true
  command("keeptarget on")
  assert(PetAssistDB.keepTarget == true)
  click("2"); assert(petCommands[1]:find(normal, 1, true) and #executed == 1)
  combat = false; event("PLAYER_REGEN_ENABLED")
  click("2"); assert(petCommands[1]:find(keep, 1, true) and #executed == 1)
  command("keeptarget off")
end)
check("keep target can be changed through settings", function()
  local checkbox = PetAssistOptionsPanel.keepTargetCheck
  checkbox:SetChecked(true); checkbox.scripts.OnClick(checkbox)
  assert(PetAssistDB.keepTarget == true)
  click("2"); assert(petCommands[1]:find("[@pettarget,noexists]", 1, true) and #executed == 1)
  checkbox:SetChecked(false); checkbox.scripts.OnClick(checkbox)
  assert(PetAssistDB.keepTarget == false)
  click("2"); assert(petCommands[1]:find("/petattack [pet,@target,harm,nodead]", 1, true) and #executed == 1)
end)
check("native paging in combat uses current slot policy", function()
  combat, secure = true, true; bar:SetAttribute("actionpage",2); secure=false
  event("ACTIONBAR_PAGE_CHANGED")
  click("1"); assert(executed[1] == 13 and #petCommands == 0)
  combat=false; event("PLAYER_REGEN_ENABLED")
  bar:SetAttribute("actionpage",1)
end)
check("simple Fear macro is recalled, body remains unchanged", function()
  macros[1] = {"Fear macro", "#showtooltip\n/cast Fear(Rank 1)"}
  actions[1] = {"macro",1}; command("refresh"); click("1")
  assert(petCommands[1] == "/petpassive\n/petfollow" and executed[1] == 1)
  assert(macros[1][2] == "#showtooltip\n/cast Fear(Rank 1)")
end)
check("invalid single-cast macro does not send pet", function()
  macros[1][2]="/cast UnknownSpell"; command("refresh"); click("1")
  assert(#petCommands==0 and #executed==1)
end)
check("conditional, item and sequence macros default to no interference", function()
  for _, body in ipairs({"/cast [mod:shift] Fear; Corruption", "/use item:5512", "/castsequence Fear, Corruption"}) do
    macros[1][2] = body; command("refresh"); click("1")
    assert(#petCommands == 0 and #executed == 1 and macros[1][2] == body)
  end
end)
check("long macro with explicit attack rule is never copied or truncated", function()
  local body = "#" .. string.rep("x",240) .. "\n/cast Fear"
  macros[1][2] = body
  command("rule attack Fear macro"); click("1")
  assert(petCommands[1]:find("/petattack",1,true) and macros[1][2] == body and #executed == 1)
end)
check("macros owning pet commands bypass even explicit rules", function()
  macros[1][2] = "/petfollow\n/cast Fear"; command("refresh"); click("1")
  assert(#petCommands == 0 and #executed == 1)
  command("rule clear Fear macro")
end)
check("spell rules override mode and SoftCC; clear restores default", function()
  actions[1] = {"spell",5782}
  command("rule ignore Fear"); click("1"); assert(#petCommands == 0)
  command("rule attack Fear"); click("1"); assert(petCommands[1]:find("/petattack",1,true))
  command("rule clear Fear"); click("1"); assert(petCommands[1] == "/petpassive\n/petfollow")
end)
check("passive preference and modifier binds execute original action", function()
  command("stance passive"); click("2"); assert(petCommands[1]:find("/petpassive",1,true))
  click("SHIFT-1"); assert(#petCommands == 1 and #executed == 1)
  command("stance off"); click("2"); assert(petCommands[1] == "/petattack [pet,@target,harm,nodead]")
end)
check("downranked spell uses original slot without spellbook reconstruction", function()
  actions[2] = {"spell",172}; command("refresh"); click("2")
  assert(#executed == 1 and executed[1] == 2)
  assert(ActionButton2:GetAttribute("type") == "action")
  assert(ActionButton2:GetAttribute("macrotext") == nil)
end)
check("optional Howl and Frost recalls", function()
  for _, data in ipairs({{"howl",5484}, {"frost",13809}}) do
    actions[1]={"spell",data[2]}; command(data[1].." off"); click("1"); assert(#petCommands==0)
    command(data[1].." on"); click("1"); assert(petCommands[1]=="/petpassive\n/petfollow")
  end
end)
check("default page driver works on older buttons without parent page", function()
  ActionButton1:SetAttribute("useparent-actionpage",nil)
  page=2; PetAssistHeader:SetAttribute("state-page","2")
  click("1"); assert(executed[1]==13 and #petCommands==0)
  page=1; PetAssistHeader:SetAttribute("state-page","1")
  ActionButton1:SetAttribute("useparent-actionpage",true)
end)
check("key-up configuration changed in combat is reconciled after combat", function()
  combat=true; keyDown=false; event("CVAR_UPDATE","ActionButtonUseKeyDown")
  combat=false; event("PLAYER_REGEN_ENABLED"); click("2")
  assert(#executed==1 and #petCommands==1)
end)
check("Blizzard secure mouse release takes priority over per-button key-down", function()
  ActionButton2:SetAttribute("useOnKeyDown",true); click("2")
  assert(#executed==1 and #petCommands==1)
  ActionButton2:SetAttribute("useOnKeyDown",nil)
end)
check("macro policy recall and ignore", function()
  actions[1]={"macro",1}; macros[1][2]="/use item:5512"
  command("macros recall"); click("1"); assert(petCommands[1]=="/petpassive\n/petfollow")
  command("macros ignore"); click("1"); assert(#petCommands==0 and #executed==1)
  command("macros auto")
end)
check("item action skipped in harm, assisted in all", function()
  actions[1]={"item",5512}; command("mode harm"); click("1"); assert(#petCommands==0)
  command("mode all"); click("1"); assert(#petCommands==1)
  command("mode harm")
end)
check("unknown spell and empty slots preserve native behavior", function()
  actions[1]={"spell",999999}; command("refresh"); click("1"); assert(#petCommands==0 and #executed==1)
  actions[1]=nil; command("refresh"); click("1"); assert(#petCommands==0)
end)
check("blacklist applies to macro name; entries counted once", function()
  actions[1]={"macro",1}; macros[1][2]="/cast Corruption"
  command("mode custom"); command("block Fear macro"); click("1"); assert(#petCommands==0)
  local count=0; for _ in pairs(PetAssistDB.blacklist) do count=count+1 end; assert(count==1)
  command("unblock Fear macro"); click("1"); assert(#petCommands==1)
end)
check("Recall reports conflicting underlying binding", function()
  command("recall SHIFT-F")
  assert(bindings["SHIFT-F"][1]=="PetAssistRecall")
  local found=false; for _, msg in ipairs(messages) do if msg:find("TARGETFOCUS",1,true) then found=true end end
  assert(found)
end)
check("diagnostics handle arbitrary and invalid buttons", function()
  command("test BT4Button1"); command("test MissingButton")
  assert(messages[#messages]:find("Unknown action button",1,true))
end)
check("diagnostics explain complex macros and explicit rules", function()
  local previousAction, previousMacro, previousMode, previousPolicy = actions[1], macros[1], PetAssistDB.mode, PetAssistDB.macroPolicy
  actions[1]={"macro",1}
  macros[1]={"Diagnostic macro", "/cast [mod:shift] Fear; Corruption"}
  command("mode harm"); command("macros auto"); command("refresh")
  command("test ActionButton1")
  local detail=messages[#messages-1]
  assert(detail:find("policy=0 | prepared=0",1,true))
  assert(detail:find("reason=complex macro: choose an explicit rule",1,true))
  command("rule attack Diagnostic macro")
  command("test ActionButton1")
  detail=messages[#messages-1]
  assert(detail:find("policy=1 | prepared=1",1,true))
  assert(detail:find("reason=explicit spell/macro rule",1,true))
  command("rule clear Diagnostic macro")
  actions[1], macros[1] = previousAction, previousMacro
  command("mode " .. previousMode); command("macros " .. previousPolicy)
end)
check("diagnostics explain pet-owning macros even with an explicit rule", function()
  local previousAction, previousMacro = actions[1], macros[1]
  actions[1]={"macro",1}
  macros[1]={"Diagnostic macro", "/petfollow\n/cast Fear"}
  command("rule attack Diagnostic macro")
  command("test ActionButton1")
  local detail=messages[#messages-1]
  assert(detail:find("policy=0 | prepared=0",1,true))
  assert(detail:find("reason=macro controls its own pet",1,true))
  command("rule clear Diagnostic macro")
  actions[1], macros[1] = previousAction, previousMacro
  command("refresh")
end)
check("rule editor applies and clears same policy as commands", function()
  local f=PetAssistOptionsPanel
  f.ruleName:SetText("Corruption")
  f.ruleApply.scripts.OnClick()
  assert(PetAssistDB.rules.corruption=="ignore")
  f.ruleChoices.buttons.clear.scripts.OnClick()
  f.ruleApply.scripts.OnClick()
  assert(PetAssistDB.rules.corruption==nil)
end)
check("options toggle stance, macro policy and optional CC", function()
  local f=PetAssistOptionsPanel
  local before=PetAssistDB.stance
  local wanted=before=="defensive" and "passive" or "defensive"
  f.stanceChoices.buttons[wanted].scripts.OnClick(); assert(PetAssistDB.stance==wanted)
  assert(f.stanceChoices.buttons[wanted]:GetChecked())
  assert(not f.stanceChoices.buttons[before]:GetChecked())
  f.macroChoices.buttons.attack.scripts.OnClick(); assert(PetAssistDB.macroPolicy=="attack")
  f.howlCheck:SetChecked(false); f.howlCheck.scripts.OnClick(f.howlCheck)
  assert(PetAssistDB.softCCHowl==false)
  command("macros auto")
end)
check("saved rules can be reopened and empty input does not create a rule", function()
  local f=PetAssistOptionsPanel
  f.ruleName:SetText("  Corruption  ")
  f.ruleChoices.buttons.attack.scripts.OnClick(); f.ruleApply.scripts.OnClick()
  local found=false
  for _, row in ipairs(f.ruleRows) do
    if row.shown and row.text:find("corruption",1,true) then
      row.scripts.OnClick(); found=true; break
    end
  end
  assert(found and f.ruleName:GetText()=="corruption")
  assert(f.ruleChoices.buttons.attack:GetChecked())
  f.ruleName:SetText("  "); f.ruleApply.scripts.OnClick()
  assert(PetAssistDB.rules[""]==nil and PetAssistDB.rules.corruption=="attack")
  f.ruleName:SetText("Corruption")
  f.ruleChoices.buttons.clear.scripts.OnClick(); f.ruleApply.scripts.OnClick()
end)
check("custom exclusions can be added and removed in settings", function()
  local f=PetAssistOptionsPanel
  f.excludedName:SetText("  Life Tap  "); f.excludeAdd.scripts.OnClick()
  assert(PetAssistDB.blacklist["life tap"] and not PetAssistDB.blacklist["Life Tap"])
  actions[1]={"spell",1454}
  f.modeChoices.buttons.custom.scripts.OnClick()
  click("1"); assert(#petCommands==0)
  f.excludeRemove.scripts.OnClick(); assert(not PetAssistDB.blacklist["life tap"])
  command("mode harm")
end)
check("graphical inspector handles default, third-party and unknown buttons", function()
  local f=PetAssistOptionsPanel
  f.selectTab("diagnostics")
  f.diagnosticName:SetText("   ")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton1",1,true))
  f.diagnosticName:SetText("  BT4Button1  ")
  f.testButton.scripts.OnClick(f.testButton)
  local gui=f.diagnosticResult:GetText()
  assert(gui:find("BT4Button1",1,true) and gui:find("Send pet to attack",1,true))
  command("test BT4Button1")
  assert(messages[#messages-1]:find("slot=25",1,true))
  f.diagnosticName:SetText("MissingButton")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("Unknown action button: MissingButton",1,true))
  command("test MissingButton")
  assert(messages[#messages]:find("Unknown action button: MissingButton",1,true))
end)
check("last action button works without debug logging and feeds the report", function()
  local f=PetAssistOptionsPanel
  f:Show(); f.selectTab("diagnostics")
  command("debug off")
  click("2")
  f.lastButton.scripts.OnClick(f.lastButton)
  assert(f.diagnosticName:GetText()=="ActionButton2")
  assert(f.diagnosticResult:GetText():find("ActionButton2",1,true))
  f.reportButton.scripts.OnClick(f.reportButton)
  assert(PetAssistDebugReport.edit:GetText():find("ActionButton2 slot=2",1,true))
  BT4Button1:Click("LeftButton", false, true)
  f.lastButton.scripts.OnClick(f.lastButton)
  assert(f.diagnosticName:GetText()=="BT4Button1")
  combat=true; click("1")
  f.lastButton.scripts.OnClick(f.lastButton)
  assert(f.diagnosticName:GetText()=="ActionButton1")
  combat=false; event("PLAYER_REGEN_ENABLED")
  command("off")
  ActionButton2:Click("LeftButton", false, true)
  f.lastButton.scripts.OnClick(f.lastButton)
  assert(f.diagnosticName:GetText()=="ActionButton1")
  command("on")
end)
check("graphical inspector clears stale results when input or state changes", function()
  local f=PetAssistOptionsPanel
  f.selectTab("diagnostics")
  f.diagnosticName:SetText("ActionButton1")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton1",1,true))
  f.diagnosticName:SetText("ActionButton2")
  f.diagnosticName:GetScript("OnTextChanged")(f.diagnosticName)
  assert(f.diagnosticResult:GetText()=="")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton2",1,true))
  f.keepTargetCheck:SetChecked(true); f.keepTargetCheck.scripts.OnClick(f.keepTargetCheck)
  assert(f.diagnosticResult:GetText()=="")
  f.keepTargetCheck:SetChecked(false); f.keepTargetCheck.scripts.OnClick(f.keepTargetCheck)
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton2",1,true))
  combat=true; event("PLAYER_REGEN_DISABLED")
  assert(f.diagnosticResult:GetText()=="")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton2",1,true))
  combat=false; event("PLAYER_REGEN_ENABLED")
  assert(f.diagnosticResult:GetText()=="")
  f.testButton.scripts.OnClick(f.testButton)
  assert(f.diagnosticResult:GetText():find("ActionButton2",1,true))
  event("ACTIONBAR_PAGE_CHANGED")
  assert(f.diagnosticResult:GetText()=="")
  assert(f.statusText:GetText():find("being refreshed",1,true))
  flush()
  assert(f.statusText:GetText():find("Settings applied",1,true))
end)
check("hidden settings synchronize with saved state when reopened", function()
  local f=PetAssistOptionsPanel
  f:Hide()
  command("keeptarget on")
  assert(PetAssistDB.keepTarget==true and not f.keepTargetCheck:GetChecked())
  f:Show()
  assert(f.keepTargetCheck:GetChecked())
  command("keeptarget off")
  assert(not f.keepTargetCheck:GetChecked())
end)
check("general settings explain target selection and pending combat changes", function()
  local f=PetAssistOptionsPanel
  f:Show(); f.selectTab("general")
  command("keeptarget off")
  assert(f.targetSummary:GetText():find("Off:", 1, true))
  f.keepTargetCheck:SetChecked(true); f.keepTargetCheck.scripts.OnClick(f.keepTargetCheck)
  assert(PetAssistDB.keepTarget and f.targetSummary:GetText():find("On:", 1, true))
  combat=true; event("PLAYER_REGEN_DISABLED")
  f.keepTargetCheck:SetChecked(false); f.keepTargetCheck.scripts.OnClick(f.keepTargetCheck)
  assert(not PetAssistDB.keepTarget and f.generalStatus:GetText():find("waiting for combat", 1, true))
  combat=false; event("PLAYER_REGEN_ENABLED")
  assert(not f.generalStatus:GetText():find("waiting for combat", 1, true))
  assert(f.targetSummary:GetText():find("Off:", 1, true))
end)
check("clicking a choice card updates the setting and selected highlight", function()
  local f=PetAssistOptionsPanel
  f:Show(); f.selectTab("general")
  command("mode harm")
  local cards = f.modeChoices.cards
  assert(cards.harm.fill.color[1] > cards.all.fill.color[1])
  cards.all.scripts.OnClick(cards.all)
  assert(PetAssistDB.mode == "all" and f.modeChoices.buttons.all:GetChecked())
  assert(not f.modeChoices.buttons.harm:GetChecked())
  assert(cards.all.fill.color[1] > cards.harm.fill.color[1])
  command("mode harm")
end)
check("graphical report uses the selected action button", function()
  local f=PetAssistOptionsPanel
  f.diagnosticName:SetText(" BT4Button1 ")
  f.reportButton.scripts.OnClick(f.reportButton)
  local report=PetAssistDebugReport.edit:GetText()
  assert(report:find("BT4Button1 slot=25",1,true))
  f.diagnosticName:SetText("MissingButton")
  f.reportButton.scripts.OnClick(f.reportButton)
  assert(PetAssistDebugReport.edit:GetText():find("unknown button=MissingButton",1,true))
  f.diagnosticName:SetText("")
  f.reportButton.scripts.OnClick(f.reportButton)
  assert(PetAssistDebugReport.edit:GetText():find("ActionButton1 slot=1",1,true))
end)
check("graphical refresh defers protected changes and updates status after combat", function()
  local f=PetAssistOptionsPanel
  f.selectTab("diagnostics")
  local previous=PetAssistHeader:GetAttribute("pa_slot_2")
  combat=true
  actions[2]={"spell",1454}
  f.refreshButton.scripts.OnClick(f.refreshButton)
  assert(PetAssistHeader:GetAttribute("pa_slot_2")==previous)
  assert(f.statusText:GetText():find("waiting for combat",1,true))
  combat=false; event("PLAYER_REGEN_ENABLED")
  assert(PetAssistHeader:GetAttribute("pa_slot_2")==0)
  assert(not f.statusText:GetText():find("waiting for combat",1,true))
  actions[2]={"spell",172}; command("refresh")
end)
check("graphical enable switch and slash commands update the same status", function()
  local f=PetAssistOptionsPanel
  f.selectTab("diagnostics")
  assert(f.statusText:GetText():find("enabled in settings",1,true))
  f.enableCheck:SetChecked(false); f.enableCheck.scripts.OnClick(f.enableCheck)
  assert(PetAssistDB.enabled==false and not bindings["1"])
  assert(f.statusText:GetText():find("disabled in settings",1,true))
  command("on")
  assert(PetAssistDB.enabled==true and bindings["1"])
  assert(f.enableCheck:GetChecked() and f.statusText:GetText():find("enabled in settings",1,true))
end)
check("graphical log controls preserve slash command compatibility", function()
  local f=PetAssistOptionsPanel
  f.debugCheck:SetChecked(true); f.debugCheck.scripts.OnClick(f.debugCheck)
  assert(PetAssistDB.debug==true)
  event("UI_ERROR_MESSAGE",50,"private")
  assert(#PetAssistDebugDB.entries>0)
  f.clearDebugButton.scripts.OnClick(f.clearDebugButton)
  assert(#PetAssistDebugDB.entries==0)
  command("debug off")
  assert(PetAssistDB.debug==false and not f.debugCheck:GetChecked())
  command("debug clear")
  f.selectTab("general")
end)
check("switching tabs cancels key capture and keeps preferences", function()
  local f=PetAssistOptionsPanel
  f.selectTab("general"); f.bindButton.scripts.OnClick(f.bindButton)
  assert(f.recallCapture.shown and f.recallCapture.keyboard)
  local stance=PetAssistDB.stance
  f.selectTab("rules")
  assert(f.activeTab=="rules" and not f.recallCapture.shown and not f.recallCapture.keyboard)
  assert(PetAssistDB.stance==stance)
  f.selectTab("general")
end)
check("closing options stops Recall key capture", function()
  local f=PetAssistOptionsPanel
  f:Show()
  for _, frame in ipairs(frames) do
    if frame.text=="Assign key" and frame.scripts.OnClick then frame.scripts.OnClick(frame); break end
  end
  assert(f.recallCapture.shown and f.recallCapture.keyboard)
  f:Hide()
  assert(not f.recallCapture.shown and not f.recallCapture.keyboard)
end)
check("disabling in combat is deferred then restores native bindings", function()
  combat=true; command("off"); assert(bindings["1"])
  combat=false; event("PLAYER_REGEN_ENABLED")
  assert(not bindings["1"] and not ActionButton1.wrapper and not extra.wrapper)
  wipe(executed); wipe(petCommands)
  ActionButton2:Click("LeftButton",true,true); ActionButton2:Click("LeftButton",false,true)
  assert(#executed==1 and #petCommands==0)
  assert(ActionButton2:GetAttribute("*type-PetAssist")==nil)
  command("on"); assert(bindings["1"] and ActionButton1.wrapper)
end)
check("diagnostics are opt-in and preserve mouse/key dispatch in combat", function()
  assert(PetAssistDB.debug==false and #PetAssistDebugDB.entries==0)
  actions[2]={"spell",172}; command("refresh"); click("2")
  assert(#PetAssistDebugDB.entries==0)
  command("debug on")
  combat=true; click("2")
  assert(#executed==1 and #petCommands==1)
  local log=table.concat(PetAssistDebugDB.entries,"\n")
  assert(log:find("bar-click",1,true) and log:find("delegate-click",1,true))
  combat=false
end)
check("reports include build, settings, cast failures and blocked actions, without private text", function()
  macros[1]={"PRIVATE_MACRO_NAME","/cast PRIVATE_MACRO_BODY"}; actions[1]={"macro",1}
  PetAssistDB.rules.PRIVATE_RULE_NAME="ignore"
  event("UI_ERROR_MESSAGE",50,"PRIVATE_ERROR_MESSAGE")
  event("ADDON_ACTION_BLOCKED","PetAssist","UseAction()")
  event("UNIT_SPELLCAST_FAILED","player","PRIVATE_CAST_GUID",172)
  command("report ActionButton1")
  local report=PetAssistDebugReport.edit:GetText()
  assert(report:find("format=1",1,true) and report:find("1.15.9",1,true))
  assert(report:find("Bartender4 loaded=true",1,true) and report:find("game-error id=50",1,true))
  assert(report:find("ADDON_ACTION_BLOCKED",1,true) and report:find("UNIT_SPELLCAST_FAILED spell=172",1,true))
  assert(not report:find("PRIVATE_",1,true))
  PetAssistDB.rules.PRIVATE_RULE_NAME=nil
end)
check("diagnostic log is bounded and clear/off work without altering protected state", function()
  for i=1,150 do event("UI_ERROR_MESSAGE",i,"private") end
  assert(#PetAssistDebugDB.entries==100)
  combat=true; command("debug off"); click("2")
  local count=#PetAssistDebugDB.entries
  event("UI_ERROR_MESSAGE",200,"private"); assert(#PetAssistDebugDB.entries==count)
  assert(#executed==1 and #petCommands==1)
  command("debug clear"); assert(#PetAssistDebugDB.entries==0)
  command("report MissingButton")
  assert(PetAssistDebugReport.edit:GetText():find("unknown button=MissingButton",1,true))
  combat=false
end)
print("Passed " .. passed .. " regression scenarios (" .. _VERSION .. ")")
