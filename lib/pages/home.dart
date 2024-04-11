import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hackernews/pages/favorites.dart';
import 'package:hackernews/pages/offline.dart';
import 'package:hackernews/pages/storypage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// I dum

import 'package:connectivity/connectivity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String sortBy;
  final ScrollController _scrollController = ScrollController();
  final List<String> sortByList = ['Top', 'New', 'Best'];
  final List<int> stories = [];
  final Map<int, Map<String, dynamic>> storiesMap = {};
  Map<int, Map<String, dynamic>> offlineStoriesMap = {};
  int numberOfStoriesToShow = 10;
  int _selectedIndex = 0;
  Set<int> favoriteStories = <int>{};
  Set<int> offlineStories = <int>{};
  bool isOffline = true;

  @override
  void initState() {
    super.initState();
    sortBy = 'New';
    _checkConnectivity();
    _loadOfflineStories();

    if (!isOffline) _fetchStories(sortBy);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreStories();
      }
    });
  }

  void _updateOfflineStoriesMap(int storyId, Map<String, dynamic> storyData) {
    setState(() {
      offlineStoriesMap[storyId] = storyData;
    });
  }

  void _loadOfflineStories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<int> offlineStoriesSet = prefs
        .getKeys()
        .where((key) => key.startsWith('offlineStory_'))
        .map((key) => int.parse(key.split('_').last))
        .toSet();
    setState(() {
      offlineStories = offlineStoriesSet;
      offlineStoriesMap = Map.fromEntries(offlineStoriesSet.map((id) =>
          MapEntry(id, jsonDecode(prefs.getString('offlineStory_$id')!))));
    });
  }

  void _checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      if (result == ConnectivityResult.none) {
        isOffline = true;
      } else {
        isOffline = false;
        _fetchStories(sortBy);
      }
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.none) {
          isOffline = true;
        } else {
          isOffline = false;
          _fetchStories(sortBy);
        }
      });
    });
  }

  void _fetchStories(String sortBy) async {
    try {
      final response = await http.get(Uri.parse(
          'https://hacker-news.firebaseio.com/v0/${sortBy.toLowerCase()}stories.json'));
      if (response.statusCode == 200) {
        final List<int> data = List<int>.from(jsonDecode(response.body));
        setState(() {
          stories.addAll(data);
        });
      } else {
        _showError('Failed to fetch stories');
      }
    } on SocketException catch (_) {
      _showError(
          'Network is unreachable. Please check your internet connection.');
    } catch (e) {
      _showError('An error occurred while fetching stories: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadMoreStories() {
    setState(() {
      numberOfStoriesToShow += 10;
    });
  }

  void _toggleFavorite(int storyId) {
    setState(() {
      if (favoriteStories.contains(storyId)) {
        favoriteStories.remove(storyId);
      } else {
        favoriteStories.add(storyId);
      }
    });
  }

  void _toggleOffline(int storyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> storyDetails = storiesMap[storyId]!;
    String? storyContent;

    if (offlineStories.contains(storyId)) {
      offlineStories.remove(storyId);
      prefs.remove('offlineStory_$storyId');
      _updateOfflineStoriesMap(storyId, {});
    } else {
      try {
        offlineStories.add(storyId);
        storyContent = await _cacheWebpage(storyDetails['url']);
        storyDetails['content'] = storyContent;
        prefs.setString('offlineStory_$storyId', jsonEncode(storyDetails));
        _updateOfflineStoriesMap(storyId, storyDetails);
      } catch (e) {
        // Handle the error (e.g., show a SnackBar, log the error)
        _showError('Error caching webpage: $e');
        // Remove the story from offlineStories if caching fails
        offlineStories.remove(storyId);
        // Optionally, you could rethrow the error to propagate it up
        // throw e;
      }
    }
  }

  Future<String> _cacheWebpage(String url) async {
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _appBar(),
        drawer: _buildDrawer(),
        body: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favorites'),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: const Text('Offline Reading'),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Designed with ❤️ by Jo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isOffline) {
      if (_selectedIndex == 2) {
        return OfflinePage(
            offlineStories: offlineStories,
            storiesMap: offlineStoriesMap,
            updateOfflineStoriesMap: _updateOfflineStoriesMap);
      } else {
        return const Center(
            child: Text(
          "You're currently offline",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
        ));
      }
    }

    List<int> storiesToShow = stories.take(numberOfStoriesToShow).toList();

    switch (_selectedIndex) {
      case 0:
        return homePage(storiesToShow);
      case 1:
        return FavoritesPage(
          favoriteStories: favoriteStories,
          storiesMap: storiesMap,
        );
      case 2:
        return OfflinePage(
          offlineStories: offlineStories,
          storiesMap: offlineStoriesMap,
          updateOfflineStoriesMap: _updateOfflineStoriesMap,
        );
      default:
        return const Text('Error');
    }
  }

  Column homePage(List<int> storiesToShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: [
              _searchField(),
              const SizedBox(height: 20),
              _sortByDB(),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storiesToShow.length,
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Divider(),
                ),
                itemBuilder: (context, index) {
                  return _storyCard(storiesToShow[index]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _sortByDB() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            'Sort By: ',
            style: TextStyle(
              color: Color.fromRGBO(255, 100, 4, 1),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButton<String>(
            underline: Container(),
            value: sortBy,
            items: sortByList.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                sortBy = value!;
              });
              stories.clear();
              numberOfStoriesToShow = 10;
              _fetchStories(value!);
            },
          ),
        ),
      ],
    );
  }

  Widget _storyCard(int storyId) {
    if (!storiesMap.containsKey(storyId)) {
      return FutureBuilder<Map<String, dynamic>>(
        future: fetchStory(storyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final result = snapshot.data!;
            storiesMap[storyId] = result;
            return _buildStoryCard(result, storyId);
          }
        },
      );
    } else {
      return _buildStoryCard(storiesMap[storyId]!, storyId);
    }
  }

  void _onStoryTap(Map<String, dynamic> result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryDetailsPage(
          result: result,
          isOffline: false,
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> result, int storyId) {
    bool isFavorite = favoriteStories.contains(storyId);
    bool isOffline = offlineStories.contains(storyId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Column(
          children: [
            const Icon(Icons.expand_less),
            const SizedBox(height: 2.5),
            Text(
              result['score'].toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        title: Text(
          "${result['title']}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'by ${result['by']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '${result['descendants']} comments',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon:
                      Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  onPressed: () {
                    _toggleFavorite(storyId);
                  },
                ),
                IconButton(
                  icon:
                      Icon(isOffline ? Icons.cloud_done : Icons.cloud_download),
                  onPressed: () {
                    _toggleOffline(storyId);
                  },
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _onStoryTap(result);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> fetchStory(int id) async {
    final response = await http.get(
      Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch story');
    }
  }

  Container _searchField() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1617).withOpacity(0.11),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(0),
            child: Icon(Icons.search),
          ),
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(15),
          hintText: 'Search',
          hintStyle: const TextStyle(color: Color(0xffDDDADA), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: const Color.fromRGBO(255, 100, 4, 1),
      title: const Text(
        'Hacker News',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
