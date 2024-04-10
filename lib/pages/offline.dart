import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  final Set<int> offlineStories;
  final Map<int, Map<String, dynamic>> storiesMap;

  const OfflinePage({super.key, required this.offlineStories, required this.storiesMap});


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}