import 'package:flutter/material.dart';
import 'package:hackernews/pages/storypage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  final Set<int> favoriteStories;
  final Map<int, Map<String, dynamic>> storiesMap;

  const FavoritesPage({
    super.key,
    required this.favoriteStories,
    required this.storiesMap,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    List<int> favoriteStoryIds = widget.favoriteStories.toList();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: favoriteStoryIds.isEmpty
          ? const Center(
              child: Text(
                'No favorites',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            )
          : ListView.builder(
              itemCount: favoriteStoryIds.length,
              itemBuilder: (context, index) {
                int storyId = favoriteStoryIds[index];
                Map<String, dynamic> story = widget.storiesMap[storyId]!;
                bool isFavorite = widget.favoriteStories.contains(storyId);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailsPage(
                          result: story,
                          isOffline: false,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Column(
                        children: [
                          const Icon(Icons.expand_less),
                          const SizedBox(height: 2.5),
                          Text(
                            story['score'].toString(),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      title: Text(
                        "${story['title']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'by ${story['by']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${story['descendants']} comments',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border),
                                onPressed: () {
                                  _toggleFavorite(storyId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _toggleFavorite(int storyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (widget.favoriteStories.contains(storyId)) {
        widget.favoriteStories.remove(storyId);
      } else {
        widget.favoriteStories.add(storyId);
      }
      prefs.setStringList('favoriteStories',
          widget.favoriteStories.map((id) => id.toString()).toList());
    });
  }
}
