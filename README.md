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

On Fear, Banish, Death Coil, Enslave Demon, Scare Beast, Freezing Trap, Wyvern Sting, Scatter Shot the addon runs:

```
/petpassive
/petfollow
/cast …
```

So the pet stops hitting and does not break your CC. The next damage spell sends it in again via PetAssist.

Toggle: options checkbox or `/pa softcc on|off` (default **on**).

**Note:** Howl of Terror and Frost Trap are opt-in (not default SoftCC). Seduction was removed from SoftCC (pet's own spell).

### Stance Restoration

When enabled (default **on**), normal assist spells automatically restore pet stance before attacking:

```
/petdefensive [pet,nomod]
/petattack [pet,@target,harm,nodead]
/cast …
```

This ensures your pet returns to a proper stance (e.g. Defensive) after SoftCC puts it on Passive.

Toggle: options checkbox or `/pa stance on|off`.

### Commands

| Command | Effect |
|--------|--------|
| `/petassist` or `/pa` | help |
| `/pa on` / `off` | enable / disable |
| `/pa refresh` | rebuild binds (out of combat) |
| `/pa config` | Esc → Options → AddOns → PetAssist |
| `/pa softcc on\|off` | SoftCC Guard (recall pet on Fear/Banish) |
| `/pa stance on\|off` | Stance restoration (restore /petdefensive before /petattack) |
| `/pa mode all\|harm\|custom` | when to send the pet |
| `/pa block SpellName` | add to custom blacklist |
| `/pa unblock SpellName` | remove from custom blacklist |
| `/pa recall SHIFT-F` | bind Recall (`/petpassive` + `/petfollow`) |
| `/pa recall clear` | clear Recall bind |
| `/pa test` | debug status (includes stance restore state) |
| `/pa status` | on/off + mode + stance restore |

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

- **Hunter and Warlock only:** The addon only activates for these two pet classes; shows a quiet message on other classes
- `/petattack` uses `[pet,@target,harm,nodead]` — no pet / friendly / dead target → no-op
- Casting Fear etc. in **harm** mode does not send the pet
- **Rank-correct casts:** Downranked spells on your bar cast the exact rank placed, not max rank

## Support

Classic Era (`## Interface: 11509`). Warlock / Hunter pets.

## Releasing (CurseForge)

Releases upload automatically when you push a version tag:

```bash
git tag v1.4.1
git push origin v1.4.1
```

Requires GitHub secret `CF_API_KEY` and `## X-Curse-Project-ID` in the `.toc`.
