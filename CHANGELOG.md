# Changelog

## 1.4.0

- **SoftCC Guard:** Fear / Banish / Howl / Death Coil / Enslave / traps / Scare Beast → `/petpassive` + `/petfollow` with the cast (pet stops breaking CC)
- Toggle: options checkbox or `/pa softcc on|off` (default on)
- SoftCC overrides assist even in `all` mode

## 1.3.2

- Fixed: DoTs (Corruption, curses, Immolate) no longer skipped in `harm` mode
- `harm` now = everything except built-in CC/utility list (no broken `IsHarmfulSpell`)
- Clearer mode descriptions in options

## 1.3.1

- Options registered in Esc → Options → AddOns → **PetAssist**
- `/pa config` opens that panel

## 1.3.0

- **Modes:** `harm` (default), `all`, `custom` — control when the pet is sent
- **Built-in block list** for CC/utility (Fear, Banish, Death Coil, traps, create stones, Life Tap, etc.)
- **Dominos / Bartender4 / ElvUI** action button support via PreClick
- **Recall** bind: `/petpassive` + `/petfollow` (`/pa recall` or options UI)
- **Options window:** `/pa config`
- Smarter `/petattack [pet,@target,harm,nodead]` (skip if no pet / bad target)
- Items skipped in `harm` mode (no pet on Healthstone/trinket presses)
- Slash: `mode`, `block`, `unblock`, `recall`, `config`

## 1.2.3

- Fixed "You are too far away" spam: `/startattack` only on the Attack button, not on every spell

## 1.2.2

- Restored pet attack via secure `/petattack` macros on keybinds
- Keep auto-attack: use `/startattack` instead of `/cast Attack`, no key-up double-fire
- Empty action slots are no longer overridden

## 1.2.1

- Fixed auto-attack: proxies now use `type=action` instead of `/cast` macros
- Removed `typerelease` double-fire that toggled Attack off on key-up
- Pet attack runs once per keypress (respects ActionButtonUseKeyDown)

## 1.2.0

- Secure action-bar proxies with `/petattack` + spell/item/macro
- Keybind overrides via `SetOverrideBindingClick`
- PreClick wrap for mouse clicks on action buttons
- `/petassist test` and `refresh`

## 1.1.0

- Attempted secure WrapScript helpers (superseded by 1.2)

## 1.0.0

- Initial experiment (direct `PetAttack()` — blocked by Blizzard)
