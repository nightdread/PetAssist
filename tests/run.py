"""Run the addon regression suite with Lua 5.1 (pip install lupa==2.8)."""
from pathlib import Path
import argparse
from zipfile import ZipFile
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description="Validate the actual addon source or packaged release with Lua 5.1.")
inputs = parser.add_mutually_exclusive_group()
inputs.add_argument("--addon-source", type=Path, help="Validate an installed PetAssist.lua instead of the working copy")
inputs.add_argument("--archive", type=Path, help="Validate PetAssist/PetAssist.lua inside a ZIP")
args = parser.parse_args()
if args.archive:
    with ZipFile(args.archive) as archive:
        assert archive.testzip() is None, "Corrupt package"
        addon_source = archive.read("PetAssist/PetAssist.lua").decode("utf-8")
        assert "PetAssist.lua" in archive.read("PetAssist/PetAssist.toc").decode("utf-8")
else:
    addon_source = (args.addon_source or root / "PetAssist.lua").read_text()
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().ADDON_SOURCE = addon_source
suite = (root / "tests" / "regression.lua").read_text()
lua.execute(suite)
fixture = suite.split("local passed = 0")[0]
for locale in ["enUS", "ruRU", "deDE", "frFR", "esES", "esMX", "ptBR", "itIT", "koKR", "zhCN", "zhTW"]:
    for player_class in ["HUNTER", "WARLOCK", "MAGE"]:
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.globals().ADDON_SOURCE = addon_source
        runtime.globals().TEST_LOCALE = locale
        runtime.globals().TEST_CLASS = player_class
        runtime.execute(fixture + """
            event("ADDON_LOADED", "PetAssist")
            event("PLAYER_ENTERING_WORLD")
            flush()
            command("config")
            command("status")
            command("report")
            if TEST_CLASS == "MAGE" then assert(not bindings["1"])
            else assert(bindings["1"]); command("test ActionButton1") end
        """)
print("Passed 33 initialization checks (11 locales, 3 classes)")

for saved_state in [
    "PetAssistDB = 'invalid'",
    "PetAssistDB = {blacklist={Fear=true, fear=true}, mode='invalid', stance='invalid', rules='invalid'}",
    "PetAssistDB = {enabled=false, blacklist={Fear=true}, mode='custom', stance='passive'}",
]:
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().ADDON_SOURCE = addon_source
    runtime.execute(fixture + saved_state + """
        event("ADDON_LOADED", "PetAssist")
        assert(type(PetAssistDB) == "table" and type(PetAssistDB.rules) == "table")
        assert(PetAssistDB.blacklist.Fear == nil)
        assert(PetAssistDB.schemaVersion == 1)
        event("PLAYER_ENTERING_WORLD")
        flush()
        if PetAssistDB.enabled then assert(bindings["1"])
        else assert(not bindings["1"] and PetAssistDB.stance == "passive") end
    """)
print("Passed 3 saved-settings migration checks")

for stored in [
    "PetAssistDB={debug=true}; PetAssistDebugDB={entries={'previous-session-marker'}}",
    "PetAssistDB={debug=false}; PetAssistDebugDB='invalid'",
]:
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().ADDON_SOURCE = addon_source
    runtime.execute(fixture + stored + """
        event("ADDON_LOADED", "PetAssist")
        command("report")
        local text = PetAssistDebugReport.edit:GetText()
        assert(type(PetAssistDebugDB) == "table" and #PetAssistDebugDB.entries <= 100)
        if PetAssistDB.debug then assert(text:find("previous-session-marker", 1, true))
        else assert(#PetAssistDebugDB.entries == 0) end
    """)
print("Passed 2 diagnostic persistence/repair checks")
