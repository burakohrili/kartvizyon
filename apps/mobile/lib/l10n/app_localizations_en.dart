// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KartVizyon AI';

  @override
  String get summaryTab => 'Summary';

  @override
  String get customersTab => 'Customers';

  @override
  String get visitsTab => 'Visits';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get fieldSummary => 'Today\'s field summary';
}
