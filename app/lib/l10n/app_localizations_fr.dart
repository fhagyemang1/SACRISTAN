// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SACRISTAN';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get navChecklists => 'Listes';

  @override
  String get navInventory => 'Inventaire';

  @override
  String get navReference => 'Référence';

  @override
  String get navNotes => 'Notes';

  @override
  String get navSettings => 'Réglages';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorWhite => 'Blanc';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorGold => 'Or';

  @override
  String get colorBlack => 'Noir';

  @override
  String get colorGoldPermittedSuffix => '(or autorisé)';

  @override
  String get rankSolemnity => 'Solennité';

  @override
  String get rankFeast => 'Fête';

  @override
  String get rankMemorial => 'Mémoire';

  @override
  String get rankOptionalMemorial => 'Mémoire facultative';

  @override
  String get rankSunday => 'Dimanche';

  @override
  String get rankFerial => 'Férie';

  @override
  String get rankTriduum => 'Triduum pascal';

  @override
  String get seasonAdvent => 'Avent';

  @override
  String get seasonChristmas => 'Noël';

  @override
  String get seasonOrdinaryTime => 'Temps ordinaire';

  @override
  String get seasonLent => 'Carême';

  @override
  String get seasonTriduum => 'Triduum pascal';

  @override
  String get seasonEaster => 'Pâques';

  @override
  String get beforeMass => 'Avant la messe';

  @override
  String get afterMass => 'Après la messe';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get checklistsEmptyState => 'Aucun modèle pour l\'instant.';

  @override
  String notesTitle(String date) {
    return 'Notes — $date';
  }

  @override
  String get notesEmptyState => 'Aucune note pour cette date pour l\'instant.';

  @override
  String get referenceAddEntry => 'Ajouter une entrée';

  @override
  String get referenceEmptyState =>
      'Aucune entrée dans cette catégorie pour l\'instant.';

  @override
  String get localCalendarTitle => 'Calendrier paroissial / diocésain';

  @override
  String get localCalendarEmptyState =>
      'Aucune entrée locale pour l\'instant.\nAjoutez votre fête patronale, un saint diocésain ou l\'anniversaire de votre paroisse — elle apparaîtra automatiquement sur le Tableau de bord et le Calendrier, chaque année, entièrement hors ligne.';

  @override
  String get localCalendarAddEntry => 'Ajouter une entrée';

  @override
  String get contactsSuppliersTitle => 'Contacts et fournisseurs';

  @override
  String get contactsEmptyState =>
      'Ajoutez les numéros de téléphone du curé, du sacristain et du responsable des servants d\'autel afin que les alertes de stock faible puissent leur envoyer un texto directement.';

  @override
  String get contactsAddContact => 'Ajouter un contact';

  @override
  String get suppliersEmptyState =>
      'Ajoutez ici vos fournisseurs habituels afin qu\'un curé puisse leur envoyer une commande par texto, ou les contacter en ligne une fois connecté.';

  @override
  String get suppliersAddSupplier => 'Ajouter un fournisseur';

  @override
  String get adminPinTitle => 'Code administrateur';

  @override
  String get languageTitle => 'Langue';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get remindersEmptyState =>
      'Aucun rappel pour l\'instant. Ajoutez-en un pour la prochaine préparation de fête, la lessive des linges ou le réapprovisionnement.';

  @override
  String get remindersAddReminder => 'Ajouter un rappel';

  @override
  String get profilesTitle => 'Profils des sacristains';

  @override
  String get profilesEmptyState =>
      'Aucun profil pour l\'instant. Ajoutez des bénévoles et attribuez des rôles.';

  @override
  String get profilesAddProfile => 'Ajouter un profil';

  @override
  String get manageTemplatesTitle => 'Gérer les modèles de listes';

  @override
  String get manageTemplatesEmptyState => 'Aucun modèle pour l\'instant.';

  @override
  String get manageTemplatesAddTemplate => 'Ajouter un modèle';

  @override
  String get templateItemsEmptyState =>
      'Aucun élément pour l\'instant. Touchez + pour en ajouter un.';

  @override
  String get settingsAccessSection => 'Accès';

  @override
  String get settingsChecklistsSection => 'Listes';

  @override
  String get settingsCalendarSection => 'Calendrier';

  @override
  String get settingsNotificationsContactsSection =>
      'Notifications et contacts';

  @override
  String get settingsAppSection => 'Application';

  @override
  String get inventoryTitle => 'Inventaire';
}
