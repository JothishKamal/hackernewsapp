import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hackernews/pages/storypage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflinePage extends StatefulWidget {
  final Set<int> offlineStories;
  final Map<int, Map<String, dynamic>> storiesMap;
  final Function(int, Map<String, dynamic>) updateOfflineStoriesMap;

  const OfflinePage({
    super.key,
    required this.offlineStories,
    required this.storiesMap,
    required this.updateOfflineStoriesMap,
  });

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  @override
  Widget build(BuildContext context) {
    List<int> offlineStoryIds = widget.offlineStories.toList();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: offlineStoryIds.isEmpty
          ? const Center(
              child: Text(
                'No stories for offline reading',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            )
          : ListView.builder(
              itemCount: offlineStoryIds.length,
              itemBuilder: (context, index) {
                int storyId = offlineStoryIds[index];
                Map<String, dynamic>? story = widget.storiesMap[storyId];
                if (story == null) {
                  return Container();
                }

                bool isOffline = widget.offlineStories.contains(storyId);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StoryDetailsPage(result: story, isOffline: true),
                      ),
                    );
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Column(
                        children: [
                          const Icon(Icons.offline_bolt),
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
                                icon: Icon(isOffline
                                    ? Icons.cloud_done
                                    : Icons.cloud_download),
                                onPressed: () {
                                  _toggleOffline(storyId);
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

  void _toggleOffline(int storyId) {
    setState(() {
      if (widget.offlineStories.contains(storyId)) {
        widget.offlineStories.remove(storyId);
        widget.storiesMap.remove(storyId);
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('offlineStory_$storyId');
        });
      } else {
        widget.offlineStories.add(storyId);
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(
              'offlineStory_$storyId', jsonEncode(widget.storiesMap[storyId]));
        });
      }
    });
  }
}
