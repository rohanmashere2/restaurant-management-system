/// Kitchen / line lifecycle for KDS and order visibility.
abstract final class OrderLineStatus {
  static const queued = 'queued';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const done = 'done';

  static String fromLine(Map<String, dynamic> line) {
    final s = line['kitchenStatus']?.toString();
    if (s == preparing || s == ready || s == done) {
      return s!;
    }
    return queued;
  }
}
