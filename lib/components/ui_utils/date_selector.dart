import 'package:flutter/material.dart';

class DateSelector {
  static Future<void> selectDate(
      BuildContext context,
      bool isFromDate,
      DateTime? fromDate,
      DateTime? toDate,
      Function setState,
      String? selectedCollection,
      Function fetchMessages) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (fromDate ?? DateTime.now())
          : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
      if (selectedCollection != null) {
        fetchMessages();
      }
    }
  }
}
