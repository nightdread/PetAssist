# PetAssist 1.7.0: Classic Era release checklist

The automated suite models native action execution. Basic Warlock damage casts and pet attacks have been confirmed on Classic Era 1.15.9 (build 70003), enUS, with Blizzard bars. The remaining real-client scenarios below are not claimed as completed by the suite.

# Forever experimental smoke (required before calling Forever “supported”)

Install into `_forever_` or `_classic_beta_`. Confirm `/dump select(4, GetBuildInfo())` is in the `16xxx` range and the addon loaded `PetAssist_Camelot.toc`.

1. SoftCC Fear/Banish (or Forever equivalents): pet Passive + Follow; spell still casts.
2. Damage ability keybind + mouse click: pet assist if Defensive does not already auto-send; no blocked-action spam.
3. `/pa stance assist` then damage cast: `/petassist` then `/petattack` when stance restore is on.
4. If chat reports secure wrapping unavailable: Recall key still works; bars do not double-wrap after `/reload`.
5. Settings tabs / rules / Howl-Frost opt-ins without Lua errors.

Do not mark Forever supported in release notes until items 1–4 pass on the target build.

Enable Lua errors (`/console scriptErrors 1`). Start with Blizzard bars and a Hunter or Warlock. Record `/pa test ActionButton1`, client build, locale, other addons, and key-down setting when reporting a failure.

1. **Secure execution in combat:** Put Corruption / a damage shot on a bar. Press its key and click with the mouse in combat. Both must cast once and send the pet. Check for blocked-action and taint errors. Verify that the short generated macro can `/click` the distinct `PetAssistAction_*` action-slot delegate on this Era build.
2. **SoftCC:** Cast Fear / Banish / Freezing Trap directly and through a simple `/cast` macro. The pet must go Passive + Follow, while the original spell casts once. Repeat while pressing Shift/Ctrl/Alt keybinds.
3. **Native macros:** Test a near-255-byte macro, a conditional macro, `/castsequence`, and a macro with its own `/petattack` or `/petfollow`. Default auto must leave ambiguous macros alone. Set an explicit rule on a long macro and verify it still executes its whole original body through nested `/click` -> native `UseAction` -> macro execution. Confirm conditionals and sequence state remain correct.
4. **Paging:** Put a damage spell on page 1 and Fear / Life Tap on page 2 in the same position. Switch pages during combat. Keys and clicks must execute the visible action and its appropriate pet policy. Repeat with bonus/possess bars if available. Empty slots must not send the pet.
5. **Ranks and native input:** Test a low-rank spell next to its highest rank. Mana use/cast must match the original slot. Test Attack / Auto Shot toggling and modified self-cast behavior. Shift-drag or place a spell with the cursor: no unintended pet command or lost cursor action.
6. **Click phase:** Repeat with ActionButtonUseKeyDown on and off. Blizzard bars currently use release for the override-binding and nested `/click` path regardless of the key-down preference. Verify exactly one cast/pet command per physical key or mouse click; test press/release while changing target and entering combat.
7. **Stance:** Choose Defensive, then Passive. After SoftCC, damage input must set the selected stance before attack. Turn stance restoration off. Friendly/dead/missing targets must not change stance or attack.
8. **Rules/options:** Add attack/recall/ignore rules through both UI and commands; clear them and verify defaults return. Test Howl/Frost opt-ins. Change options in combat and verify they apply after combat. Confirm all three settings tabs scroll correctly at supported UI scales in both English and Russian. Check mutually exclusive selections, saved-rule editing/removal, empty-name feedback, custom exclusion add/remove, and that switching tabs cancels Recall key capture.
9. **Recall:** After `/pa off` outside combat, check both damage and utility casts and verify no pet command is issued; repeat after `/reload`. Assign a used key and verify the conflict notice. Clear it and verify the previous action is restored. Start capturing a key, then close the options panel: normal keyboard input must resume. Repeat after `/reload`.
10. **Third-party bars:** Repeat damage, SoftCC, long macro, page changes, and disable/re-enable with Dominos, Bartender4, and ElvUI **separately**. Confirm their OnClick handlers accept the synthetic PetAssist button and execute the original action once; check right-click pet autocast. Non-action-slot custom buttons are not automatically classified.
11. **Persistence/classes/locales:** `/reload` preserves preferences and rules. Mage/other classes remain inactive. Check English/Russian settings; verify other locales fall back for new strings without Lua errors.

12. **Diagnostics:** With recording off, use abilities and verify the journal stays empty. Enable `/pa debug on`, reproduce a failed and a successful cast, and inspect `/pa report ActionButton2`; game error IDs and player cast outcomes must appear. Verify mouse/key casts with debug both on and off in combat, report copy/select/scroll/Escape behavior, and English/Russian Advanced settings. Reload and verify the bounded log survives. Debug off stops new entries; clear erases them. Confirm no character names or macro text appear. Attach Lua errors separately.

13. **Keep pet target — experimental, not yet verified in game:** On both supported classes, enable `/pa keeptarget on` out of combat. With the pet attacking living enemy A, change your target to enemy B and cast an eligible spell; confirm the player spell executes normally and PetAssist does not redirect the pet. Repeat while the pet is travelling to A, and record whether the client exposes `pettarget` immediately. Kill A, target B and cast again: confirm the pet attacks B when its old target is dead or absent. Repeat with a friendly, dead and absent player target; no attack or stance change should occur solely because of an invalid target. Use the native pet attack button or an explicit pet macro to redirect the pet manually. Cast Fear/Banish or a supported trap and confirm recall still works; then cast an eligible attack and verify stance restoration and a new attack order. Repeat with stance restoration off and with each available stance (Passive, Defensive, and Assist where supported); note any autonomous target changes caused by the stance. Change the option during combat and verify it takes effect after combat, then check persistence after `/reload`. Repeat in Forever before describing it as verified there. The Lua fixture checks generated commands, not actual game macro condition evaluation or pet AI.

Do not publish a release until the secure execution and original macro/cast checks pass on the target Classic Era client.
