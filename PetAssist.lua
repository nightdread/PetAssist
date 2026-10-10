--[[
  PetAssist 1.6.0 — Classic Era

  Secure OnClick selects a pet command, then /click executes the original button.
  Never copy spells or macro bodies: preserve ranks, conditionals,
  targeting, and action-bar paging. Slot policies are prepared out of combat.
]]

local ADDON_NAME = ...
local VERSION = "@project-version@"
-- Unpackaged working copy (placeholder not replaced by packager)
if VERSION:find("@", 1, true) then
  VERSION = "1.6.0"
end

local MODE_ALL = "all"
local MODE_HARM = "harm"
local MODE_CUSTOM = "custom"

-- Slot policies: 0 = none, 1 = petattack, 2 = SoftCC (passive+follow)
local PA_NONE = 0
local PA_ASSIST = 1
local PA_SOFTCC = 2

-- ===== Localization =====
-- This structure can be extracted to a separate file for CurseForge localization system.
-- All locales fall back to English (enUS) for missing strings.
local L = {}
local locale = GetLocale()

-- Locale table builder with fallback
local function BuildLocale(translations)
  for key, value in pairs(translations.enUS) do
    L[key] = value
  end
  
  if translations[locale] then
    for key, value in pairs(translations[locale]) do
      L[key] = value
    end
  end
end

-- Localization strings: enUS is default/fallback, all other locales override only what they define
local TRANSLATIONS = {
  enUS = {
    ADDON_READY = "v%s ready [%s]: buttons %d, keys %d, extra %d.",
    RESTORE_STANCE = "Set preferred pet stance before assisting",
    REASON_RULE = "explicit spell/macro rule",
    REASON_UNKNOWN = "unknown spell",
    REASON_SOFTCC = "SoftCC Guard",
    REASON_BLACKLIST = "custom blacklist",
    REASON_UTILITY = "utility or unsupported action",
    REASON_MODE = "assist mode",
    REASON_EMPTY = "empty action",
    REASON_MACRO_PET = "macro controls its own pet",
    REASON_MACRO_POLICY = "default macro policy",
    REASON_MACRO_COMPLEX = "complex macro: choose an explicit rule",
    STANCE_BUTTON = "Preferred stance: %s",
    MACRO_BUTTON = "Macros: %s",
    HOWL_OPTION = "Recall on Howl of Terror",
    FROST_OPTION = "Recall on Frost Trap",
    RULE_USAGE = "Usage: /pa rule attack|recall|ignore|clear SpellOrMacroName",
    RULE_SAVED = "%s: %s",
    RULE_NAME_HINT = "Spell or macro name",
    RULE_APPLY = "Apply rule",
    RULE_ACTION = "Rule: %s",
    RULE_LIST = "%s = %s",
    RECALL_CONFLICT = "Recall overrides %s on %s.",
    TEST_BAD_BUTTON = "Unknown action button: %s",
    TEST_DETAIL = "%s | slot=%s | type=%s | id=%s | name=%s | policy=%s | prepared=%s | reason=%s | pending=%s | combat=%s",
    TEST_NATIVE = "Original button executes unchanged | wrapped=%s | stance=%s | macros=%s",
    SLASH_HELP = "Commands: on|off|refresh|test [ButtonName]|status|config|mode|softcc|stance|macros|howl|frost|rule|rules|block|unblock|recall",
    OPTION_USAGE = "Usage: /pa %s on|off",
    MACRO_USAGE = "Usage: /pa macros auto|attack|recall|ignore",
    STANCE_USAGE = "Usage: /pa stance on|off|passive|defensive",
    ENABLED = "Enabled",
    REFRESH_AFTER_COMBAT = "refresh after combat…",
    SOFTCC_GUARD = "SoftCC Guard — recall pet on Fear/Banish (passive+follow)",
    MODE_ALL_DESC = "all — pet on EVERY button (including Fear)",
    MODE_CUSTOM_DESC = "custom — pet always, except /pa block",
    MODE_HARM_DESC = "harm — pet on damage/DoTs, NOT on Fear/stones/buffs",
    MODE_LABEL = "Mode:",
    MODE_ALL_HINT = "Pet goes even on Life Tap / stones. SoftCC still recalls on Fear.",
    MODE_CUSTOM_HINT = "Custom list: /pa block Name  |  /pa unblock Name",
    MODE_HARM_HINT = "Corruption, curses, SB — yes. Fear/Banish — SoftCC (passive+follow). Stones — no.",
    RECALL_LABEL = "Recall (pet recall):",
    RECALL_UNBOUND = "not bound",
    CUSTOM_BLACKLIST = "Custom blacklist: %d names (custom mode only)",
    BIND_RECALL = "Bind Recall",
    PRESS_KEY = "Press a key…",
    CLEAR = "Clear",
    RECALL_CLEARED = "Recall bind cleared.",
    REFRESH = "Refresh",
    SLASH_HINT = "/pa softcc on|off  |  /pa block Fear  |  /pa mode harm",
    ESCAPE_OPTIONS = "Esc → Options → AddOns → PetAssist",
    SUBTITLE = "Pet attacks your target with your cast (Warlock / Hunter)",
    ADDON_DISABLED = "disabled.",
    SOFTCC_ON = "SoftCC enabled.",
    SOFTCC_OFF = "SoftCC disabled.",
    STANCE_RESTORE_ON = "Stance restore enabled.",
    STANCE_RESTORE_OFF = "Stance restore disabled.",
    MODE_CHANGED = "mode → %s",
    USAGE_MODE = "Usage: /pa mode all|harm|custom (current: %s)",
    USAGE_BLOCK = "Usage: /pa block SpellName",
    BLOCK_ADDED = "Added to blacklist. Enable custom: /pa mode custom",
    BLOCKED = "block: %s",
    USAGE_UNBLOCK = "Usage: /pa unblock SpellName",
    UNBLOCKED = "unblock: %s",
    RECALL_BIND_USAGE = "Recall bind cleared. To bind: /pa recall SHIFT-F",
    RECALL_BOUND = "Recall → %s (/petpassive + /petfollow)",
    STATUS_OUTPUT = "%s | %s | SoftCC %s | stance restore %s",
    STATUS_ENABLED = "enabled v%s",
    STATUS_DISABLED = "disabled",
    SLASH_MODE_STATUS = "Mode: %s | SoftCC: %s | Stance restore: %s",
    UNKNOWN_COMMAND = "Unknown command. /pa help",
    CANNOT_BIND_COMBAT = "cannot change bind in combat.",
    SOFTCC_TOGGLE = "SoftCC → %s",
    SOFTCC_ON_DESC = "on (Fear/Banish recall pet)",
    SOFTCC_OFF_DESC = "off",
    STANCE_TOGGLE = "Stance restore → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: only for Hunter and Warlock.",
  },
  
  ruRU = {
    ADDON_READY = "v%s готов [%s]: кнопок %d, клавиш %d, сторонних %d.",
    RESTORE_STANCE = "Устанавливать выбранную стойку перед атакой питомца",
    REASON_RULE = "правило способности/макроса",
    REASON_UNKNOWN = "неизвестное заклинание",
    REASON_SOFTCC = "SoftCC Guard",
    REASON_BLACKLIST = "свой список исключений",
    REASON_UTILITY = "служебное или неподдерживаемое действие",
    REASON_MODE = "режим помощи",
    REASON_EMPTY = "пустая кнопка",
    REASON_MACRO_PET = "макрос сам управляет питомцем",
    REASON_MACRO_POLICY = "общее правило макросов",
    REASON_MACRO_COMPLEX = "сложный макрос: назначь отдельное правило",
    STANCE_BUTTON = "Стойка питомца: %s",
    MACRO_BUTTON = "Макросы: %s",
    HOWL_OPTION = "Отзывать при Вое ужаса",
    FROST_OPTION = "Отзывать при Ледяной ловушке",
    RULE_USAGE = "Использование: /pa rule attack|recall|ignore|clear ИмяСпособностиИлиМакроса",
    RULE_SAVED = "%s: %s",
    RULE_NAME_HINT = "Имя способности или макроса",
    RULE_APPLY = "Применить правило",
    RULE_ACTION = "Правило: %s",
    RULE_LIST = "%s = %s",
    RECALL_CONFLICT = "Отзыв перекрывает %s на клавише %s.",
    TEST_BAD_BUTTON = "Неизвестная кнопка: %s",
    TEST_DETAIL = "%s | слот=%s | тип=%s | ID=%s | имя=%s | правило=%s | подготовлено=%s | причина=%s | ожидает=%s | бой=%s",
    TEST_NATIVE = "Исходная кнопка выполняется без изменений | подключена=%s | стойка=%s | макросы=%s",
    SLASH_HELP = "Команды: on|off|refresh|test [ИмяКнопки]|status|config|mode|softcc|stance|macros|howl|frost|rule|rules|block|unblock|recall",
    OPTION_USAGE = "Использование: /pa %s on|off",
    MACRO_USAGE = "Использование: /pa macros auto|attack|recall|ignore",
    STANCE_USAGE = "Использование: /pa stance on|off|passive|defensive",
    ENABLED = "Включён",
    REFRESH_AFTER_COMBAT = "обновление после боя…",
    SOFTCC_GUARD = "SoftCC Guard — на Fear/Banish отзывать пета (passive+follow)",
    MODE_ALL_DESC = "all — пет на КАЖДУЮ кнопку (включая Fear)",
    MODE_CUSTOM_DESC = "custom — пет всегда, кроме /pa block",
    MODE_HARM_DESC = "harm — пет на урон/DoT, НЕ на Fear/камни/баффы",
    MODE_LABEL = "Режим:",
    MODE_ALL_HINT = "Пет полетит даже от Life Tap / камней. SoftCC всё равно отзовёт на Fear.",
    MODE_CUSTOM_HINT = "Свой список: /pa block Имя  |  /pa unblock Имя",
    MODE_HARM_HINT = "Corruption, курсы, SB — да. Fear/Banish — SoftCC (passive+follow). Камни — нет.",
    RECALL_LABEL = "Recall (отзыв пета):",
    RECALL_UNBOUND = "не назначен",
    CUSTOM_BLACKLIST = "Custom blacklist: %d имён (только для режима custom)",
    BIND_RECALL = "Назначить Recall",
    PRESS_KEY = "Нажми клавишу…",
    CLEAR = "Сброс",
    RECALL_CLEARED = "Recall бинд сброшен.",
    SUBTITLE = "Питомец атакует цель вместе с твоим кастом (Warlock / Hunter)",
    ADDON_DISABLED = "выключен.",
    SOFTCC_ON = "SoftCC включён.",
    SOFTCC_OFF = "SoftCC выключен.",
    STANCE_RESTORE_ON = "Восстановление стойки включено.",
    STANCE_RESTORE_OFF = "Восстановление стойки выключено.",
    MODE_CHANGED = "режим → %s",
    USAGE_MODE = "Использование: /pa mode all|harm|custom (сейчас: %s)",
    USAGE_BLOCK = "Использование: /pa block ИмяСпелла",
    BLOCK_ADDED = "Добавлено в blacklist. Включи custom: /pa mode custom",
    BLOCKED = "block: %s",
    USAGE_UNBLOCK = "Использование: /pa unblock ИмяСпелла",
    UNBLOCKED = "unblock: %s",
    RECALL_BIND_USAGE = "Recall бинд сброшен. Назначить: /pa recall SHIFT-F",
    RECALL_BOUND = "Recall → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "включён v%s",
    STATUS_DISABLED = "выключен",
    SLASH_MODE_STATUS = "Режим: %s | SoftCC: %s | Восстановление стойки: %s",
    UNKNOWN_COMMAND = "Неизвестная команда. /pa help",
    CANNOT_BIND_COMBAT = "нельзя менять бинд в бою.",
    SOFTCC_ON_DESC = "on (Fear/Banish отзывают пета)",
    STANCE_TOGGLE = "Восстановление стойки → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: только для Охотника и Чернокнижника.",
  },
  
  deDE = {
    ENABLED = "Aktiviert",
    REFRESH_AFTER_COMBAT = "Aktualisierung nach dem Kampf…",
    SOFTCC_GUARD = "SoftCC-Wächter — ruft Begleiter bei Furcht/Verbannung zurück (passiv+folgen)",
    MODE_ALL_DESC = "all — Begleiter auf JEDER Taste (einschl. Furcht)",
    MODE_CUSTOM_DESC = "custom — Begleiter immer, außer /pa block",
    MODE_HARM_DESC = "harm — Begleiter auf Schaden/DoTs, NICHT auf Furcht/Steine/Buffs",
    MODE_LABEL = "Modus:",
    MODE_ALL_HINT = "Begleiter greift auch bei Aderlass / Steinen an. SoftCC ruft trotzdem bei Furcht zurück.",
    MODE_CUSTOM_HINT = "Eigene Liste: /pa block Name  |  /pa unblock Name",
    MODE_HARM_HINT = "Verderbnis, Flüche, Schattenblitz — ja. Furcht/Verbannung — SoftCC (passiv+folgen). Steine — nein.",
    RECALL_LABEL = "Rückruf (Begleiterrückruf):",
    RECALL_UNBOUND = "nicht belegt",
    CUSTOM_BLACKLIST = "Eigene Sperrliste: %d Namen (nur im Modus custom)",
    BIND_RECALL = "Rückruf belegen",
    PRESS_KEY = "Taste drücken…",
    CLEAR = "Löschen",
    RECALL_CLEARED = "Rückruf-Belegung gelöscht.",
    REFRESH = "Aktualisieren",
    SUBTITLE = "Begleiter greift dein Ziel mit deinem Zauber an (Hexenmeister / Jäger)",
    ADDON_DISABLED = "deaktiviert.",
    SOFTCC_ON = "SoftCC aktiviert.",
    SOFTCC_OFF = "SoftCC deaktiviert.",
    STANCE_RESTORE_ON = "Haltungswiederherstellung aktiviert.",
    STANCE_RESTORE_OFF = "Haltungswiederherstellung deaktiviert.",
    MODE_CHANGED = "Modus → %s",
    USAGE_MODE = "Verwendung: /pa mode all|harm|custom (aktuell: %s)",
    USAGE_BLOCK = "Verwendung: /pa block Zaubername",
    BLOCK_ADDED = "Zur Sperrliste hinzugefügt. Custom aktivieren: /pa mode custom",
    BLOCKED = "gesperrt: %s",
    USAGE_UNBLOCK = "Verwendung: /pa unblock Zaubername",
    UNBLOCKED = "entsperrt: %s",
    RECALL_BIND_USAGE = "Rückruf-Belegung gelöscht. Zum Belegen: /pa recall SHIFT-F",
    RECALL_BOUND = "Rückruf → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "aktiviert v%s",
    STATUS_DISABLED = "deaktiviert",
    SLASH_HELP = "Befehle: on|off|refresh|test|status|config|mode|softcc|stance|block|unblock|recall",
    SLASH_MODE_STATUS = "Modus: %s | SoftCC: %s | Haltungswiederherstellung: %s",
    UNKNOWN_COMMAND = "Unbekannter Befehl. /pa help",
    CANNOT_BIND_COMBAT = "Belegung kann im Kampf nicht geändert werden.",
    SOFTCC_ON_DESC = "an (Furcht/Verbannung ruft Begleiter zurück)",
    STANCE_TOGGLE = "Haltungswiederherstellung → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: nur für Jäger und Hexenmeister.",
  },
  
  frFR = {
    ENABLED = "Activé",
    REFRESH_AFTER_COMBAT = "actualisation après le combat…",
    SOFTCC_GUARD = "Garde SoftCC — rappelle le familier sur Peur/Bannissement (passif+suivre)",
    MODE_ALL_DESC = "all — familier sur CHAQUE bouton (y compris Peur)",
    MODE_CUSTOM_DESC = "custom — familier toujours, sauf /pa block",
    MODE_HARM_DESC = "harm — familier sur dégâts/DoTs, PAS sur Peur/pierres/buffs",
    MODE_LABEL = "Mode :",
    MODE_ALL_HINT = "Le familier attaque même sur Connexion / pierres. SoftCC rappelle quand même sur Peur.",
    MODE_CUSTOM_HINT = "Liste personnalisée : /pa block Nom  |  /pa unblock Nom",
    MODE_HARM_HINT = "Corruption, malédictions, Trait — oui. Peur/Bannissement — SoftCC (passif+suivre). Pierres — non.",
    RECALL_LABEL = "Rappel (rappel du familier) :",
    RECALL_UNBOUND = "non lié",
    CUSTOM_BLACKLIST = "Liste noire personnalisée : %d noms (mode custom uniquement)",
    BIND_RECALL = "Lier le rappel",
    PRESS_KEY = "Appuyer sur une touche…",
    CLEAR = "Effacer",
    RECALL_CLEARED = "Liaison de rappel effacée.",
    REFRESH = "Actualiser",
    SUBTITLE = "Le familier attaque votre cible avec votre sort (Démoniste / Chasseur)",
    ADDON_DISABLED = "désactivé.",
    SOFTCC_ON = "SoftCC activé.",
    SOFTCC_OFF = "SoftCC désactivé.",
    STANCE_RESTORE_ON = "Restauration de posture activée.",
    STANCE_RESTORE_OFF = "Restauration de posture désactivée.",
    MODE_CHANGED = "mode → %s",
    USAGE_MODE = "Usage : /pa mode all|harm|custom (actuel : %s)",
    USAGE_BLOCK = "Usage : /pa block NomDuSort",
    BLOCK_ADDED = "Ajouté à la liste noire. Activer custom : /pa mode custom",
    BLOCKED = "bloqué : %s",
    USAGE_UNBLOCK = "Usage : /pa unblock NomDuSort",
    UNBLOCKED = "débloqué : %s",
    RECALL_BIND_USAGE = "Liaison de rappel effacée. Pour lier : /pa recall SHIFT-F",
    RECALL_BOUND = "Rappel → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "activé v%s",
    STATUS_DISABLED = "désactivé",
    SLASH_HELP = "Commandes : on|off|refresh|test|status|config|mode|softcc|stance|block|unblock|recall",
    SLASH_MODE_STATUS = "Mode : %s | SoftCC : %s | Restauration de posture : %s",
    UNKNOWN_COMMAND = "Commande inconnue. /pa help",
    CANNOT_BIND_COMBAT = "impossible de changer la liaison en combat.",
    SOFTCC_ON_DESC = "activé (Peur/Bannissement rappelle le familier)",
    STANCE_TOGGLE = "Restauration de posture → %s",
    CLASS_NOT_SUPPORTED = "PetAssist : uniquement pour Chasseur et Démoniste.",
  },
  
  esES = {
    ENABLED = "Activado",
    REFRESH_AFTER_COMBAT = "actualización después del combate…",
    SOFTCC_GUARD = "Guardia SoftCC — recuerda la mascota en Miedo/Destierro (pasivo+seguir)",
    MODE_ALL_DESC = "all — mascota en CADA botón (incluido Miedo)",
    MODE_CUSTOM_DESC = "custom — mascota siempre, excepto /pa block",
    MODE_HARM_DESC = "harm — mascota en daño/DoTs, NO en Miedo/piedras/buffs",
    MODE_LABEL = "Modo:",
    MODE_ALL_HINT = "La mascota va incluso con Transfusión / piedras. SoftCC aún así recuerda en Miedo.",
    MODE_CUSTOM_HINT = "Lista personalizada: /pa block Nombre  |  /pa unblock Nombre",
    MODE_HARM_HINT = "Corrupción, maldiciones, Descarga — sí. Miedo/Destierro — SoftCC (pasivo+seguir). Piedras — no.",
    RECALL_LABEL = "Recuerdo (recuerdo de mascota):",
    RECALL_UNBOUND = "sin asignar",
    CUSTOM_BLACKLIST = "Lista negra personalizada: %d nombres (solo modo custom)",
    BIND_RECALL = "Asignar recuerdo",
    PRESS_KEY = "Pulsa una tecla…",
    CLEAR = "Limpiar",
    RECALL_CLEARED = "Asignación de recuerdo limpiada.",
    REFRESH = "Actualizar",
    SUBTITLE = "La mascota ataca tu objetivo con tu lanzamiento (Brujo / Cazador)",
    ADDON_DISABLED = "desactivado.",
    SOFTCC_ON = "SoftCC activado.",
    SOFTCC_OFF = "SoftCC desactivado.",
    STANCE_RESTORE_ON = "Restauración de postura activada.",
    STANCE_RESTORE_OFF = "Restauración de postura desactivada.",
    MODE_CHANGED = "modo → %s",
    USAGE_MODE = "Uso: /pa mode all|harm|custom (actual: %s)",
    USAGE_BLOCK = "Uso: /pa block NombreDeHechizo",
    BLOCK_ADDED = "Añadido a la lista negra. Activar custom: /pa mode custom",
    BLOCKED = "bloqueado: %s",
    USAGE_UNBLOCK = "Uso: /pa unblock NombreDeHechizo",
    UNBLOCKED = "desbloqueado: %s",
    RECALL_BIND_USAGE = "Asignación de recuerdo limpiada. Para asignar: /pa recall SHIFT-F",
    RECALL_BOUND = "Recuerdo → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "activado v%s",
    STATUS_DISABLED = "desactivado",
    SLASH_HELP = "Comandos: on|off|refresh|test|status|config|mode|softcc|stance|block|unblock|recall",
    SLASH_MODE_STATUS = "Modo: %s | SoftCC: %s | Restauración de postura: %s",
    UNKNOWN_COMMAND = "Comando desconocido. /pa help",
    CANNOT_BIND_COMBAT = "no se puede cambiar asignación en combate.",
    SOFTCC_ON_DESC = "activado (Miedo/Destierro recuerda la mascota)",
    STANCE_TOGGLE = "Restauración de postura → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: solo para Cazador y Brujo.",
  },
  
  esMX = {
    -- Mexican Spanish: mostly same as esES with minor regional differences
    ENABLED = "Activado",
    SUBTITLE = "La mascota ataca tu objetivo con tu lanzamiento (Brujo / Cazador)",
    CLASS_NOT_SUPPORTED = "PetAssist: solo para Cazador y Brujo.",
  },
  
  ptBR = {
    ENABLED = "Ativado",
    REFRESH_AFTER_COMBAT = "atualização após o combate…",
    SOFTCC_GUARD = "Guarda SoftCC — chama mascote em Medo/Banimento (passivo+seguir)",
    MODE_ALL_DESC = "all — mascote em CADA botão (incluindo Medo)",
    MODE_CUSTOM_DESC = "custom — mascote sempre, exceto /pa block",
    MODE_HARM_DESC = "harm — mascote em dano/DoTs, NÃO em Medo/pedras/buffs",
    MODE_LABEL = "Modo:",
    MODE_ALL_HINT = "Mascote vai até em Drenar Vida / pedras. SoftCC ainda assim chama em Medo.",
    MODE_CUSTOM_HINT = "Lista personalizada: /pa block Nome  |  /pa unblock Nome",
    MODE_HARM_HINT = "Corrupção, maldições, Seta — sim. Medo/Banimento — SoftCC (passivo+seguir). Pedras — não.",
    RECALL_LABEL = "Chamar (chamar mascote):",
    RECALL_UNBOUND = "não atribuído",
    CUSTOM_BLACKLIST = "Lista negra personalizada: %d nomes (apenas modo custom)",
    BIND_RECALL = "Atribuir chamada",
    PRESS_KEY = "Pressione uma tecla…",
    CLEAR = "Limpar",
    RECALL_CLEARED = "Atribuição de chamada limpa.",
    REFRESH = "Atualizar",
    SUBTITLE = "A mascote ataca seu alvo com seu lançamento (Bruxo / Caçador)",
    ADDON_DISABLED = "desativado.",
    SOFTCC_ON = "SoftCC ativado.",
    SOFTCC_OFF = "SoftCC desativado.",
    STANCE_RESTORE_ON = "Restauração de postura ativada.",
    STANCE_RESTORE_OFF = "Restauração de postura desativada.",
    MODE_CHANGED = "modo → %s",
    USAGE_MODE = "Uso: /pa mode all|harm|custom (atual: %s)",
    USAGE_BLOCK = "Uso: /pa block NomeDaHabilidade",
    BLOCK_ADDED = "Adicionado à lista negra. Ativar custom: /pa mode custom",
    BLOCKED = "bloqueado: %s",
    USAGE_UNBLOCK = "Uso: /pa unblock NomeDaHabilidade",
    UNBLOCKED = "desbloqueado: %s",
    RECALL_BIND_USAGE = "Atribuição de chamada limpa. Para atribuir: /pa recall SHIFT-F",
    RECALL_BOUND = "Chamar → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "ativado v%s",
    STATUS_DISABLED = "desativado",
    SLASH_HELP = "Comandos: on|off|refresh|test|status|config|mode|softcc|stance|block|unblock|recall",
    SLASH_MODE_STATUS = "Modo: %s | SoftCC: %s | Restauração de postura: %s",
    UNKNOWN_COMMAND = "Comando desconhecido. /pa help",
    CANNOT_BIND_COMBAT = "não pode mudar atribuição em combate.",
    SOFTCC_ON_DESC = "ativado (Medo/Banimento chama a mascote)",
    STANCE_TOGGLE = "Restauração de postura → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: apenas para Caçador e Bruxo.",
  },
  
  itIT = {
    ENABLED = "Attivato",
    REFRESH_AFTER_COMBAT = "aggiornamento dopo il combattimento…",
    SOFTCC_GUARD = "Guardia SoftCC — richiama mascotte su Paura/Esilio (passivo+segui)",
    MODE_ALL_DESC = "all — mascotte su OGNI pulsante (incluso Paura)",
    MODE_CUSTOM_DESC = "custom — mascotte sempre, eccetto /pa block",
    MODE_HARM_DESC = "harm — mascotte su danno/DoTs, NON su Paura/pietre/buff",
    MODE_LABEL = "Modalità:",
    MODE_ALL_HINT = "La mascotte va anche su Salasso / pietre. SoftCC richiama comunque su Paura.",
    MODE_CUSTOM_HINT = "Lista personalizzata: /pa block Nome  |  /pa unblock Nome",
    MODE_HARM_HINT = "Corruzione, maledizioni, Freccia — sì. Paura/Esilio — SoftCC (passivo+segui). Pietre — no.",
    RECALL_LABEL = "Richiamo (richiamo mascotte):",
    RECALL_UNBOUND = "non assegnato",
    CUSTOM_BLACKLIST = "Lista nera personalizzata: %d nomi (solo modalità custom)",
    BIND_RECALL = "Assegna richiamo",
    PRESS_KEY = "Premi un tasto…",
    CLEAR = "Cancella",
    RECALL_CLEARED = "Assegnazione richiamo cancellata.",
    REFRESH = "Aggiorna",
    SUBTITLE = "La mascotte attacca il tuo bersaglio con il tuo lancio (Stregone / Cacciatore)",
    ADDON_DISABLED = "disattivato.",
    SOFTCC_ON = "SoftCC attivato.",
    SOFTCC_OFF = "SoftCC disattivato.",
    STANCE_RESTORE_ON = "Ripristino postura attivato.",
    STANCE_RESTORE_OFF = "Ripristino postura disattivato.",
    MODE_CHANGED = "modalità → %s",
    USAGE_MODE = "Uso: /pa mode all|harm|custom (attuale: %s)",
    USAGE_BLOCK = "Uso: /pa block NomeIncantesimo",
    BLOCK_ADDED = "Aggiunto alla lista nera. Attiva custom: /pa mode custom",
    BLOCKED = "bloccato: %s",
    USAGE_UNBLOCK = "Uso: /pa unblock NomeIncantesimo",
    UNBLOCKED = "sbloccato: %s",
    RECALL_BIND_USAGE = "Assegnazione richiamo cancellata. Per assegnare: /pa recall SHIFT-F",
    RECALL_BOUND = "Richiamo → %s (/petpassive + /petfollow)",
    STATUS_ENABLED = "attivato v%s",
    STATUS_DISABLED = "disattivato",
    SLASH_HELP = "Comandi: on|off|refresh|test|status|config|mode|softcc|stance|block|unblock|recall",
    SLASH_MODE_STATUS = "Modalità: %s | SoftCC: %s | Ripristino postura: %s",
    UNKNOWN_COMMAND = "Comando sconosciuto. /pa help",
    CANNOT_BIND_COMBAT = "impossibile cambiare assegnazione in combattimento.",
    SOFTCC_ON_DESC = "attivato (Paura/Esilio richiama la mascotte)",
    STANCE_TOGGLE = "Ripristino postura → %s",
    CLASS_NOT_SUPPORTED = "PetAssist: solo per Cacciatore e Stregone.",
  },
  
  -- Asian locales: marked as draft translations (game-terminology may need verification)
  koKR = {
    -- Korean (draft)
    ENABLED = "활성화",
    REFRESH_AFTER_COMBAT = "전투 후 새로고침…",
    SOFTCC_GUARD = "SoftCC 가드 — 공포/추방 시 소환수 회수 (수동+따라가기)",
    MODE_ALL_DESC = "all — 모든 버튼에 소환수 (공포 포함)",
    MODE_CUSTOM_DESC = "custom — 항상 소환수, /pa block 제외",
    MODE_HARM_DESC = "harm — 피해/DoT에만 소환수, 공포/돌/버프는 제외",
    MODE_LABEL = "모드:",
    SUBTITLE = "소환수가 시전과 함께 대상 공격 (흑마법사 / 사냥꾼)",
    ADDON_DISABLED = "비활성화됨.",
    SOFTCC_ON = "SoftCC 활성화됨.",
    SOFTCC_OFF = "SoftCC 비활성화됨.",
    STANCE_RESTORE_ON = "태세 복원 활성화됨.",
    STANCE_RESTORE_OFF = "태세 복원 비활성화됨.",
    CLASS_NOT_SUPPORTED = "PetAssist: 사냥꾼과 흑마법사 전용.",
  },
  
  zhCN = {
    -- Simplified Chinese (draft)
    ENABLED = "已启用",
    REFRESH_AFTER_COMBAT = "战斗后刷新…",
    SOFTCC_GUARD = "SoftCC 守护 — 恐惧/放逐时召回宠物 (被动+跟随)",
    MODE_ALL_DESC = "all — 每个按钮都发宠物 (包括恐惧)",
    MODE_CUSTOM_DESC = "custom — 总是发宠物, 除了 /pa block",
    MODE_HARM_DESC = "harm — 伤害/DoT 发宠物, 恐惧/石头/增益不发",
    MODE_LABEL = "模式:",
    SUBTITLE = "宠物随你的施法攻击目标 (术士 / 猎人)",
    ADDON_DISABLED = "已禁用。",
    SOFTCC_ON = "SoftCC 已启用。",
    SOFTCC_OFF = "SoftCC 已禁用。",
    STANCE_RESTORE_ON = "姿态恢复已启用。",
    STANCE_RESTORE_OFF = "姿态恢复已禁用。",
    CLASS_NOT_SUPPORTED = "PetAssist: 仅限猎人和术士。",
  },
  
  zhTW = {
    -- Traditional Chinese (draft)
    ENABLED = "已啟用",
    REFRESH_AFTER_COMBAT = "戰鬥後重新整理…",
    SOFTCC_GUARD = "SoftCC 守護 — 恐懼/放逐時召回寵物 (被動+跟隨)",
    MODE_ALL_DESC = "all — 每個按鈕都發寵物 (包括恐懼)",
    MODE_CUSTOM_DESC = "custom — 總是發寵物, 除了 /pa block",
    MODE_HARM_DESC = "harm — 傷害/DoT 發寵物, 恐懼/石頭/增益不發",
    MODE_LABEL = "模式:",
    SUBTITLE = "寵物隨你的施法攻擊目標 (術士 / 獵人)",
    ADDON_DISABLED = "已停用。",
    SOFTCC_ON = "SoftCC 已啟用。",
    SOFTCC_OFF = "SoftCC 已停用。",
    STANCE_RESTORE_ON = "姿態恢復已啟用。",
    STANCE_RESTORE_OFF = "姿態恢復已停用。",
    CLASS_NOT_SUPPORTED = "PetAssist: 僅限獵人和術士。",
  },
}

-- Build the locale table with fallback
BuildLocale(TRANSLATIONS)

local defaults = {
  enabled = true,
  mode = MODE_HARM,       -- all | harm | custom
  softCC = true,          -- on Fear/Banish/… pull pet back (passive+follow)
  restoreStance = true,   -- restore pet stance (e.g. /petdefensive) before /petattack on normal spells
  stance = "defensive",
  macroPolicy = "auto",   -- auto (simple casts only) | attack | recall | ignore
  rules = {},             -- localized spell or macro name -> attack | recall | ignore
  softCCHowl = false,     -- include Howl of Terror in SoftCC (opt-in)
  softCCFrostTrap = false,-- include Frost Trap in SoftCC (opt-in)
  blacklist = {},         -- [lowerSpellName] = true (custom mode)
  recallKey = nil,        -- e.g. "SHIFT-F"
}

-- Classic Era: CC / utility that should not send the pet (localized via GetSpellInfo).
local BLOCK_SPELL_IDS = {
  -- Warlock CC / utility
  5782, 6213, 6215,           -- Fear
  710, 18647,                 -- Banish
  5484, 17928,                -- Howl of Terror
  6789, 17925, 17926,         -- Death Coil
  1098, 11725, 11726,         -- Enslave Demon
  126,                        -- Eye of Kilrogg
  1122,                       -- Inferno
  698,                        -- Ritual of Summoning
  18540,                      -- Ritual of Doom
  1454, 1455, 1456, 11687, 11688, 11689, -- Life Tap
  18220, 18937, 18938,        -- Dark Pact
  755, 3698, 3699, 3700, 11693, 11694, 11695, -- Health Funnel
  6229, 11739, 11740, 28610,  -- Shadow Ward
  687, 696,                   -- Demon Skin
  706, 1086, 11733, 11734, 11735, -- Demon Armor
  5500,                       -- Sense Demons
  132, 6512, 11743,           -- Detect Invisibility ranks
  5697,                       -- Unending Breath
  18708,                      -- Fel Domination
  19028,                      -- Soul Link
  18288,                      -- Amplify Curse
  6201, 6202, 5699, 11729, 11730, -- Create Healthstone
  693, 20752, 20755, 20756, 20757, -- Create Soulstone
  6366, 17951, 17952, 17953,  -- Create Firestone
  2362, 17727, 17728,         -- Create Spellstone
  -- Warlock demon summons
  688,                        -- Summon Imp
  697,                        -- Summon Voidwalker
  712,                        -- Summon Succubus
  691,                        -- Summon Felhunter
  30146,                      -- Summon Felguard (TBC, but keeping for compatibility)
  -- Hunter CC / utility
  5384,                       -- Feign Death
  1002,                       -- Eyes of the Beast
  6197,                       -- Eagle Eye
  1513, 14326, 14327,         -- Scare Beast
  1499, 14310, 14311,         -- Freezing Trap
  13809,                      -- Frost Trap
  19386, 24132, 24133,        -- Wyvern Sting
  19503,                      -- Scatter Shot
  20736,                      -- Distracting Shot
  1543,                       -- Flare
  1515,                       -- Tame Beast
  1462,                       -- Beast Lore
  883,                        -- Call Pet
  2641,                       -- Dismiss Pet
  982,                        -- Revive Pet
  6991,                       -- Feed Pet
  136, 3111, 3661, 3662, 13542, 13543, 13544, -- Mend Pet
  -- Hunter Aspects
  13163,                      -- Aspect of the Monkey
  13161,                      -- Aspect of the Beast
  13165,                      -- Aspect of the Hawk
  14318, 14319, 14320, 14321, 14322, 25296, -- Aspect of the Hawk ranks
  5118,                       -- Aspect of the Cheetah
  13159,                      -- Aspect of the Pack
  20043,                      -- Aspect of the Wild
  20190,                      -- Aspect of the Wild rank 2
  -- Hunter Tracking
  1494,                       -- Track Beasts
  19878,                      -- Track Demons
  19879,                      -- Track Dragonkin
  19880,                      -- Track Elementals
  19882,                      -- Track Giants
  19883,                      -- Track Humanoids
  19884,                      -- Track Undead
  19885,                      -- Track Hidden
  -- Hunter other utility
  19506,                      -- Trueshot Aura
  3045,                       -- Rapid Fire
  19263,                      -- Deterrence
  781,                        -- Disengage
}

-- Spells where the pet must STOP (SoftCC Guard): passive + follow with the cast.
-- Note: Howl of Terror and Frost Trap are opt-in via settings; Seduction removed (pet's own spell).
local SOFTCC_SPELL_IDS = {
  5782, 6213, 6215,           -- Fear
  710, 18647,                 -- Banish
  6789, 17925, 17926,         -- Death Coil
  1098, 11725, 11726,         -- Enslave Demon
  1513, 14326, 14327,         -- Scare Beast
  1499, 14310, 14311,         -- Freezing Trap
  19386, 24132, 24133,        -- Wyvern Sting
  19503,                      -- Scatter Shot
}

-- Opt-in SoftCC spells (controlled by settings)
local SOFTCC_HOWL_IDS = {
  5484, 17928,                -- Howl of Terror
}

local SOFTCC_FROST_TRAP_IDS = {
  13809,                      -- Frost Trap
}

local BARS = {
  { bind = "ACTIONBUTTON",          btn = "ActionButton" },
  { bind = "MULTIACTIONBAR1BUTTON", btn = "MultiBarBottomLeftButton" },
  { bind = "MULTIACTIONBAR2BUTTON", btn = "MultiBarBottomRightButton" },
  { bind = "MULTIACTIONBAR3BUTTON", btn = "MultiBarRightButton" },
  { bind = "MULTIACTIONBAR4BUTTON", btn = "MultiBarLeftButton" },
}

-- Extra action buttons (keybinds usually CLICK the button → PreClick is enough)
local EXTRA_BUTTON_FORMATS = {
  "DominosActionButton%d",
  "BT4Button%d",
}
for bar = 1, 10 do
  EXTRA_BUTTON_FORMATS[#EXTRA_BUTTON_FORMATS + 1] = "ElvUI_Bar" .. bar .. "Button%d"
end

local binder = CreateFrame("Frame", "PetAssistBinder", UIParent, "SecureHandlerBaseTemplate")
local header = CreateFrame("Frame", "PetAssistHeader", UIParent, "SecureHandlerBaseTemplate")

local PET = "/petattack [pet,@target,harm,nodead]"
local SOFTCC = "/petpassive\n/petfollow"

local recallBtn = CreateFrame("Button", "PetAssistRecall", UIParent, "SecureActionButtonTemplate")
recallBtn:RegisterForClicks("AnyUp", "AnyDown")
recallBtn:SetAttribute("type", "macro")
recallBtn:SetAttribute("*type*", "macro")
recallBtn:SetAttribute("macrotext", SOFTCC)
recallBtn:SetAttribute("*macrotext*", SOFTCC)
recallBtn:Hide()

local wrapped = {}
local blockedNames = {}
local softCcNames = {}
local pendingRefresh = false
local optionsFrame
local settingsCategory -- Settings API category (Classic Era Options → AddOns)
local isHunterOrWarlock = false
local hasShownClassWarning = false
local firstLogin = true
local refreshDebounceTimer

-- Read the same effective action/page attributes used by native secure buttons.
-- The native OnClick decides which physical phase fires (including mouse-up).
-- All policy attributes are written out of combat; paging itself remains secure.
local ONCLICK_PET = [[
  -- /click below re-enters this wrapper once with the original mouse button.
  if self:GetAttribute("pa_reentry") then
    self:SetAttribute("pa_reentry", nil)
    return
  end
  if not control:GetAttribute("pa_enabled") then return end
  if self:GetEffectiveAttribute("type", button) ~= "action" then return end
  local wantDown = self:GetEffectiveAttribute("useOnKeyDown", button)
  if wantDown == nil then wantDown = control:GetAttribute("pa_keydown") == 1 end

  local slot
  if self:GetAttribute("pa_native") and self:GetID() > 0 then
    local page = self:GetEffectiveAttribute("actionpage", button)
      or tonumber(control:GetAttribute("state-page")) or 1
    slot = self:GetID() + (page - 1) * 12
  else
    slot = self:GetEffectiveAttribute("action", button)
  end
  if not slot then return end
  local allow = control:GetAttribute("pa_slot_" .. slot)
  local text
  if allow == 1 then text = control:GetAttribute("pa_assist_text")
  elseif allow == 2 then text = control:GetAttribute("pa_recall_text") end
  if not text then return end
  -- Restricted frame handles have no Click method. Let SecureActionButton's
  -- native macro action run /click, preserving the original button and phase.
  self:SetAttribute("*type-PetAssist", "macro")
  self:SetAttribute("*macro-PetAssist", "")
  self:SetAttribute("*macrotext-PetAssist", text .. "\n/click " .. self:GetName()
    .. " " .. button .. (wantDown and " 1" or " 0"))
  self:SetAttribute("pa_reentry", true)
  return "PetAssist", true
]]

-- Fallback for older Blizzard buttons without an inherited actionpage attribute.
RegisterStateDriver(header, "page", "[bar:6]6;[bar:5]5;[bar:4]4;[bar:3]3;[bar:2]2;1")

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff9966ffPetAssist|r: " .. msg)
end

local function DB()
  if type(PetAssistDB) ~= "table" then
    PetAssistDB = {}
  end
  for k, v in pairs(defaults) do
    if PetAssistDB[k] == nil then
      if type(v) == "table" then
        PetAssistDB[k] = {}
      else
        PetAssistDB[k] = v
      end
    end
  end
  if type(PetAssistDB.blacklist) ~= "table" then
    PetAssistDB.blacklist = {}
  end
  if PetAssistDB.mode ~= MODE_ALL and PetAssistDB.mode ~= MODE_HARM and PetAssistDB.mode ~= MODE_CUSTOM then
    PetAssistDB.mode = MODE_HARM
  end
  if PetAssistDB.schemaVersion ~= 1 then
    local blacklist = {}
    for name, value in pairs(PetAssistDB.blacklist) do
      if type(name) == "string" and value then blacklist[name:lower()] = true end
    end
    PetAssistDB.blacklist = blacklist
    PetAssistDB.schemaVersion = 1
  end
  if type(PetAssistDB.rules) ~= "table" then PetAssistDB.rules = {} end
  if PetAssistDB.stance ~= "passive" and PetAssistDB.stance ~= "defensive" then
    PetAssistDB.stance = "defensive"
  end
  if PetAssistDB.macroPolicy ~= "auto" and PetAssistDB.macroPolicy ~= "attack"
    and PetAssistDB.macroPolicy ~= "recall" and PetAssistDB.macroPolicy ~= "ignore" then
    PetAssistDB.macroPolicy = "auto"
  end
  return PetAssistDB
end

local function SpellName(spellId)
  if not spellId then
    return nil
  end
  if GetSpellInfo then
    return GetSpellInfo(spellId)
  end
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(spellId)
  end
  return nil
end

local function RebuildBlockedNames()
  wipe(blockedNames)
  for _, spellId in ipairs(BLOCK_SPELL_IDS) do
    local name = SpellName(spellId)
    if name then
      blockedNames[name] = true
      blockedNames[name:lower()] = true
    end
  end
  wipe(softCcNames)
  for _, spellId in ipairs(SOFTCC_SPELL_IDS) do
    local name = SpellName(spellId)
    if name then
      softCcNames[name] = true
      softCcNames[name:lower()] = true
    end
  end
  -- Add opt-in SoftCC spells if enabled
  local db = DB()
  if db.softCCHowl then
    for _, spellId in ipairs(SOFTCC_HOWL_IDS) do
      local name = SpellName(spellId)
      if name then
        softCcNames[name] = true
        softCcNames[name:lower()] = true
      end
    end
  end
  if db.softCCFrostTrap then
    for _, spellId in ipairs(SOFTCC_FROST_TRAP_IDS) do
      local name = SpellName(spellId)
      if name then
        softCcNames[name] = true
        softCcNames[name:lower()] = true
      end
    end
  end
end

local function UseKeyDown()
  return GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false
end

local function SyncKeyDownAttr()
  if not InCombatLockdown() then
    header:SetAttribute("pa_keydown", UseKeyDown() and 1 or 0)
  end
end

local function IsBlockedSpell(spellId, name)
  if spellId and blockedNames[SpellName(spellId) or ""] then
    return true
  end
  if name then
    if blockedNames[name] or blockedNames[name:lower()] then
      return true
    end
  end
  return false
end

local function IsSoftCCSpell(spellId, name)
  if spellId then
    local sn = SpellName(spellId)
    if sn and (softCcNames[sn] or softCcNames[sn:lower()]) then
      return true
    end
  end
  if name and (softCcNames[name] or softCcNames[name:lower()]) then
    return true
  end
  return false
end

local function IsCustomBlacklisted(name)
  if not name then
    return false
  end
  local bl = DB().blacklist
  return bl[name] or bl[name:lower()] or false
end

local RULE_ACTIONS = { attack = PA_ASSIST, recall = PA_SOFTCC, ignore = PA_NONE }

local function NamedRule(name)
  if name then
    return RULE_ACTIONS[DB().rules[name] or DB().rules[name:lower()]]
  end
end

local function ResolveSpell(id, name)
  local db = DB()
  name = name or SpellName(id)
  local rule = NamedRule(name)
  if rule ~= nil then return rule, L.REASON_RULE end
  if not name then return PA_NONE, L.REASON_UNKNOWN end
  if db.softCC and IsSoftCCSpell(id, name) then
    return PA_SOFTCC, L.REASON_SOFTCC
  end
  if db.mode == MODE_CUSTOM and IsCustomBlacklisted(name) then
    return PA_NONE, L.REASON_BLACKLIST
  end
  if db.mode == MODE_HARM and IsBlockedSpell(id, name) then
    return PA_NONE, L.REASON_UTILITY
  end
  return PA_ASSIST, L.REASON_MODE
end

-- Only classify an unconditional single /cast. Do not guess which branch of a
-- conditional/sequence macro will run. Explicit pet commands always own policy.
local function InspectMacro(body)
  local castName, casts = nil, 0
  local unsafe, ownsPet = false, false
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    line = line:match("^%s*(.-)%s*$")
    local command, argument = line:match("^(/%S+)%s*(.-)$")
    local lower = command and command:lower()
    if lower and lower:match("^/pet") then ownsPet = true end
    if line ~= "" and not line:match("^#") then
      if lower == "/cast" and argument ~= "" and not argument:find("[%[%];]") then
        casts = casts + 1
        castName = argument:gsub("%s*%b()$", "")
      else
        unsafe = true
      end
    end
  end
  return not unsafe and casts == 1 and castName or nil, ownsPet
end

local function ResolveAction(actionType, id)
  if not actionType then return PA_NONE, L.REASON_EMPTY end
  local db = DB()
  if actionType == "spell" then return ResolveSpell(id) end
  if actionType == "macro" then
    if not id then return PA_NONE, L.REASON_UNKNOWN end
    local name, _, body = GetMacroInfo(id)
    if not body or body == "" then return PA_NONE, L.REASON_EMPTY end
    local castName, ownsPet = InspectMacro(body)
    if ownsPet then return PA_NONE, L.REASON_MACRO_PET end
    local rule = NamedRule(name)
    if rule ~= nil then return rule, L.REASON_RULE end
    if db.mode == MODE_CUSTOM and IsCustomBlacklisted(name) then
      return PA_NONE, L.REASON_BLACKLIST
    end
    local policy = RULE_ACTIONS[db.macroPolicy]
    if policy ~= nil then return policy, L.REASON_MACRO_POLICY end
    if castName then
      local name = SpellName(castName)
      if not name then return PA_NONE, L.REASON_UNKNOWN end
      return ResolveSpell(nil, name)
    end
    return PA_NONE, L.REASON_MACRO_COMPLEX
  end
  if actionType == "item" and db.mode ~= MODE_HARM then
    return PA_ASSIST, L.REASON_MODE
  end
  return PA_NONE, L.REASON_UTILITY
end

local function SlotFromButton(btn)
  if not btn then
    return nil
  end
  if btn.CalculateAction then
    local ok, slot = pcall(btn.CalculateAction, btn)
    if ok and slot then return slot end
  end
  if ActionButton_CalculateAction then
    local ok, slot = pcall(ActionButton_CalculateAction, btn)
    if ok and slot then
      return slot
    end
  end
  return btn:GetAttribute("action") or btn.action
end

local function SyncPetCommand()
  local db = DB()
  local text = PET
  if db.restoreStance then
    local stanceCommand = db.stance == "passive" and "/petpassive" or "/petdefensive"
    text = stanceCommand .. " [pet,@target,harm,nodead]\n" .. PET
  end
  header:SetAttribute("pa_assist_text", text)
  header:SetAttribute("pa_recall_text", SOFTCC)
end

local function PrepareSlotPolicies()
  -- Classic has ten pages of twelve action slots, including bonus/possess bars.
  for slot = 1, 120 do
    local actionType, id = GetActionInfo(slot)
    local action = ResolveAction(actionType, id)
    header:SetAttribute("pa_slot_" .. slot, action)
  end
end

local function WrapButton(realBtn)
  if not realBtn or wrapped[realBtn] or InCombatLockdown() then
    return
  end
  header:WrapScript(realBtn, "OnClick", ONCLICK_PET, [[
    self:SetAttribute("pa_reentry", nil)
  ]])
  wrapped[realBtn] = true
end

local function UnwrapButtons()
  if InCombatLockdown() then
    return
  end
  for btn in pairs(wrapped) do
    pcall(function()
      header:UnwrapScript(btn, "OnClick")
    end)
    pcall(function()
      btn:SetAttribute("pa_native", nil)
      btn:SetAttribute("pa_reentry", nil)
      btn:SetAttribute("*type-PetAssist", nil)
      btn:SetAttribute("*macro-PetAssist", nil)
      btn:SetAttribute("*macrotext-PetAssist", nil)
    end)
  end
  wipe(wrapped)
end

local function UpdateExtraButton(btn)
  if not btn or InCombatLockdown() then return end
  btn:SetAttribute("pa_native", false)
  WrapButton(btn)
end

local function ScanExtraButtons()
  if InCombatLockdown() then
    return 0
  end
  local n = 0
  for _, fmt in ipairs(EXTRA_BUTTON_FORMATS) do
    if _G[string.format(fmt, 1)] then
      for i = 1, 120 do
        local btn = _G[string.format(fmt, i)]
        if btn then
          UpdateExtraButton(btn)
          n = n + 1
        end
      end
    end
  end
  return n
end

local function ReportRecallConflict(key)
  local command = GetBindingAction(key)
  if command and command ~= "" and command ~= "CLICK PetAssistRecall:LeftButton" then
    Print(string.format(L.RECALL_CONFLICT, command, key))
  end
end

local function ApplyRecallBinding()
  if InCombatLockdown() then
    return
  end
  local key = DB().recallKey
  if key and key ~= "" then
    SetOverrideBindingClick(binder, true, key, "PetAssistRecall", "LeftButton")
  end
end

local function Apply()
  if InCombatLockdown() then
    pendingRefresh = true
    return false
  end
  
  -- Class gate: only work for Hunter and Warlock
  if not isHunterOrWarlock then
    return true, 0, 0, 0
  end

  RebuildBlockedNames()
  ClearOverrideBindings(binder)
  local db = DB()
  SyncKeyDownAttr()
  header:SetAttribute("pa_enabled", db.enabled and true or false)

  if not db.enabled then
    UnwrapButtons()
    return true, 0, 0, 0
  end

  SyncPetCommand()
  PrepareSlotPolicies()
  local buttonCount, keyCount, extraCount = 0, 0, 0
  for _, bar in ipairs(BARS) do
    for i = 1, 12 do
      local realBtn = _G[bar.btn .. i]
      if realBtn then
        realBtn:SetAttribute("pa_native", true)
        WrapButton(realBtn)
        buttonCount = buttonCount + 1
        -- Bind the original button on every page, including currently empty slots.
        -- Its native secure action preserves macro bodies, spell ranks and targets.
        local key1, key2 = GetBindingKey(bar.bind .. i)
        if key1 then
          SetOverrideBindingClick(binder, true, key1, realBtn:GetName(), "LeftButton")
          keyCount = keyCount + 1
        end
        if key2 then
          SetOverrideBindingClick(binder, true, key2, realBtn:GetName(), "LeftButton")
          keyCount = keyCount + 1
        end
      end
    end
  end

  extraCount = ScanExtraButtons()
  ApplyRecallBinding()

  return true, buttonCount, keyCount, extraCount
end

local function Refresh(quiet)
  -- Cancel any pending debounced refresh
  if refreshDebounceTimer then
    refreshDebounceTimer:Cancel()
    refreshDebounceTimer = nil
  end
  
  if InCombatLockdown() then
    pendingRefresh = true
    if not quiet then
      Print(L.REFRESH_AFTER_COMBAT)
    end
    return
  end
  
  -- Class gate check
  if not isHunterOrWarlock then
    if not hasShownClassWarning then
      Print(L.CLASS_NOT_SUPPORTED)
      hasShownClassWarning = true
    end
    return
  end
  
  pendingRefresh = false
  local ok, proxiesN, keysN, extraN = Apply()
  if ok and DB().enabled and not quiet then
    Print(string.format(
      L.ADDON_READY,
      VERSION, DB().mode or MODE_HARM, proxiesN or 0, keysN or 0, extraN or 0
    ))
  end
end

local function DebouncedRefresh()
  if refreshDebounceTimer then
    refreshDebounceTimer:Cancel()
  end
  refreshDebounceTimer = C_Timer.NewTimer(0.1, function()
    refreshDebounceTimer = nil
    Refresh(true)
  end)
end

-- ---------------------------------------------------------------------------
-- Options UI (Esc → Options → AddOns → PetAssist)
-- ---------------------------------------------------------------------------

local function ModeLabel(mode)
  if mode == MODE_ALL then
    return L.MODE_ALL_DESC
  elseif mode == MODE_CUSTOM then
    return L.MODE_CUSTOM_DESC
  end
  return L.MODE_HARM_DESC
end

local function RefreshOptionsUI()
  if not optionsFrame then
    return
  end
  local db = DB()
  optionsFrame.enableCheck:SetChecked(db.enabled)
  if optionsFrame.softCcCheck then
    optionsFrame.softCcCheck:SetChecked(db.softCC ~= false)
  end
  if optionsFrame.restoreStanceCheck then
    optionsFrame.restoreStanceCheck:SetChecked(db.restoreStance ~= false)
  end
  if optionsFrame.stanceButton then
    optionsFrame.stanceButton:SetText(string.format(L.STANCE_BUTTON, db.stance))
    optionsFrame.macroButton:SetText(string.format(L.MACRO_BUTTON, db.macroPolicy))
    optionsFrame.howlCheck:SetChecked(db.softCCHowl)
    optionsFrame.frostCheck:SetChecked(db.softCCFrostTrap)
  end
  optionsFrame.modeText:SetText(L.MODE_LABEL .. " " .. ModeLabel(db.mode))
  if optionsFrame.modeHint then
    if db.mode == MODE_ALL then
      optionsFrame.modeHint:SetText(L.MODE_ALL_HINT)
    elseif db.mode == MODE_CUSTOM then
      optionsFrame.modeHint:SetText(L.MODE_CUSTOM_HINT)
    else
      optionsFrame.modeHint:SetText(L.MODE_HARM_HINT)
    end
  end
  optionsFrame.recallText:SetText(L.RECALL_LABEL .. " " .. (db.recallKey or ("|cff888888" .. L.RECALL_UNBOUND .. "|r")))
  local blCount = 0
  for _ in pairs(db.blacklist) do
    blCount = blCount + 1
  end
  optionsFrame.blText:SetText(string.format(
    L.CUSTOM_BLACKLIST,
    blCount
  ))
end

local function CreateOptions()
  if optionsFrame then
    return optionsFrame
  end

  -- Canvas panel for Settings / Interface Options (fills the AddOns content area)
  local f = CreateFrame("Frame", "PetAssistOptionsPanel")
  f.name = "PetAssist"
  f:Hide()

  local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("PetAssist " .. VERSION)

  local sub = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText(L.SUBTITLE)

  local enableCheck = CreateFrame("CheckButton", "PetAssistEnableCheck", f, "UICheckButtonTemplate")
  enableCheck:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -16)
  local enableLabel = _G["PetAssistEnableCheckText"]
  if enableLabel then
    enableLabel:SetText(L.ENABLED)
  end
  enableCheck:SetScript("OnClick", function(self)
    DB().enabled = self:GetChecked() and true or false
    if DB().enabled then
      Refresh(false)
    else
      if not InCombatLockdown() then
        ClearOverrideBindings(binder)
        header:SetAttribute("pa_enabled", false)
        UnwrapButtons()
      else
        pendingRefresh = true
      end
      Print(L.ADDON_DISABLED)
    end
    RefreshOptionsUI()
  end)
  f.enableCheck = enableCheck

  local softCcCheck = CreateFrame("CheckButton", "PetAssistSoftCcCheck", f, "UICheckButtonTemplate")
  softCcCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -4)
  local softCcLabel = _G["PetAssistSoftCcCheckText"]
  if softCcLabel then
    softCcLabel:SetText(L.SOFTCC_GUARD)
  end
  softCcCheck:SetScript("OnClick", function(self)
    DB().softCC = self:GetChecked() and true or false
    Refresh(false)
    Print(DB().softCC and L.SOFTCC_ON or L.SOFTCC_OFF)
    RefreshOptionsUI()
  end)
  f.softCcCheck = softCcCheck

  local restoreStanceCheck = CreateFrame("CheckButton", "PetAssistRestoreStanceCheck", f, "UICheckButtonTemplate")
  restoreStanceCheck:SetPoint("TOPLEFT", softCcCheck, "BOTTOMLEFT", 0, -4)
  local restoreStanceLabel = _G["PetAssistRestoreStanceCheckText"]
  if restoreStanceLabel then
    restoreStanceLabel:SetText(L.RESTORE_STANCE)
  end
  restoreStanceCheck:SetScript("OnClick", function(self)
    DB().restoreStance = self:GetChecked() and true or false
    Refresh(false)
    Print(DB().restoreStance and L.STANCE_RESTORE_ON or L.STANCE_RESTORE_OFF)
    RefreshOptionsUI()
  end)
  f.restoreStanceCheck = restoreStanceCheck

  local stanceButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  stanceButton:SetSize(250, 24)
  stanceButton:SetPoint("TOPLEFT", restoreStanceCheck, "BOTTOMLEFT", 4, -8)
  stanceButton:SetScript("OnClick", function()
    DB().stance = DB().stance == "defensive" and "passive" or "defensive"
    Refresh(true)
    RefreshOptionsUI()
  end)
  f.stanceButton = stanceButton

  local macroButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  macroButton:SetSize(250, 24)
  macroButton:SetPoint("LEFT", stanceButton, "RIGHT", 8, 0)
  macroButton:SetScript("OnClick", function()
    local nextPolicy = { auto = "attack", attack = "recall", recall = "ignore", ignore = "auto" }
    DB().macroPolicy = nextPolicy[DB().macroPolicy]
    Refresh(true)
    RefreshOptionsUI()
  end)
  f.macroButton = macroButton

  local function OptionalCC(name, key, label, anchor, x, y)
    local check = CreateFrame("CheckButton", name, f, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
    _G[name .. "Text"]:SetText(label)
    check:SetScript("OnClick", function(self)
      DB()[key] = self:GetChecked() and true or false
      Refresh(true)
      RefreshOptionsUI()
    end)
    return check
  end
  f.howlCheck = OptionalCC("PetAssistHowlCheck", "softCCHowl", L.HOWL_OPTION, stanceButton, -4, -6)
  f.frostCheck = OptionalCC("PetAssistFrostCheck", "softCCFrostTrap", L.FROST_OPTION, macroButton, -4, -6)

  local modeText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  modeText:SetPoint("TOPLEFT", f.howlCheck, "BOTTOMLEFT", 4, -8)
  modeText:SetWidth(520)
  modeText:SetJustifyH("LEFT")
  f.modeText = modeText

  local function SetMode(mode)
    DB().mode = mode
    Refresh(false)
    RefreshOptionsUI()
    Print(string.format(L.MODE_CHANGED, ModeLabel(mode)))
  end

  local btnHarm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnHarm:SetSize(140, 24)
  btnHarm:SetPoint("TOPLEFT", modeText, "BOTTOMLEFT", 0, -8)
  btnHarm:SetText("harm")
  btnHarm:SetScript("OnClick", function() SetMode(MODE_HARM) end)

  local btnAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnAll:SetSize(100, 24)
  btnAll:SetPoint("LEFT", btnHarm, "RIGHT", 8, 0)
  btnAll:SetText("all")
  btnAll:SetScript("OnClick", function() SetMode(MODE_ALL) end)

  local btnCustom = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnCustom:SetSize(100, 24)
  btnCustom:SetPoint("LEFT", btnAll, "RIGHT", 8, 0)
  btnCustom:SetText("custom")
  btnCustom:SetScript("OnClick", function() SetMode(MODE_CUSTOM) end)

  local modeHint = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  modeHint:SetPoint("TOPLEFT", btnHarm, "BOTTOMLEFT", 0, -8)
  modeHint:SetWidth(520)
  modeHint:SetJustifyH("LEFT")
  f.modeHint = modeHint

  local blText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  blText:SetPoint("TOPLEFT", modeHint, "BOTTOMLEFT", 0, -12)
  blText:SetWidth(520)
  blText:SetJustifyH("LEFT")
  f.blText = blText

  local ruleName = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  ruleName:SetSize(215, 24)
  ruleName:SetPoint("TOPLEFT", blText, "BOTTOMLEFT", 4, -12)
  ruleName:SetAutoFocus(false)
  ruleName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local ruleLabel = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  ruleLabel:SetPoint("BOTTOMLEFT", ruleName, "TOPLEFT", 0, 2)
  ruleLabel:SetText(L.RULE_NAME_HINT)
  local ruleMode = "ignore"
  local ruleButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  ruleButton:SetSize(140, 24)
  ruleButton:SetPoint("LEFT", ruleName, "RIGHT", 8, 0)
  ruleButton:SetText(string.format(L.RULE_ACTION, ruleMode))
  ruleButton:SetScript("OnClick", function(self)
    local nextRule = { ignore = "attack", attack = "recall", recall = "clear", clear = "ignore" }
    ruleMode = nextRule[ruleMode]
    self:SetText(string.format(L.RULE_ACTION, ruleMode))
  end)
  local ruleApply = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  ruleApply:SetSize(140, 24)
  ruleApply:SetPoint("LEFT", ruleButton, "RIGHT", 8, 0)
  ruleApply:SetText(L.RULE_APPLY)
  ruleApply:SetScript("OnClick", function()
    local name = ruleName:GetText():match("^%s*(.-)%s*$")
    if name == "" then Print(L.RULE_USAGE); return end
    DB().rules[name] = nil
    DB().rules[name:lower()] = ruleMode ~= "clear" and ruleMode or nil
    ruleName:ClearFocus()
    Refresh(true)
    Print(string.format(L.RULE_SAVED, name, ruleMode))
  end)

  f.ruleName, f.ruleButton, f.ruleApply = ruleName, ruleButton, ruleApply

  local recallText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  recallText:SetPoint("TOPLEFT", ruleName, "BOTTOMLEFT", -4, -12)
  recallText:SetWidth(520)
  recallText:SetJustifyH("LEFT")
  f.recallText = recallText

  local bindBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  bindBtn:SetSize(160, 24)
  bindBtn:SetPoint("TOPLEFT", recallText, "BOTTOMLEFT", 0, -8)
  bindBtn:SetText(L.BIND_RECALL)
  local binderFrame = CreateFrame("Frame", nil, f)
  binderFrame:Hide()
  f.recallCapture = binderFrame
  bindBtn:SetScript("OnClick", function(self)
    if InCombatLockdown() then
      Print(L.CANNOT_BIND_COMBAT)
      return
    end
    self:SetText(L.PRESS_KEY)
    binderFrame:EnableKeyboard(true)
    if binderFrame.SetPropagateKeyboardInput then
      binderFrame:SetPropagateKeyboardInput(false)
    end
    binderFrame:SetScript("OnKeyDown", function(_, key)
      if key == "ESCAPE" then
        self:SetText(L.BIND_RECALL)
        binderFrame:Hide()
        return
      end
      if key == "UNKNOWN" or key == "LSHIFT" or key == "RSHIFT"
        or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
        return
      end
      local parts = {}
      if IsShiftKeyDown() then parts[#parts + 1] = "SHIFT" end
      if IsControlKeyDown() then parts[#parts + 1] = "CTRL" end
      if IsAltKeyDown() then parts[#parts + 1] = "ALT" end
      parts[#parts + 1] = key
      local binding = table.concat(parts, "-")
      ReportRecallConflict(binding)
      DB().recallKey = binding
      Refresh(true)
      self:SetText(L.BIND_RECALL)
      Print(string.format(L.RECALL_BOUND, binding))
      RefreshOptionsUI()
      binderFrame:Hide()
    end)
    binderFrame:Show()
  end)

  local clearBind = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBind:SetSize(100, 24)
  clearBind:SetPoint("LEFT", bindBtn, "RIGHT", 8, 0)
  clearBind:SetText(L.CLEAR)
  clearBind:SetScript("OnClick", function()
    DB().recallKey = nil
    Refresh(true)
    Print(L.RECALL_CLEARED)
    RefreshOptionsUI()
  end)

  local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  refreshBtn:SetSize(120, 24)
  refreshBtn:SetPoint("TOPLEFT", bindBtn, "BOTTOMLEFT", 0, -20)
  refreshBtn:SetText(L.REFRESH)
  refreshBtn:SetScript("OnClick", function() Refresh(false) end)

  local hint = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  hint:SetPoint("TOPLEFT", refreshBtn, "BOTTOMLEFT", 0, -20)
  hint:SetWidth(520)
  hint:SetJustifyH("LEFT")
  hint:SetText(L.SLASH_HINT .. "\n/pa rule attack|recall|ignore|clear Name\n" .. L.ESCAPE_OPTIONS)

  f:SetScript("OnShow", RefreshOptionsUI)
  f:SetScript("OnHide", function()
    binderFrame:Hide()
    binderFrame:EnableKeyboard(false)
    bindBtn:SetText(L.BIND_RECALL)
  end)

  optionsFrame = f
  RefreshOptionsUI()
  return f
end

local function RegisterOptionsPanel()
  local panel = CreateOptions()
  if settingsCategory then
    return
  end

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(settingsCategory)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

local function ToggleOptions()
  RegisterOptionsPanel()
  RefreshOptionsUI()

  if settingsCategory and Settings and Settings.OpenToCategory then
    -- Classic Era accepts category ID; some builds accept the category object
    if settingsCategory.GetID then
      Settings.OpenToCategory(settingsCategory:GetID())
    else
      Settings.OpenToCategory(settingsCategory)
    end
    return
  end

  if InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(optionsFrame) -- Classic quirk: call twice
    return
  end

  -- Fallback: show panel as floating window
  if not optionsFrame:GetParent() or optionsFrame:GetParent() == UIParent then
    optionsFrame:SetParent(UIParent)
    optionsFrame:ClearAllPoints()
    optionsFrame:SetSize(600, 600)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
  end
  optionsFrame:Show()
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("UPDATE_MACROS")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:RegisterEvent("UNIT_PET")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then
      -- Detect class
      local _, class = UnitClass("player")
      isHunterOrWarlock = (class == "HUNTER" or class == "WARLOCK")
      
      DB()
      RebuildBlockedNames()
      RegisterOptionsPanel()
    end
    return
  end

  if event == "CVAR_UPDATE" then
    if arg1 == "ActionButtonUseKeyDown" then
      if InCombatLockdown() then pendingRefresh = true else SyncKeyDownAttr() end
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    if not isHunterOrWarlock then
      if not hasShownClassWarning then
        Print(L.CLASS_NOT_SUPPORTED)
        hasShownClassWarning = true
      end
      return
    end
    
    if DB().enabled then
      C_Timer.After(0.75, function()
        -- Only print on first login
        Refresh(not firstLogin)
        firstLogin = false
      end)
      -- Late scan for Dominos/ElvUI that load after us
      C_Timer.After(2.5, function()
        if DB().enabled and not InCombatLockdown() then
          ScanExtraButtons()
        end
      end)
    end
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if pendingRefresh then
      Refresh(true)
    end
    return
  end

  if event == "UNIT_PET" and arg1 ~= "player" then
    return
  end

  if not DB().enabled or not isHunterOrWarlock then
    return
  end

  -- Debounce rapid action bar events
  if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_MACROS" then
    if InCombatLockdown() then
      pendingRefresh = true
      return
    end
    DebouncedRefresh()
    return
  end

  if InCombatLockdown() then
    pendingRefresh = true
    return
  end

  Apply()
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

SLASH_PETASSIST1 = "/petassist"
SLASH_PETASSIST2 = "/pa"
SlashCmdList.PETASSIST = function(msg)
  local db = DB()
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""
  rest = rest or ""

  if cmd == "" or cmd == "help" or cmd == "помощь" then
    Print(L.SLASH_HELP)
    Print(string.format(L.SLASH_MODE_STATUS, 
      ModeLabel(db.mode),
      (db.softCC ~= false and "on" or "off"),
      (db.restoreStance ~= false and "on" or "off")))
  elseif cmd == "on" or cmd == "вкл" then
    db.enabled = true
    Refresh(false)
  elseif cmd == "off" or cmd == "выкл" then
    db.enabled = false
    if not InCombatLockdown() then
      ClearOverrideBindings(binder)
      header:SetAttribute("pa_enabled", false)
      UnwrapButtons()
    else
      pendingRefresh = true
    end
    Print(L.ADDON_DISABLED)
  elseif cmd == "refresh" or cmd == "rewrap" or cmd == "обновить" then
    Refresh(false)
  elseif cmd == "config" or cmd == "options" or cmd == "настройки" then
    ToggleOptions()
  elseif cmd == "softcc" or cmd == "cc" then
    local m = rest:lower()
    if m == "on" or m == "вкл" or m == "1" then
      db.softCC = true
    elseif m == "off" or m == "выкл" or m == "0" then
      db.softCC = false
    else
      db.softCC = not (db.softCC ~= false)
    end
    Refresh(false)
    Print(string.format(L.SOFTCC_TOGGLE, db.softCC and L.SOFTCC_ON_DESC or L.SOFTCC_OFF_DESC))
  elseif cmd == "stance" or cmd == "стойка" then
    local m = rest:lower()
    if m == "on" or m == "вкл" or m == "1" then
      db.restoreStance = true
    elseif m == "off" or m == "выкл" or m == "0" then
      db.restoreStance = false
    elseif m == "passive" or m == "defensive" then
      db.stance = m
      db.restoreStance = true
    elseif m == "" then
      db.restoreStance = not (db.restoreStance ~= false)
    else
      Print(L.STANCE_USAGE)
      return
    end
    Refresh(false)
    Print(string.format(L.STANCE_TOGGLE, db.restoreStance and db.stance or "off"))
  elseif cmd == "macros" then
    local policy = rest:lower()
    if policy ~= "auto" and RULE_ACTIONS[policy] == nil then Print(L.MACRO_USAGE); return end
    db.macroPolicy = policy
    Refresh(true)
    Print(string.format(L.MACRO_BUTTON, policy))
  elseif cmd == "howl" or cmd == "frost" then
    local value = rest:lower()
    if value ~= "on" and value ~= "off" then Print(string.format(L.OPTION_USAGE, cmd)); return end
    db[cmd == "howl" and "softCCHowl" or "softCCFrostTrap"] = value == "on"
    Refresh(true)
  elseif cmd == "rule" then
    local policy, name = rest:match("^(%S+)%s+(.+)$")
    policy = policy and policy:lower()
    if not name or (policy ~= "clear" and RULE_ACTIONS[policy] == nil) then
      Print(L.RULE_USAGE)
      return
    end
    db.rules[name] = nil
    db.rules[name:lower()] = policy ~= "clear" and policy or nil
    Refresh(true)
    Print(string.format(L.RULE_SAVED, name, policy))
  elseif cmd == "rules" then
    local names = {}
    for name in pairs(db.rules) do names[#names + 1] = name end
    table.sort(names)
    for _, name in ipairs(names) do Print(string.format(L.RULE_LIST, name, db.rules[name])) end
  elseif cmd == "mode" or cmd == "режим" then
    local m = rest:lower()
    if m == MODE_ALL or m == MODE_HARM or m == MODE_CUSTOM then
      db.mode = m
      Refresh(false)
      Print(string.format(L.MODE_CHANGED, ModeLabel(m)))
    else
      Print(string.format(L.USAGE_MODE, tostring(db.mode)))
    end
  elseif cmd == "block" or cmd == "блок" then
    if rest == "" then
      Print(L.USAGE_BLOCK)
      return
    end
    db.blacklist[rest] = nil
    db.blacklist[rest:lower()] = true
    if db.mode ~= MODE_CUSTOM then
      Print(L.BLOCK_ADDED)
    end
    Refresh(true)
    Print(string.format(L.BLOCKED, rest))
  elseif cmd == "unblock" or cmd == "разблок" then
    if rest == "" then
      Print(L.USAGE_UNBLOCK)
      return
    end
    db.blacklist[rest] = nil
    db.blacklist[rest:lower()] = nil
    Refresh(true)
    Print(string.format(L.UNBLOCKED, rest))
  elseif cmd == "recall" or cmd == "отзыв" then
    if rest == "" or rest:lower() == "clear" or rest:lower() == "сброс" then
      db.recallKey = nil
      Refresh(true)
      Print(L.RECALL_BIND_USAGE)
    else
      db.recallKey = rest:upper():gsub("%s+", "")
      ReportRecallConflict(db.recallKey)
      Refresh(true)
      Print(string.format(L.RECALL_BOUND, db.recallKey))
    end
  elseif cmd == "test" or cmd == "тест" then
    local buttonName = rest ~= "" and rest or "ActionButton1"
    local btn = _G[buttonName]
    if not btn or type(btn.GetAttribute) ~= "function" then
      Print(string.format(L.TEST_BAD_BUTTON, buttonName))
      return
    end
    local slot = SlotFromButton(btn)
    local actionType, id
    if slot then actionType, id = GetActionInfo(slot) end
    local action, reason = ResolveAction(actionType, id)
    local prepared = slot and header:GetAttribute("pa_slot_" .. slot) or PA_NONE
    local name = actionType == "spell" and SpellName(id)
    if actionType == "macro" then name = GetMacroInfo(id) end
    Print(string.format(L.TEST_DETAIL, buttonName, tostring(slot), tostring(actionType),
      tostring(id), tostring(name), tostring(action), tostring(prepared), reason,
      tostring(pendingRefresh), tostring(InCombatLockdown())))
    Print(string.format(L.TEST_NATIVE, tostring(wrapped[btn] == true), tostring(DB().stance),
      tostring(DB().macroPolicy)))
  elseif cmd == "status" or cmd == "статус" then
    local statusText = db.enabled and string.format(L.STATUS_ENABLED, VERSION) or L.STATUS_DISABLED
    Print(string.format(L.STATUS_OUTPUT,
      statusText,
      ModeLabel(db.mode),
      (db.softCC ~= false and "on" or "off"),
      (db.restoreStance ~= false and "on" or "off")))
  else
    Print(L.UNKNOWN_COMMAND)
  end
end
