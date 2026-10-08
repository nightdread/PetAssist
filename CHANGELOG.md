# Changelog

## 1.5.1

### Localization
- **Full Classic Era locale support:** Added translations for deDE (German), frFR (French), esES (Spanish - Spain), esMX (Spanish - Mexico), ptBR (Portuguese - Brazil), itIT (Italian), koKR (Korean), zhCN (Simplified Chinese), zhTW (Traditional Chinese)
- **Fallback system:** All locales fall back to English (enUS) for any missing strings
- **Structured for CurseForge:** Localization tables organized for future integration with CurseForge localization system
- **Note:** Asian locales (koKR, zhCN, zhTW) are draft translations; game terminology may need verification by native speakers

### Auto-Attack Detection
- **Locale-independent:** Fixed auto-attack detection to use spell ID 6603 instead of hardcoded string comparisons ("attack", "атака", etc.)
- **Classic Era compatible:** Uses spell ID check first, fallback to global ATTACK string for reliability
- **Eliminates bugs:** Now works correctly on all client languages without special-casing locale strings

## 1.5.0

### Features
- **Rank-correct casts:** Downranked spells on the action bar now cast the exact rank placed on the bar, not max rank
- **Restore pet stance after SoftCC:** New option (default ON) to restore pet stance (e.g. `/petdefensive`) before `/petattack` on normal spells after using SoftCC abilities
- **Class gate:** Addon now only activates for Hunter and Warlock; shows a single quiet message on other classes
- **Localization:** All user-facing strings now support English (default) and Russian (ruRU) via locale table

### Spell List Improvements
- **Added missing Hunter spells to block list:**
  - All Aspects (Hawk, Cheetah, Pack, Wild)
  - All Tracking abilities
  - Trueshot Aura, Rapid Fire, Deterrence, Disengage
  - Demon summons for Warlock
  - All Detect Invisibility ranks
- **SoftCC changes:**
  - Removed Seduction (pet's own spell; `/petfollow` interrupts it)
  - Howl of Terror and Frost Trap now opt-in via settings (not default)

### Performance & UX
- **Event debouncing:** `ACTIONBAR_SLOT_CHANGED` and similar events now debounced into one refresh (100ms delay)
- **UPDATE_MACROS registered:** Edited macros now automatically picked up
- **Reduced print noise:** Only prints on first login or explicit `/pa refresh`, not every world enter
- **Skip unnecessary post-combat refresh:** Only refreshes when `pendingRefresh` flag is set

### Commands
- New: `/pa stance on|off` — toggle stance restoration
- Updated: `/pa test` now shows stance restore status
- Updated: `/pa status` includes stance restore state

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
