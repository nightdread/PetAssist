# PetAssist

Warlock / Hunter pet helper for **Classic Era** and **WoW Forever** (experimental): SoftCC recall on Fear/Banish-style CC, optional `/petattack` with your cast, rules and Recall key. Separate CurseForge packages identify each client flavor.

## Why

In Classic Era, a pet on **Defensive** only joins after you (or the pet) take damage. Ranged openers leave the pet idle. Blizzard blocks `PetAttack()` from normal addon code, so PetAssist uses secure action-bar keybinds and OnClick wrappers instead. The wrapper issues the pet command, then uses `/click` to execute the original button. Spells and user macro bodies are never reconstructed or truncated.

On Forever, Defensive often auto-engages more like Assist; SoftCC and Recall remain the main value. Explicit assist and `/petattack` still help on Passive or when you want bar-driven send.

## Install

**Classic Era**

1. Copy the `PetAssist` folder into `World of Warcraft/_classic_era_/Interface/AddOns/`
2. Restart the game or `/reload`
3. Enable **PetAssist** on the character addon list if needed

**Forever** (experimental)

1. Copy the same `PetAssist` folder into `World of Warcraft/_forever_/Interface/AddOns/` or `_classic_beta_/Interface/AddOns/` (whichever your client uses)
2. Restart the game or `/reload`
3. Confirm the addon list shows Interface `16001` / Forever TOC (`PetAssist_Camelot.toc`)

## Usage

- In Forever, open PetAssist from the addon menu by the minimap, or use `/pa config`.
- Put an enemy on target and press your spells from the **action bar**
- The pet receives `/petattack` together with your cast (when the mode allows it)
- Default mode **harm**: pet is sent on damage/DoTs; Fear / Banish pull the pet back (**SoftCC Guard**)

### SoftCC Guard

On Fear, Banish, Death Coil, Enslave Demon, Scare Beast, Freezing Trap, Wyvern Sting, Scatter Shot the addon runs:

```
/petpassive
/petfollow
/cast …
```

So the pet stops hitting and does not break your CC. The next damage spell sends it in again via PetAssist.

Toggle: options checkbox or `/pa softcc on|off` (default **on**).

**Note:** Howl of Terror and Frost Trap are opt-in (options checkboxes or `/pa howl on` / `/pa frost on`; not default SoftCC). Seduction was removed from SoftCC (pet's own spell).

### Stance Restoration

When enabled (default **on**), normal assist spells automatically restore pet stance before attacking:

```
/petdefensive [pet,@target,harm,nodead]
/petattack [pet,@target,harm,nodead]
/cast …
```

Choose Defensive (default) or Passive in options, or use `/pa stance defensive|passive`. On Forever, **Assist** is also available (`/pa stance assist` → `/petassist`). This sets your preferred stance before assisting; it does not remember the previous stance. Mouse clicks and modifier keybinds use the same behavior. Friendly, dead or absent targets do not change stance.

Toggle: options checkbox or `/pa stance on|off`.

### Commands

| Command | Effect |
|--------|--------|
| `/petassist` or `/pa` | help |
| `/pa on` / `off` | enable / disable |
| `/pa refresh` | rebuild binds (out of combat) |
| `/pa config` | Esc → Options → AddOns → PetAssist |
| `/pa softcc on\|off` | SoftCC Guard (recall pet on Fear/Banish) |
| `/pa stance on\|off\|defensive\|passive` | Enable/disable preferred stance, or select it |
| `/pa keeptarget on\|off` | Avoid sending attack orders while the pet has a living target |
| `/pa howl on\|off` / `/pa frost on\|off` | Include Howl of Terror / Frost Trap in SoftCC |
| `/pa macros auto\|attack\|recall\|ignore` | Default behavior for macros |
| `/pa rule attack\|recall\|ignore\|clear Name` | Set/remove an explicit spell or macro rule |
| `/pa rules` | List saved rules |
| `/pa mode all\|harm\|custom` | when to send the pet |
| `/pa block SpellName` | add to custom blacklist |
| `/pa unblock SpellName` | remove from custom blacklist |
| `/pa recall SHIFT-F` | bind Recall (`/petpassive` + `/petfollow`) |
| `/pa recall clear` | clear Recall bind |
| `/pa test [ButtonName]` | Inspect an action button (default: ActionButton1): slot, spell ID, chosen/prepared policy and reason |
| `/pa status` | on/off + mode + stance restore |

### Modes

- **harm** (default) — pet on damage/DoTs/curses; **not** on Fear, Banish, stones, buffs, Life Tap
- **all** — spells and items, subject to SoftCC and explicit rules
- **custom** — everything except names you `/pa block`

### Spell and macro rules

Open **Esc → Options → AddOns → PetAssist** to manage the addon without chat commands. The settings are grouped into **General** (pet target, attack mode, Recall key and stance), **Advanced** (crowd-control protection and macro behavior), **Rules** (spell/macro overrides and custom exclusions), and **Diagnostics** (status, action-bar refresh, button checks and reports). Pages scroll on smaller settings windows. Selected choices are highlighted, and you can click anywhere on a choice to select it. Changes apply automatically, or after combat ends. Chat commands remain available as shortcuts.

In the Rules tab, enter a localized spell name / exact macro name, select a behavior and save. Click a saved rule to edit it; choose default behavior to remove it. Custom exclusions only apply in custom mode. You can also use chat commands:

```text
/pa rule recall Fear macro
/pa rule ignore Life Tap
/pa rule attack Corruption
/pa rule clear Corruption
/pa rules
```

Rules apply in every mode and take precedence over built-in SoftCC and utility lists. `clear` restores automatic behavior. A spell and macro with the same name share the rule. Name case matching uses Lua's lowercase conversion; for non-Latin names use the spelling shown by the client.

### Macro behavior

Default **auto** recognizes one unconditional `/cast SpellName` (optional rank and `#showtooltip` lines). Fear recalls the pet; damage spells assist; utility spells do not assist in harm mode. Unknown spells are ignored.

Conditional macros (`[mod:shift]`, `[@mouseover]`, `;`), `/castsequence`, `/use`, and macros with additional commands are left alone. Add an explicit macro rule to opt in. The default macro policy is separate from `all|harm|custom`; `all` does not force ambiguous macros to assist.

`/pa macros attack|recall|ignore` applies that default policy to macros without their own rule. A macro containing an explicit `/pet...` command always owns pet behavior: PetAssist leaves it alone, even when an attack/recall rule is set. Native macro execution and spell ranks are preserved. PetAssist's automatic target remains `@target`; it does not infer a conditional macro's selected target.

### Keep the pet's target (experimental)

Enable **General → Keep the pet on its current target (experimental)** or `/pa keeptarget on` to avoid issuing a new PetAssist attack order when the pet already has a living target. The option is off by default. When the pet has no target, or its target is dead, the next eligible action can send it to your current target. To switch targets intentionally, use the game's pet attack button or your own pet macro. SoftCC recall still takes priority. Changes made in combat apply after combat.

This limits only PetAssist's attack commands; pet stances, other addons, and manual commands may still affect the pet's target. If stance restoration is enabled, it still sets the selected stance for an eligible player target. The conditional macro needs validation in the real target client, especially when the pet's target dies or changes.

PetAssist sends commands on the input action; it cannot guarantee the spell was successfully cast. An invalid or out-of-range cast can therefore still trigger an attack order.

### Why didn't my pet attack?

- Check that PetAssist is enabled, you have a living pet, and your current target is a living enemy. PetAssist commands target `@target`, including when a macro casts at `@mouseover`.
- Crowd-control abilities may recall the pet instead. Afterward, an allowed attack action can send it in again, so be careful not to break your own crowd control.
- Complex macros are ignored by default. In **Rules**, add the exact macro name and choose attack, recall, or ignore. A macro with its own `/pet...` command still controls the pet itself.
- Settings changed in combat apply after combat. For an action-bar button, `/pa test ActionButton1` shows the selected policy and reason; replace the button name as needed. `/pa refresh` rebuilds bindings outside combat.
- Spellbook casts are not hooked. Use an action-bar button, and check the compatibility notes below for your client and bar addon.

## Reporting problems

1. Open **Diagnostics** in PetAssist settings and enable diagnostic recording (or use `/pa debug on`).
2. Reproduce the problem with the addon enabled; note the ability and whether you used the mouse or a key.
3. Press the affected action-bar button, then choose **Diagnostics → Last button** to inspect it and select it for the report. You can instead enter its name or use `/pa report ActionButton2`. Open the report and copy its selected text into a GitHub issue with your reproduction steps.
4. Turn off recording in **Diagnostics** when finished. The clear-log button erases the recorded events; `/pa debug off` and `/pa debug clear` are also available.

Reports include addon/client versions, locale, class, settings, detected bar addons, occupied action slots and the most recent 100 recorded events. Recording is off by default; its state and bounded journal survive `/reload`. Nothing is sent automatically. Character names, chat, macro bodies/names and custom rule names are omitted.

The last-button shortcut remembers the last connected action-bar button in the current session, even when recording is off. It does not remember the action itself: inspection uses the button's current page. After `/reload`, press a button again. Spellbook casts and buttons PetAssist has not connected cannot be selected this way; manual entry remains available.

Clicks are dispatch attempts; player spell start/success/failure events are recorded separately. Game error IDs and blocked/forbidden addon actions are included while recording. Lua error text is not intercepted: enable `/console scriptErrors 1` and attach the game's Lua error separately if one appears. Reports and debug toggles are available in combat without modifying protected action attributes.

## Recall

Bind a key (options UI or `/pa recall KEY`) to pull the pet back: Passive + Follow. Useful before CC or when the pet over-aggros. PetAssist reports the underlying binding it will override. Clearing Recall restores that binding after refresh (after combat if necessary).

## Compatibility

- Default Blizzard bars (keybinds + mouse)
- **Dominos**, **Bartender4**, **ElvUI** action buttons (secure OnClick; action-slot buttons)
- Spell/macro edits refresh automatically out of combat; `/pa refresh` can also rebuild rules
- Assisted actions use a separate secure action-slot delegate; they do not click back into the active macro button. Native slot execution is modeled in tests; real-client macro chaining and third-party bar handlers still require validation.
- Changing pages in combat reads the current secure action slot from the button; slot policies are prepared out of combat
- Option changes during combat take effect after combat
- Spellbook UI casts are not hooked — use the action bar

## Notes

- **Hunter and Warlock only:** The addon only activates for these two pet classes; shows a quiet message on other classes
- `/petattack` uses `[pet,@target,harm,nodead]` — no pet / friendly / dead target → no-op
- Casting Fear etc. in **harm** mode does not send the pet
- **Rank-correct casts:** Downranked spells on your bar cast the exact rank placed, not max rank

## Localization

Existing strings support all Classic Era client languages. New 1.6 controls and diagnostics are translated into English and Russian; other locales fall back to English for these additions:
- English (enUS)
- German (deDE)
- French (frFR)
- Spanish - Spain (esES)
- Spanish - Mexico (esMX)
- Portuguese - Brazil (ptBR)
- Italian (itIT)
- Russian (ruRU)
- Korean (koKR) *
- Simplified Chinese (zhCN) *
- Traditional Chinese (zhTW) *

\* Asian locale translations are drafts; game terminology verification by native speakers welcome.

## Support

| Client | TOC | Interface | Status |
|--------|-----|-----------|--------|
| Classic Era | `PetAssist.toc` | `11509` | Supported (see changelog confirmations) |
| Forever | `PetAssist_Camelot.toc` | `16001` | Experimental until in-game smoke passes |

Warlock / Hunter pets. Forever shares Mainline-family APIs; if secure OnClick snippets fail on a build, bar SoftCC/assist wrapping disables and a chat message explains it — the Recall key still works.

## Releasing (CurseForge)

The release workflow creates and validates separate `-classic.zip` and `-forever.zip` archives (packager maps `11509` → classic, `16001` → forever), then uploads them sequentially. Releases upload when you push a version tag:

```bash
git tag v1.9.2
git push origin v1.9.2
```

Requires GitHub secret `CF_API_KEY` and `## X-Curse-Project-ID` in the `.toc`.


## Development checks

```bash
python3 -m pip install lupa==2.8
python3 tests/run.py
```

The suite loads the full addon in Lua 5.1 with mocked WoW APIs, checks action dispatch, macro preservation, pet policies, paging, settings, key phases, and class/locale initialization. Restricted snippets receive only allowed frame methods. It does **not** emulate Blizzard taint propagation or validate `/click` macro execution in a real client. Run the [in-game checklist](tests/IN_GAME.md) before releasing.

Validate the installed file or packaged archive before delivering a build (with Lupa installed):

```sh
python tests/run.py --addon-source /path/to/Interface/AddOns/PetAssist/PetAssist.lua
python tests/run.py --archive /path/to/PetAssist.zip
```
