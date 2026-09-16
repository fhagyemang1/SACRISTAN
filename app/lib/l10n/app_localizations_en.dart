// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SACRISTAN';

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navChecklists => 'Checklists';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navReference => 'Reference';

  @override
  String get navNotes => 'Notes';

  @override
  String get navSettings => 'Settings';

  @override
  String get thisWeek => 'This Week';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorWhite => 'White';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorGold => 'Gold';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorGoldPermittedSuffix => '(gold permitted)';

  @override
  String get rankSolemnity => 'Solemnity';

  @override
  String get rankFeast => 'Feast';

  @override
  String get rankMemorial => 'Memorial';

  @override
  String get rankOptionalMemorial => 'Optional Memorial';

  @override
  String get rankSunday => 'Sunday';

  @override
  String get rankFerial => 'Weekday';

  @override
  String get rankTriduum => 'Sacred Triduum';

  @override
  String get seasonAdvent => 'Advent';

  @override
  String get seasonChristmas => 'Christmas';

  @override
  String get seasonOrdinaryTime => 'Ordinary Time';

  @override
  String get seasonLent => 'Lent';

  @override
  String get seasonTriduum => 'Sacred Triduum';

  @override
  String get seasonEaster => 'Easter';

  @override
  String get beforeMass => 'Before Mass';

  @override
  String get afterMass => 'After Mass';

  @override
  String get addItem => 'Add item';

  @override
  String get addNote => 'Add note';

  @override
  String get checklistsEmptyState => 'No templates yet.';

  @override
  String notesTitle(String date) {
    return 'Notes — $date';
  }

  @override
  String get notesEmptyState => 'No notes for this date yet.';

  @override
  String get referenceAddEntry => 'Add entry';

  @override
  String get referenceEmptyState => 'No entries in this category yet.';

  @override
  String get localCalendarTitle => 'Parish / Diocesan Calendar';

  @override
  String get localCalendarEmptyState =>
      'No local entries yet.\nAdd your patronal feast, a diocesan saint, or your parish anniversary — it will show up on the Dashboard and Calendar automatically, every year, fully offline.';

  @override
  String get localCalendarAddEntry => 'Add entry';

  @override
  String get contactsSuppliersTitle => 'Contacts & Suppliers';

  @override
  String get contactsEmptyState =>
      'Add phone numbers for the Pastor, Sacristan, and Server Leader so low-stock alerts can text them directly.';

  @override
  String get contactsAddContact => 'Add contact';

  @override
  String get suppliersEmptyState =>
      'Add your usual suppliers here so a pastor can text an order directly, or reach them online once connected.';

  @override
  String get suppliersAddSupplier => 'Add supplier';

  @override
  String get adminPinTitle => 'Admin PIN';

  @override
  String get languageTitle => 'Language';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersEmptyState =>
      'No reminders yet. Add one for the next feast-day prep, linen laundering, or restock.';

  @override
  String get remindersAddReminder => 'Add reminder';

  @override
  String get profilesTitle => 'Sacristan Profiles';

  @override
  String get profilesEmptyState =>
      'No profiles yet. Add volunteers and assign roles.';

  @override
  String get profilesAddProfile => 'Add profile';

  @override
  String get manageTemplatesTitle => 'Manage Checklist Templates';

  @override
  String get manageTemplatesEmptyState => 'No templates yet.';

  @override
  String get manageTemplatesAddTemplate => 'Add template';

  @override
  String get templateItemsEmptyState => 'No items yet. Tap + to add one.';

  @override
  String get settingsAccessSection => 'Access';

  @override
  String get settingsChecklistsSection => 'Checklists';

  @override
  String get settingsCalendarSection => 'Calendar';

  @override
  String get settingsNotificationsContactsSection => 'Notifications & Contacts';

  @override
  String get settingsAppSection => 'App';

  @override
  String get inventoryTitle => 'Inventory';
}
