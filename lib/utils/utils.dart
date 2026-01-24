part of axis_dashboard;

class GenericCache<T> {
  final Map<String, T> registry = {};
  final FutureOr<T> Function(String id) operation;

  GenericCache(this.operation);

  Future<T> get(String id) async {
    if (registry.containsKey(id)) {
      return registry[id]!;
    } else {
      return registry[id] = await operation(id);
    }
  }
}
