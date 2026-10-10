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
local allowed = { GetAttribute=true, SetAttribute=true, GetEffectiveAttribute=true, GetID=true, GetName=true }
local function restricted(frame)
  return setmetatable({}, {__index=function(_, method)
    assert(allowed[method], "method unavailable in restricted environment: " .. method)
    return function(_, ...) return frame[method](frame, ...) end
  end})
end
function Frame:WrapScript(btn, script, pre, post)
  assert(not combat)
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
  if down == (not mouse and useDown) then
    if self:GetEffectiveAttribute("type", button) == "action" then
      executed[#executed + 1] = self:CalculateAction()
    elseif self:GetEffectiveAttribute("type", button) == "macro" then
      local text = self:GetEffectiveAttribute("macrotext", button)
      local prefix, target, mouseButton, phase = text:match("^(.-)\n/click (%S+) (%S+) (%d)$")
      petCommands[#petCommands + 1] = prefix or text
      if target then _G[target]:Click(mouseButton, phase == "1") end
    end
  end
  if message and self.post then self.post(restricted(self), restricted(self.control), message, button, down) end
  secure = previous
end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:CreateFontString() return setmetatable({ attrs={}, scripts={}, refs={} }, Frame) end
function Frame:SetChecked(value) self.checked = value end
function Frame:GetChecked() return self.checked end
function Frame:SetText(value) self.text = value end
function Frame:GetText() return self.text or "" end
function Frame:GetParent() return self.parent end
function Frame:SetParent(value) self.parent = value end
function Frame:Hide()
  local shown = self.shown
  self.shown = false
  if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Frame:EnableKeyboard(value) self.keyboard = value end
function Frame:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
for _, method in ipairs({"RegisterForClicks", "RegisterForDrag", "RegisterEvent", "SetPoint", "SetSize",
  "SetWidth", "SetJustifyH", "SetPropagateKeyboardInput", "ClearAllPoints",
  "SetFrameStrata", "SetAutoFocus", "ClearFocus"}) do Frame[method] = function() end end
function CreateFrame(kind, name, parent, template)
  local f = setmetatable({name=name, parent=parent, attrs={}, refs={}, scripts={}}, Frame)
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
function GetLocale() return TEST_LOCALE or "enUS" end
function UnitClass() return "Player", TEST_CLASS or "WARLOCK" end
function InCombatLockdown() return combat end
function GetCVarBool() return keyDown end
function GetSpellInfo(id)
  if spellNames[id] then return spellNames[id] end
  for _, name in pairs(spellNames) do if name == id then return name end end
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
  OpenToCategory = function() end,
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
assert(loadstring(ADDON_SOURCE))("PetAssist")
local eventFrame
for _, frame in ipairs(frames) do if frame.scripts.OnEvent then eventFrame = frame end end
local function event(name, arg) eventFrame.scripts.OnEvent(eventFrame, name, arg) end
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
event("ADDON_LOADED", "PetAssist")
event("PLAYER_ENTERING_WORLD")
flush()
check("Fear recalls once and executes original action", function()
  click("1")
  assert(#petCommands == 1 and petCommands[1] == "/petpassive\n/petfollow")
  assert(#executed == 1 and executed[1] == 1)
  assert(bindings["1"][1] == "ActionButton1")
end)
check("native mouse-up preserves cast and pet command with key-down enabled", function()
  wipe(petCommands); wipe(executed)
  ActionButton2:Click("LeftButton",true,true)
  ActionButton2:Click("LeftButton",false,true)
  assert(#petCommands==1 and #executed==1 and executed[1]==2)
end)
check("damage restores stance for both keys and mouse", function()
  click("2"); assert(petCommands[1]:find("/petdefensive",1,true))
  wipe(petCommands); extra:Click("LeftButton", true); extra:Click("LeftButton",false)
  assert(#petCommands == 1 and petCommands[1]:find("/petdefensive",1,true))
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
check("per-button click phase controls helper click phase", function()
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
check("rule editor applies and clears same policy as commands", function()
  local f=PetAssistOptionsPanel
  f.ruleName:SetText("Corruption")
  f.ruleApply.scripts.OnClick()
  assert(PetAssistDB.rules.corruption=="ignore")
  for i=1,3 do f.ruleButton.scripts.OnClick(f.ruleButton) end
  f.ruleApply.scripts.OnClick()
  assert(PetAssistDB.rules.corruption==nil)
end)
check("options toggle stance, macro policy and optional CC", function()
  local f=PetAssistOptionsPanel
  local before=PetAssistDB.stance
  f.stanceButton.scripts.OnClick(); assert(PetAssistDB.stance~=before)
  f.macroButton.scripts.OnClick(); assert(PetAssistDB.macroPolicy=="attack")
  f.howlCheck:SetChecked(false); f.howlCheck.scripts.OnClick(f.howlCheck)
  assert(PetAssistDB.softCCHowl==false)
  command("macros auto")
end)
check("closing options stops Recall key capture", function()
  local f=PetAssistOptionsPanel
  f:Show()
  for _, frame in ipairs(frames) do
    if frame.text=="Bind Recall" and frame.scripts.OnClick then frame.scripts.OnClick(frame); break end
  end
  assert(f.recallCapture.shown and f.recallCapture.keyboard)
  f:Hide()
  assert(not f.recallCapture.shown and not f.recallCapture.keyboard)
end)
check("disabling in combat is deferred then restores native bindings", function()
  combat=true; command("off"); assert(bindings["1"])
  combat=false; event("PLAYER_REGEN_ENABLED")
  assert(not bindings["1"] and not ActionButton1.wrapper and not extra.wrapper)
  command("on"); assert(bindings["1"] and ActionButton1.wrapper)
end)
print("Passed " .. passed .. " regression scenarios (" .. _VERSION .. ")")
