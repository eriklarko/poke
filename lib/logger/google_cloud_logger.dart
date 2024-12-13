import 'dart:async';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/persistence/environment_variables.dart';

// Define constants for authentication and project identification
// TODO: Put somewhere safe
const _serviceAccountCredentials = {
  "type": "service_account",
  "project_id": "plant-reminder-90745",
  "private_key_id": "0cf1c340537adee00aaa3ce461e629ce22aa13fb",
  "private_key": "FROM ENVIFIED .env FILE",
  "client_email": "poke-logger@plant-reminder-90745.iam.gserviceaccount.com",
  "client_id": "111476150673636714610",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url":
      "https://www.googleapis.com/robot/v1/metadata/x509/poke-logger%40plant-reminder-90745.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

final _projectId = _serviceAccountCredentials['project_id']!;

class GoogleCloudLogger extends PokeLogger {
  final Iterable<Level> levels;
  late final LoggingApi _loggingApi;
  bool _isSetup = false;

  GoogleCloudLogger({
    this.levels = const [Level.warning, Level.error, Level.fatal],
  });

  Future<void> initialize() async {
    if (_isSetup) return;

    // Authenticate using ServiceAccountCredentials and obtain an
    // AutoRefreshingAuthClient authorized client
    final saCreds = _serviceAccountCredentials;
    saCreds['private_key'] = Env.gcloudApiKey;

    final authClient = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(saCreds),
      [LoggingApi.loggingWriteScope],
    );

    _loggingApi = LoggingApi(authClient);
    _isSetup = true;
  }

  @override
  FutureOr<void> logAppForegrounded() {
    return log(Level.info, "app foregrounded");
  }

  @override
  FutureOr<void> doLog(
    Level level,
    PokeLogEntry log,
  ) async {
    if (!_isSetup) {
      throw Exception('Cloud Logging API is not setup');
    }

    if (!levels.contains(level)) {
      return;
    }

    final logEntry = LogEntry(
      jsonPayload: log.asMap(),
      severity: levelToSeverity(level).toString(),
      labels: {
        // Must match the project ID with the one in the JSON key file
        'project_id': _projectId,
        'level': level.name.toUpperCase(),
      },
      resource: MonitoredResource(type: 'global'),
    );

    final request = WriteLogEntriesRequest(
      logName: 'projects/$_projectId/logs/poke',
      entries: [logEntry],
    );
    await _loggingApi.entries.write(request);
  }

  /// FROM https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry
  /// Possible string values are:
  /// - "DEFAULT" : (0) The log entry has no assigned severity level.
  /// - "DEBUG" : (100) Debug or trace information.
  /// - "INFO" : (200) Routine information, such as ongoing status or
  /// performance.
  /// - "NOTICE" : (300) Normal but significant events, such as start up, shut
  /// down, or a configuration change.
  /// - "WARNING" : (400) Warning events might cause problems.
  /// - "ERROR" : (500) Error events are likely to cause problems.
  /// - "CRITICAL" : (600) Critical events cause more severe problems or
  /// outages.
  /// - "ALERT" : (700) A person must take an action immediately.
  /// - "EMERGENCY" : (800) One or more systems are unusable.
  String levelToSeverity(Level level) {
    switch (level) {
      case Level.trace:
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARNING';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'CRITICAL';
      default:
        return 'DEFAULT';
    }
  }
}
