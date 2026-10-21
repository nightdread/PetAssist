"""Run the addon regression suite with Lua 5.1 (pip install lupa==2.8)."""
from pathlib import Path
import argparse
from zipfile import ZipFile
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description="Validate the actual addon source or packaged release with Lua 5.1.")
inputs = parser.add_mutually_exclusive_group()
inputs.add_argument("--addon-source", type=Path, help="Validate an installed PetAssist.lua instead of the working copy")
inputs.add_argument("--archive", type=Path, help="Validate PetAssist package inside a ZIP")
args = parser.parse_args()
if args.archive:
    with ZipFile(args.archive) as archive:
        assert archive.testzip() is None, "Corrupt package"
        addon_source = archive.read("PetAssist/PetAssist.lua").decode("utf-8")
        era_toc = archive.read("PetAssist/PetAssist.toc").decode("utf-8")
        forever_toc = archive.read("PetAssist/PetAssist_Forever.toc").decode("utf-8")
        compat_source = archive.read("PetAssist/Forever/Compat.lua").decode("utf-8")
        assert "PetAssist.lua" in era_toc and "11509" in era_toc
        assert "Forever/Compat.lua" in forever_toc and "16001" in forever_toc
        assert "PetAssist.lua" in forever_toc
else:
    addon_source = (args.addon_source or root / "PetAssist.lua").read_text()
    compat_source = (root / "Forever" / "Compat.lua").read_text()
    assert "11509" in (root / "PetAssist.toc").read_text()
    forever_toc = (root / "PetAssist_Forever.toc").read_text()
    assert "16001" in forever_toc and "Forever/Compat.lua" in forever_toc

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

# Forever load path: Compat preload + Mainline-style spell API
forever = LuaRuntime(unpack_returned_tuples=True)
forever.globals().ADDON_SOURCE = addon_source
forever.globals().PRELOAD_SOURCE = compat_source
forever.globals().CLIENT_INTERFACE = 16001
forever.globals().FOREVER_ONLY = True
forever.execute(suite)
print("Passed Forever load-path checks")

# Forever secure-snippet failure fallback
snippet_fail = LuaRuntime(unpack_returned_tuples=True)
snippet_fail.globals().ADDON_SOURCE = addon_source
snippet_fail.globals().PRELOAD_SOURCE = compat_source
snippet_fail.globals().CLIENT_INTERFACE = 16001
snippet_fail.globals().FOREVER_ONLY = True
snippet_fail.globals().FORCE_SNIPPET_FAIL = True
snippet_fail.execute(suite)
print("Passed Forever snippet-failure fallback checks")
