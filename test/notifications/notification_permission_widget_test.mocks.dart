// Mocks generated by Mockito 5.4.2 from annotations
// in poke/test/notifications/notification_permission_widget_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:poke/models/action.dart' as _i4;
import 'package:poke/notifications/notification_service.dart' as _i2;
import 'package:poke/persistence/serializable_event_data.dart' as _i5;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [NotificationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNotificationService extends _i1.Mock
    implements _i2.NotificationService {
  @override
  _i3.FutureOr<_i2.PermissionResponse> hasPermissionToSendNotifications() =>
      (super.noSuchMethod(
        Invocation.method(
          #hasPermissionToSendNotifications,
          [],
        ),
        returnValue: _i3.Future<_i2.PermissionResponse>.value(
            _i2.PermissionResponse.hasNotChosen),
        returnValueForMissingStub: _i3.Future<_i2.PermissionResponse>.value(
            _i2.PermissionResponse.hasNotChosen),
      ) as _i3.FutureOr<_i2.PermissionResponse>);

  @override
  _i3.FutureOr<void> scheduleReminder(
    _i4.Action<_i5.SerializableEventData?>? action,
    DateTime? dueDate,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #scheduleReminder,
          [
            action,
            dueDate,
          ],
        ),
        returnValueForMissingStub: null,
      ) as _i3.FutureOr<void>);

  @override
  _i3.FutureOr<Iterable<(String, DateTime)>> getAllScheduledNotifications() =>
      (super.noSuchMethod(
        Invocation.method(
          #getAllScheduledNotifications,
          [],
        ),
        returnValue: _i3.Future<Iterable<(String, DateTime)>>.value(
            <(String, DateTime)>[]),
        returnValueForMissingStub:
            _i3.Future<Iterable<(String, DateTime)>>.value(
                <(String, DateTime)>[]),
      ) as _i3.FutureOr<Iterable<(String, DateTime)>>);
}
