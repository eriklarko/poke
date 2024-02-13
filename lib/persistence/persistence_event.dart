abstract class PersistenceEvent {
  // TODO: Rename
  // Meant to contain which reminder list item is being referenced in the event
  // In the water plant case it's using `water-frank`, which comes from `action.equalityKey`
  final String key;

  PersistenceEvent(this.key);
}

class Added extends PersistenceEvent {
  Added(String key) : super(key);
}

class Updating extends PersistenceEvent {
  Updating(String key) : super(key);
}
