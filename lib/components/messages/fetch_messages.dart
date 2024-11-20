import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../utils/api_db/api_service.dart';

Future<void> fetchMessages(
    String? selectedCollection,
    DateTime? fromDate,
    DateTime? toDate,
    Function setState,
    Function setLoading,
    Function setMessages) async {
  if (selectedCollection == null) return;
  setLoading(true);
  try {
    final loadedMessages = await ApiService.fetchMessages(
      selectedCollection,
      fromDate:
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null,
      toDate: toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null,
    );
    setMessages(loadedMessages);
    setLoading(false);
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching messages: $e');
    }
    setLoading(false);
  }
}
