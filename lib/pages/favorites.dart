import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  final Set<int> favoriteStories;
  final Map<int, Map<String, dynamic>> storiesMap;

  const FavoritesPage({super.key, required this.favoriteStories, required this.storiesMap});


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}