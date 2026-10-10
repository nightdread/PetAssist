# PetAssist

Classic Era addon for Warlocks and Hunters: your pet attacks the same target as soon as you press an ability on the action bars — no waiting for the mob to hit you first (Defensive stance).

## Why

In Classic, a pet on **Defensive** only joins after you (or the pet) take damage. Ranged openers leave the pet idle. Blizzard blocks `PetAttack()` from normal addon code, so PetAssist uses secure action-bar keybinds and OnClick wrappers instead. The wrapper issues the pet command, then uses `/click` to execute the original button. Spells and user macro bodies are never reconstructed or truncated.

## Install

1. Copy the `PetAssist` folder into `World of Warcraft/_classic_era_/Interface/AddOns/`
2. Restart the game or `/reload`
3. Enable **PetAssist** on the character addon list if needed

## Usage

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

Choose Defensive (default) or Passive in options, or use `/pa stance defensive|passive`. This sets your preferred stance before assisting; it does not remember the previous stance. Mouse clicks and modifier keybinds use the same behavior. Friendly, dead or absent targets do not change stance.

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

Settings are grouped into **General** (attack mode, stance, Recall key), **Advanced** (crowd-control protection and macro behavior), and **Rules** (spell/macro overrides and custom exclusions). Pages scroll on smaller settings windows. Choices show the selected value; changes apply automatically, or after combat ends.

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

## Recall

Bind a key (options UI or `/pa recall KEY`) to pull the pet back: Passive + Follow. Useful before CC or when the pet over-aggros. PetAssist reports the underlying binding it will override. Clearing Recall restores that binding after refresh (after combat if necessary).

## Compatibility

- Default Blizzard bars (keybinds + mouse)
- **Dominos**, **Bartender4**, **ElvUI** action buttons (secure OnClick; action-slot buttons)
- Spell/macro edits refresh automatically out of combat; `/pa refresh` can also rebuild rules
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

Classic Era (`## Interface: 11509`). Warlock / Hunter pets.

## Releasing (CurseForge)

Releases upload automatically when you push a version tag:

```bash
git tag v1.6.1
git push origin v1.6.1
```

Requires GitHub secret `CF_API_KEY` and `## X-Curse-Project-ID` in the `.toc`.


## Development checks

```bash
python3 -m pip install lupa==2.8
python3 tests/run.py
```

The suite loads the full addon in Lua 5.1 with mocked WoW APIs, checks action dispatch, macro preservation, pet policies, paging, settings, key phases, and class/locale initialization. Restricted snippets receive only allowed frame methods. It does **not** emulate Blizzard taint propagation or validate `/click` macro execution in a real client. Run the [in-game checklist](tests/IN_GAME.md) before releasing.
