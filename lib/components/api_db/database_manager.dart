import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'api_service.dart';
import 'dart:convert';

class DatabaseManager extends StatefulWidget {
  final VoidCallback refreshCollections;

  const DatabaseManager({super.key, required this.refreshCollections});

  @override
  DatabaseManagerState createState() => DatabaseManagerState();
}

class DatabaseManagerState extends State<DatabaseManager> {
  String currentDb = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentDb();
  }

  Future<void> fetchCurrentDb() async {
    try {
      final response =
          await ApiService.get('/current-db', headers: ApiService.headers);
      if (response.statusCode == 200) {
        setState(() {
          currentDb = json.decode(response.body)['current_db'];
        });
      } else {
        throw Exception('Failed to load current DB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current DB: $e');
      }
    }
  }

  Future<void> switchDbAndFetch() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await ApiService.post('/switch-db', headers: ApiService.headers);
      if (response.statusCode == 200) {
        await fetchCurrentDb();
        widget.refreshCollections();
      } else {
        throw Exception('Failed to switch DB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error switching DB: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height * 0.1, // 30% of the screen height
      child: Column(
        children: [
          Text('Current DB: $currentDb'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading ? null : switchDbAndFetch,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Switch DB'),
          ),
        ],
      ),
    );
  }
}
