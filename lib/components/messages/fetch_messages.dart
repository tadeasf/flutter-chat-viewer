import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../utils/api_db/api_service.dart';
import '../../stores/store_provider.dart';

Future<void> fetchMessages(String? selectedCollection, DateTime? fromDate,
    DateTime? toDate, Function setState, Function setMessages,
    {required BuildContext context}) async {
  if (selectedCollection == null) return;

  // Get the store from context
  final store = StoreProvider.of(context).collectionStore;

  // Set message loading to true
  store.setMessageLoading(true);

  try {
    final loadedMessages = await ApiService.fetchMessages(
      selectedCollection,
      fromDate:
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null,
      toDate: toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null,
    );
    setMessages(loadedMessages);
    store.setMessageLoading(false);
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching messages: $e');
    }
    store.setMessageLoading(false);
  }
}
