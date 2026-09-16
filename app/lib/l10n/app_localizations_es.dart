// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SACRISTAN';

  @override
  String get navToday => 'Hoy';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get navChecklists => 'Listas';

  @override
  String get navInventory => 'Inventario';

  @override
  String get navReference => 'Referencia';

  @override
  String get navNotes => 'Notas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get colorViolet => 'Morado';

  @override
  String get colorWhite => 'Blanco';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorGold => 'Oro';

  @override
  String get colorBlack => 'Negro';

  @override
  String get colorGoldPermittedSuffix => '(oro permitido)';

  @override
  String get rankSolemnity => 'Solemnidad';

  @override
  String get rankFeast => 'Fiesta';

  @override
  String get rankMemorial => 'Memoria';

  @override
  String get rankOptionalMemorial => 'Memoria libre';

  @override
  String get rankSunday => 'Domingo';

  @override
  String get rankFerial => 'Feria';

  @override
  String get rankTriduum => 'Triduo Pascual';

  @override
  String get seasonAdvent => 'Adviento';

  @override
  String get seasonChristmas => 'Navidad';

  @override
  String get seasonOrdinaryTime => 'Tiempo Ordinario';

  @override
  String get seasonLent => 'Cuaresma';

  @override
  String get seasonTriduum => 'Triduo Pascual';

  @override
  String get seasonEaster => 'Pascua';

  @override
  String get beforeMass => 'Antes de la misa';

  @override
  String get afterMass => 'Después de la misa';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get addNote => 'Añadir nota';

  @override
  String get checklistsEmptyState => 'Aún no hay plantillas.';

  @override
  String notesTitle(String date) {
    return 'Notas — $date';
  }

  @override
  String get notesEmptyState => 'Aún no hay notas para esta fecha.';

  @override
  String get referenceAddEntry => 'Añadir entrada';

  @override
  String get referenceEmptyState => 'Aún no hay entradas en esta categoría.';

  @override
  String get localCalendarTitle => 'Calendario parroquial / diocesano';

  @override
  String get localCalendarEmptyState =>
      'Aún no hay entradas locales.\nAñada su fiesta patronal, un santo diocesano o el aniversario de su parroquia — aparecerá automáticamente en el Panel y el Calendario, cada año, completamente sin conexión.';

  @override
  String get localCalendarAddEntry => 'Añadir entrada';

  @override
  String get contactsSuppliersTitle => 'Contactos y proveedores';

  @override
  String get contactsEmptyState =>
      'Añada los números de teléfono del párroco, el sacristán y el responsable de los monaguillos para que las alertas de stock bajo puedan enviarles un mensaje de texto directamente.';

  @override
  String get contactsAddContact => 'Añadir contacto';

  @override
  String get suppliersEmptyState =>
      'Añada aquí sus proveedores habituales para que un párroco pueda enviarles un pedido por mensaje de texto, o contactarlos en línea una vez conectado.';

  @override
  String get suppliersAddSupplier => 'Añadir proveedor';

  @override
  String get adminPinTitle => 'PIN de administrador';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get remindersEmptyState =>
      'Aún no hay recordatorios. Añada uno para la próxima preparación de una fiesta, el lavado de los lienzos o el reabastecimiento.';

  @override
  String get remindersAddReminder => 'Añadir recordatorio';

  @override
  String get profilesTitle => 'Perfiles de sacristanes';

  @override
  String get profilesEmptyState =>
      'Aún no hay perfiles. Añada voluntarios y asigne roles.';

  @override
  String get profilesAddProfile => 'Añadir perfil';

  @override
  String get manageTemplatesTitle => 'Gestionar plantillas de listas';

  @override
  String get manageTemplatesEmptyState => 'Aún no hay plantillas.';

  @override
  String get manageTemplatesAddTemplate => 'Añadir plantilla';

  @override
  String get templateItemsEmptyState =>
      'Aún no hay elementos. Toque + para añadir uno.';

  @override
  String get settingsAccessSection => 'Acceso';

  @override
  String get settingsChecklistsSection => 'Listas';

  @override
  String get settingsCalendarSection => 'Calendario';

  @override
  String get settingsNotificationsContactsSection =>
      'Notificaciones y contactos';

  @override
  String get settingsAppSection => 'Aplicación';

  @override
  String get inventoryTitle => 'Inventario';
}
