// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'KLMS';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabTasks => 'Devoirs';

  @override
  String get tabPages => 'Pages';

  @override
  String get tabTimetable => 'Emploi du temps';

  @override
  String get tabSettings => 'Réglages';

  @override
  String lastUpdated(String time) {
    return 'Dernière mise à jour : $time';
  }

  @override
  String get neverUpdated => 'Jamais mis à jour';

  @override
  String get refreshNow => 'Actualiser';

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String get upcomingTasks => 'Devoirs à venir';

  @override
  String get homeNextClass => 'Prochain cours';

  @override
  String get homeCurrentClass => 'Cours en cours';

  @override
  String get homeNoClass => 'Aucun cours à venir';

  @override
  String get homeThenLabel => 'Ensuite';

  @override
  String get syncLog => 'Journal de synchronisation';

  @override
  String get syncLogDesc =>
      'Vérifier si l\'actualisation en arrière-plan fonctionne';

  @override
  String get syncLogEmpty => 'Aucune entrée';

  @override
  String get syncLogClear => 'Effacer le journal';

  @override
  String get googleAccount => 'Compte Google';

  @override
  String get googleNotConnected => 'Non connecté';

  @override
  String get googleConnect => 'Connecter un compte Google';

  @override
  String get googleDisconnect => 'Déconnecter';

  @override
  String get googleDisconnectConfirm =>
      'La déconnexion supprime l\'agenda et la liste de tâches créés par cette application. Continuer ?';

  @override
  String get recentAnnouncements => 'Annonces récentes';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get noTasks => 'Aucun devoir';

  @override
  String get noAnnouncements => 'Aucune annonce';

  @override
  String get notLoggedIn => 'Non connecté à KLMS';

  @override
  String get loginPrompt =>
      'Connectez-vous pour récupérer vos devoirs et cours. Votre identifiant et mot de passe ne sont jamais enregistrés.';

  @override
  String get loginButton => 'Se connecter à KLMS';

  @override
  String get loginTitle => 'Connexion KLMS';

  @override
  String get loginSuccess => 'Connecté';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm =>
      'Se déconnecter ? Les identifiants de session enregistrés seront supprimés.';

  @override
  String get loggedInAs => 'Connecté';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterIncomplete => 'À faire';

  @override
  String get filterCompleted => 'Terminés';

  @override
  String get filterHidden => 'Masqués';

  @override
  String get markComplete => 'Marquer comme terminé';

  @override
  String get markIncomplete => 'Marquer comme non terminé';

  @override
  String dueAt(String time) {
    return 'Échéance : $time';
  }

  @override
  String get noDueDate => 'Sans échéance';

  @override
  String get completedOnLms => 'Rendu sur le LMS';

  @override
  String get completedByUser => 'Terminé manuellement';

  @override
  String get conflictWarning =>
      'Marqué terminé manuellement, mais non rendu sur le LMS';

  @override
  String get conflictNotificationTitle => 'Devoir non rendu';

  @override
  String conflictNotificationBody(String task) {
    return '« $task » est marqué terminé, mais non rendu sur le LMS';
  }

  @override
  String get deadlineNotificationTitle => 'Échéance proche';

  @override
  String deadlineNotificationBody(String task, String time) {
    return '« $task » est à rendre à $time';
  }

  @override
  String get announcementNotificationTitle => 'Nouvelle annonce';

  @override
  String get courses => 'Cours';

  @override
  String get modules => 'Modules';

  @override
  String get announcements => 'Annonces';

  @override
  String get assignments => 'Devoirs';

  @override
  String get grades => 'Notes';

  @override
  String get noModules => 'Aucun module';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get openOnLms => 'Ouvrir sur le LMS';

  @override
  String points(String points) {
    return '$points pts';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get noClassToday => 'Pas de cours aujourd\'hui';

  @override
  String get nextClass => 'Prochain cours';

  @override
  String period(int n) {
    return 'Période $n';
  }

  @override
  String get settings => 'Réglages';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get themeMode => 'Thème';

  @override
  String get themeSystem => 'Suivre le système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Suivre le système';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get announcementNotifications => 'Notifications d\'annonces';

  @override
  String get announcementNotificationsDesc => 'Notifier les nouvelles annonces';

  @override
  String get deadlineReminder => 'Rappels d\'échéance';

  @override
  String get deadlineReminderDesc =>
      'Notifier avant l\'échéance des devoirs non terminés';

  @override
  String get reminderTiming => 'Moment du rappel';

  @override
  String reminderTimingValue(int h, int m) {
    return '${h}h ${m}min avant l\'échéance';
  }

  @override
  String get hoursUnit => 'h';

  @override
  String get minutesUnit => 'min';

  @override
  String get minutesBeforeUnit => 'min avant';

  @override
  String get excludeApplyToList => 'Masquer aussi dans la liste';

  @override
  String get excludeApplyToListDesc =>
      'Si désactivé, les exclusions ne s\'appliquent qu\'aux rappels';

  @override
  String get close => 'Fermer';

  @override
  String get excludeWords => 'Mots exclus';

  @override
  String get excludeWordsDesc =>
      'Ignorer les devoirs dont le titre contient ces mots';

  @override
  String get addWord => 'Ajouter un mot';

  @override
  String get excludeCourses => 'Cours exclus';

  @override
  String get excludeCoursesDesc => 'Ignorer les devoirs des cours sélectionnés';

  @override
  String get sectionCourses => 'Cours';

  @override
  String get courseNicknames => 'Surnoms des cours';

  @override
  String get courseNicknamesDesc => 'Affiché comme [surnom] devant les titres';

  @override
  String get nicknameHint => 'Surnom (ex. Jexp)';

  @override
  String get sectionTimetable => 'Emploi du temps';

  @override
  String get timetableSettings => 'Réglages de l\'emploi du temps';

  @override
  String get timetableDays => 'Jours';

  @override
  String timetableDaysValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String get periodsPerDay => 'Créneaux par jour';

  @override
  String get periodTimes => 'Horaires des créneaux';

  @override
  String get startTime => 'Début';

  @override
  String get endTime => 'Fin';

  @override
  String get sectionSync => 'Synchronisation';

  @override
  String get backgroundSync => 'Synchronisation en arrière-plan';

  @override
  String get backgroundSyncDesc =>
      'Récupère automatiquement devoirs et annonces même si l\'app est fermée (requis pour les notifications d\'annonces)';

  @override
  String get syncIntervalOff => 'Désactivée';

  @override
  String everyMinutes(int m) {
    return 'Toutes les $m min';
  }

  @override
  String everyHours(int h) {
    return 'Toutes les $h h';
  }

  @override
  String get iosSyncNote =>
      'Sur iOS, l\'intervalle réel est décidé par le système (selon l\'utilisation)';

  @override
  String get googleCalendarSync => 'Synchronisation Google Agenda';

  @override
  String get googleCalendarSyncDesc =>
      'Ajoute les échéances des devoirs non terminés à votre propre Google Agenda';

  @override
  String get googleTasksSync => 'Synchroniser avec Google Tasks';

  @override
  String get googleTasksSyncDesc =>
      'Ajoute les devoirs non terminés à une liste Google Tasks dédiée';

  @override
  String googleCalendarConnected(String email) {
    return 'Connecté : $email';
  }

  @override
  String get googleCalendarDisconnect =>
      'Déconnecter (supprime aussi les événements créés)';

  @override
  String get googleCalendarConnectFailed =>
      'Échec de la connexion à votre compte Google';

  @override
  String get sectionAccount => 'Compte';

  @override
  String get accessToken => 'Jeton d\'accès (avancé)';

  @override
  String get accessTokenDesc =>
      'Saisissez un jeton généré dans les réglages KLMS';

  @override
  String get sectionAbout => 'À propos';

  @override
  String get contact => 'Contact';

  @override
  String get licenses => 'Licences';

  @override
  String get version => 'Version';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Réessayer';
}
