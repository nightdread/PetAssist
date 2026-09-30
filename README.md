# PetAssist

Classic Era addon for Warlocks and Hunters: your pet attacks the same target as soon as you press an ability on the action bars — no waiting for the mob to hit you first (Defensive stance).

## Why

In Classic, a pet on **Defensive** only joins after you (or the pet) take damage. Ranged openers leave the pet idle. Blizzard blocks `PetAttack()` from normal addon code, so PetAssist uses secure action-bar keybinds / PreClick wrappers instead.

## Install

1. Copy the `PetAssist` folder into `World of Warcraft/_classic_era_/Interface/AddOns/`
2. Restart the game or `/reload`
3. Enable **PetAssist** on the character addon list if needed

## Usage

- Put an enemy on target and press your spells from the **action bar**
- The pet receives `/petattack` together with your cast (when the mode allows it)
- Default mode **harm**: pet is sent on damage/DoTs; Fear / Banish pull the pet back (**SoftCC Guard**)

### SoftCC Guard

On Fear, Banish, Howl of Terror, Death Coil, Enslave Demon, Seduction, Scare Beast, Freezing/Frost Trap, Wyvern Sting, Scatter Shot the addon runs:

```
/petpassive
/petfollow
/cast …
```

So the pet stops hitting and does not break your CC. The next damage spell sends it in again via PetAssist.

Toggle: options checkbox or `/pa softcc on|off` (default **on**).

### Commands

| Command | Effect |
|--------|--------|
| `/petassist` or `/pa` | help |
| `/pa on` / `off` | enable / disable |
| `/pa refresh` | rebuild binds (out of combat) |
| `/pa config` | Esc → Options → AddOns → PetAssist |
| `/pa softcc on\|off` | SoftCC Guard (recall pet on Fear/Banish) |
| `/pa mode all\|harm\|custom` | when to send the pet |
| `/pa block SpellName` | add to custom blacklist |
| `/pa unblock SpellName` | remove from custom blacklist |
| `/pa recall SHIFT-F` | bind Recall (`/petpassive` + `/petfollow`) |
| `/pa recall clear` | clear Recall bind |
| `/pa test` | debug status |
| `/pa status` | on/off + mode |

### Modes

- **harm** (default) — pet on damage/DoTs/curses; **not** on Fear, Banish, stones, buffs, Life Tap
- **all** — every action-bar press (including Fear)
- **custom** — everything except names you `/pa block`

### Recall

Bind a key (options UI or `/pa recall KEY`) to pull the pet back: Passive + Follow. Useful before CC or when the pet over-aggros.

## Compatibility

- Default Blizzard bars (keybinds + mouse)
- **Dominos**, **Bartender4**, **ElvUI** action buttons (PreClick)
- After rearranging spells, `/pa refresh` out of combat (or leave combat)
- Spellbook UI casts are not hooked — use the action bar

## Notes

- `/petattack` uses `[pet,@target,harm,nodead]` — no pet / friendly / dead target → no-op
- Casting Fear etc. in **harm** mode does not send the pet

## Support

Classic Era (`## Interface: 11509`). Warlock / Hunter pets.
