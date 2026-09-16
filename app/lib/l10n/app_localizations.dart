import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SACRISTAN'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get navChecklists;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get navReference;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @colorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @colorGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colorGold;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorGoldPermittedSuffix.
  ///
  /// In en, this message translates to:
  /// **'(gold permitted)'**
  String get colorGoldPermittedSuffix;

  /// No description provided for @rankSolemnity.
  ///
  /// In en, this message translates to:
  /// **'Solemnity'**
  String get rankSolemnity;

  /// No description provided for @rankFeast.
  ///
  /// In en, this message translates to:
  /// **'Feast'**
  String get rankFeast;

  /// No description provided for @rankMemorial.
  ///
  /// In en, this message translates to:
  /// **'Memorial'**
  String get rankMemorial;

  /// No description provided for @rankOptionalMemorial.
  ///
  /// In en, this message translates to:
  /// **'Optional Memorial'**
  String get rankOptionalMemorial;

  /// No description provided for @rankSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get rankSunday;

  /// No description provided for @rankFerial.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get rankFerial;

  /// No description provided for @rankTriduum.
  ///
  /// In en, this message translates to:
  /// **'Sacred Triduum'**
  String get rankTriduum;

  /// No description provided for @seasonAdvent.
  ///
  /// In en, this message translates to:
  /// **'Advent'**
  String get seasonAdvent;

  /// No description provided for @seasonChristmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas'**
  String get seasonChristmas;

  /// No description provided for @seasonOrdinaryTime.
  ///
  /// In en, this message translates to:
  /// **'Ordinary Time'**
  String get seasonOrdinaryTime;

  /// No description provided for @seasonLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get seasonLent;

  /// No description provided for @seasonTriduum.
  ///
  /// In en, this message translates to:
  /// **'Sacred Triduum'**
  String get seasonTriduum;

  /// No description provided for @seasonEaster.
  ///
  /// In en, this message translates to:
  /// **'Easter'**
  String get seasonEaster;

  /// No description provided for @beforeMass.
  ///
  /// In en, this message translates to:
  /// **'Before Mass'**
  String get beforeMass;

  /// No description provided for @afterMass.
  ///
  /// In en, this message translates to:
  /// **'After Mass'**
  String get afterMass;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @checklistsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No templates yet.'**
  String get checklistsEmptyState;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes — {date}'**
  String notesTitle(String date);

  /// No description provided for @notesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No notes for this date yet.'**
  String get notesEmptyState;

  /// No description provided for @referenceAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get referenceAddEntry;

  /// No description provided for @referenceEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No entries in this category yet.'**
  String get referenceEmptyState;

  /// No description provided for @localCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Parish / Diocesan Calendar'**
  String get localCalendarTitle;

  /// No description provided for @localCalendarEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No local entries yet.\nAdd your patronal feast, a diocesan saint, or your parish anniversary — it will show up on the Dashboard and Calendar automatically, every year, fully offline.'**
  String get localCalendarEmptyState;

  /// No description provided for @localCalendarAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get localCalendarAddEntry;

  /// No description provided for @contactsSuppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts & Suppliers'**
  String get contactsSuppliersTitle;

  /// No description provided for @contactsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Add phone numbers for the Pastor, Sacristan, and Server Leader so low-stock alerts can text them directly.'**
  String get contactsEmptyState;

  /// No description provided for @contactsAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get contactsAddContact;

  /// No description provided for @suppliersEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Add your usual suppliers here so a pastor can text an order directly, or reach them online once connected.'**
  String get suppliersEmptyState;

  /// No description provided for @suppliersAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get suppliersAddSupplier;

  /// No description provided for @adminPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin PIN'**
  String get adminPinTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Add one for the next feast-day prep, linen laundering, or restock.'**
  String get remindersEmptyState;

  /// No description provided for @remindersAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get remindersAddReminder;

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sacristan Profiles'**
  String get profilesTitle;

  /// No description provided for @profilesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet. Add volunteers and assign roles.'**
  String get profilesEmptyState;

  /// No description provided for @profilesAddProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get profilesAddProfile;

  /// No description provided for @manageTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Checklist Templates'**
  String get manageTemplatesTitle;

  /// No description provided for @manageTemplatesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No templates yet.'**
  String get manageTemplatesEmptyState;

  /// No description provided for @manageTemplatesAddTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get manageTemplatesAddTemplate;

  /// No description provided for @templateItemsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Tap + to add one.'**
  String get templateItemsEmptyState;

  /// No description provided for @settingsAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get settingsAccessSection;

  /// No description provided for @settingsChecklistsSection.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get settingsChecklistsSection;

  /// No description provided for @settingsCalendarSection.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get settingsCalendarSection;

  /// No description provided for @settingsNotificationsContactsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Contacts'**
  String get settingsNotificationsContactsSection;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSection;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
