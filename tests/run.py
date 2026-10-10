"""Run the addon regression suite with Lua 5.1 (pip install lupa==2.8)."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().ADDON_SOURCE = (root / "PetAssist.lua").read_text()
suite = (root / "tests" / "regression.lua").read_text()
lua.execute(suite)
fixture = suite.split("local passed = 0")[0]
for locale in ["enUS", "ruRU", "deDE", "frFR", "esES", "esMX", "ptBR", "itIT", "koKR", "zhCN", "zhTW"]:
    for player_class in ["HUNTER", "WARLOCK", "MAGE"]:
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.globals().ADDON_SOURCE = (root / "PetAssist.lua").read_text()
        runtime.globals().TEST_LOCALE = locale
        runtime.globals().TEST_CLASS = player_class
        runtime.execute(fixture + """
            event("ADDON_LOADED", "PetAssist")
            event("PLAYER_ENTERING_WORLD")
            flush()
            command("config")
            command("status")
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
    runtime.globals().ADDON_SOURCE = (root / "PetAssist.lua").read_text()
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
