class Clock {
  DateTime _dt;
  final Duration _defaultDuration;

  Clock._(this._dt, this._defaultDuration);

  factory Clock({DateTime? initialTime, Duration? defaultDuration}) {
    return Clock._(
      initialTime ?? DateTime.now(),
      defaultDuration ?? const Duration(minutes: 1),
    );
  }

  DateTime next({Duration? advanceBy}) {
    final toReturn = _dt;
    _dt = _dt.add(advanceBy ?? _defaultDuration);
    return toReturn;
  }
}
