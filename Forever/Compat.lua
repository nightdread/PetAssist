--[[
  PetAssist Forever compatibility layer.

  Loaded only from PetAssist_Camelot.toc (before PetAssist.lua).
  Forever uses Mainline-family APIs (Interface 16001); Classic Era does not load this file.
]]

PetAssistCompat = PetAssistCompat or {}
local C = PetAssistCompat

C.isForever = true
C.secureSnippetError = nil

local snippetProbeResult -- nil = not probed, true/false after probe

local function InterfaceVersion()
  if not GetBuildInfo then
    return nil
  end
  local _, _, _, interface = GetBuildInfo()
  return interface
end

--- Prefer interface range; named project constants when present (beta IDs were unreliable early on).
function C.DetectForever()
  local interface = InterfaceVersion()
  if type(interface) == "number" and interface >= 16000 and interface < 20000 then
    return true
  end
  if WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
    return true
  end
  return C.isForever == true
end

function C.SupportsAssistStance()
  return true
end

function C.IsValidStance(stance)
  return stance == "passive" or stance == "defensive" or stance == "assist" or stance == "aggressive"
end

function C.StanceCommand(stance)
  if stance == "passive" then
    return "/petpassive"
  end
  if stance == "assist" then
    return "/petassist"
  end
  if stance == "aggressive" then
    return "/petaggressive"
  end
  -- Forever's Defensive button uses Defensive Assist, a separate native command.
  local defensiveAssist = SLASH_PET_DEFENSIVEASSIST1
  if type(defensiveAssist) == "string" and defensiveAssist ~= "" then
    return defensiveAssist
  end
  return "/petdefensive"
end

--- Mainline-style spell name lookup with Classic fallback if globals reappear.
function C.SpellName(spellId)
  if not spellId then
    return nil
  end
  if C_Spell then
    if C_Spell.GetSpellName then
      local name = C_Spell.GetSpellName(spellId)
      if name then
        return name
      end
    end
    if C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(spellId)
      if type(info) == "table" and info.name then
        return info.name
      end
      if type(info) == "string" then
        return info
      end
    end
  end
  if GetSpellInfo then
    return GetSpellInfo(spellId)
  end
  return nil
end

function C.ResetSnippetProbe()
  snippetProbeResult = nil
  C.secureSnippetError = nil
end

function C.MarkSnippetsUnavailable(err)
  snippetProbeResult = false
  C.secureSnippetError = tostring(err)
end

--- Returns whether WrapScript/OnClick snippets are usable. Safe to call out of combat.
function C.ProbeSecureSnippets()
  if snippetProbeResult ~= nil then
    return snippetProbeResult
  end
  if InCombatLockdown and InCombatLockdown() then
    -- Cannot create/wrap securely in combat; defer a real probe.
    return true
  end
  local ok, err = pcall(function()
    local probe = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
    local btn = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    probe:WrapScript(btn, "OnClick", [[ return ]])
    probe:UnwrapScript(btn, "OnClick")
  end)
  if ok then
    snippetProbeResult = true
    C.secureSnippetError = nil
  else
    C.MarkSnippetsUnavailable(err)
  end
  return snippetProbeResult
end

function C.SecureSnippetsAvailable()
  return C.ProbeSecureSnippets()
end

function C.ClientLabel()
  local interface = InterfaceVersion() or "?"
  return "forever interface=" .. tostring(interface)
end
