# PetAssist 1.6.0: Classic Era release checklist

The automated suite models native action execution. These real-client checks are still required; none are claimed as completed by the suite.

Enable Lua errors (`/console scriptErrors 1`). Start with Blizzard bars and a Hunter or Warlock. Record `/pa test ActionButton1`, client build, locale, other addons, and key-down setting when reporting a failure.

1. **Secure execution in combat:** Put Corruption / a damage shot on a bar. Press its key and click with the mouse in combat. Both must cast once and send the pet. Check for blocked-action and taint errors. Verify that the short generated macro can `/click` the original action button on this Era build.
2. **SoftCC:** Cast Fear / Banish / Freezing Trap directly and through a simple `/cast` macro. The pet must go Passive + Follow, while the original spell casts once. Repeat while pressing Shift/Ctrl/Alt keybinds.
3. **Native macros:** Test a near-255-byte macro, a conditional macro, `/castsequence`, and a macro with its own `/petattack` or `/petfollow`. Default auto must leave ambiguous macros alone. Set an explicit rule on a long macro and verify it still executes its whole original body through nested `/click` -> native `UseAction` -> macro execution. Confirm conditionals and sequence state remain correct.
4. **Paging:** Put a damage spell on page 1 and Fear / Life Tap on page 2 in the same position. Switch pages during combat. Keys and clicks must execute the visible action and its appropriate pet policy. Repeat with bonus/possess bars if available. Empty slots must not send the pet.
5. **Ranks and native input:** Test a low-rank spell next to its highest rank. Mana use/cast must match the original slot. Test Attack / Auto Shot toggling and modified self-cast behavior. Shift-drag or place a spell with the cursor: no unintended pet command or lost cursor action.
6. **Click phase:** Repeat with ActionButtonUseKeyDown on and off. Verify exactly one cast/pet command per physical key or mouse click; test press/release while changing target and entering combat.
7. **Stance:** Choose Defensive, then Passive. After SoftCC, damage input must set the selected stance before attack. Turn stance restoration off. Friendly/dead/missing targets must not change stance or attack.
8. **Rules/options:** Add attack/recall/ignore rules through both UI and commands; clear them and verify defaults return. Test Howl/Frost opt-ins. Change options in combat and verify they apply after combat. Confirm all controls fit the settings panel at supported UI scales.
9. **Recall:** Assign a used key and verify the conflict notice. Clear it and verify the previous action is restored. Start capturing a key, then close the options panel: normal keyboard input must resume. Repeat after `/reload`.
10. **Third-party bars:** Repeat damage, SoftCC, long macro, page changes, and disable/re-enable with Dominos, Bartender4, and ElvUI **separately**. Confirm their OnClick handlers accept the synthetic PetAssist button and execute the original action once; check right-click pet autocast. Non-action-slot custom buttons are not automatically classified.
11. **Persistence/classes/locales:** `/reload` preserves preferences and rules. Mage/other classes remain inactive. Check English/Russian settings; verify other locales fall back for new strings without Lua errors.

Do not publish a release until the secure execution and original macro/cast checks pass on the target Classic Era client.
