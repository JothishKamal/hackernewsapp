import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hackernews/pages/favorites.dart';
import 'package:hackernews/pages/offline.dart';
import 'package:hackernews/pages/storypage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:connectivity/connectivity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String sortBy;
  late TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> sortByList = ['Top', 'New', 'Best'];
  final List<int> stories = [];
  final Map<int, Map<String, dynamic>> storiesMap = {};
  Map<int, Map<String, dynamic>> offlineStoriesMap = {};
  int numberOfStoriesToShow = 20;
  int _selectedIndex = 0;
  Set<int> favoriteStories = <int>{};
  Set<int> offlineStories = <int>{};
  List<int> storiesToShow = [];
  bool isOffline = true;

  @override
  void initState() {
    super.initState();
    sortBy = 'New';
    _checkConnectivity();
    _loadFavoriteStories();
    _loadOfflineStories();
    searchController = TextEditingController();

    if (!isOffline) _fetchStories(sortBy);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreStories();
      }
    });
  }

  void _loadFavoriteStories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteStoriesList = prefs.getStringList('favoriteStories');
    if (favoriteStoriesList != null) {
      setState(() {
        favoriteStories =
            favoriteStoriesList.map((id) => int.parse(id)).toSet();
      });
    }
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

  void _updateOfflineStoriesMap(int storyId, Map<String, dynamic> storyData) {
    setState(() {
      offlineStoriesMap[storyId] = storyData;
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

  void _toggleFavorite(int storyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteStories.contains(storyId)) {
        favoriteStories.remove(storyId);
      } else {
        favoriteStories.add(storyId);
      }
      prefs.setStringList('favoriteStories',
          favoriteStories.map((id) => id.toString()).toList());
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
        _showError('Error caching webpage: $e');
        offlineStories.remove(storyId);
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
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  Drawer _buildDrawer() {
    return Drawer(
      child: drawerList(),
    );
  }

  Column drawerList() {
    return Column(
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

    switch (_selectedIndex) {
      case 0:
        storiesToShow = stories.take(numberOfStoriesToShow).toList();
        break;
      case 1:
        storiesToShow = stories
            .where((storyId) => favoriteStories.contains(storyId))
            .toList();
        break;
      case 2:
        storiesToShow = offlineStories.toList();
        break;
      default:
        storiesToShow = [];
    }

    if (searchController.text.isNotEmpty) {
      storiesToShow = storiesToShow.where((storyId) {
        Map<String, dynamic>? story = storiesMap[storyId];
        return story != null &&
            story['title']
                .toLowerCase()
                .contains(searchController.text.toLowerCase());
      }).toList();
    }

    if (_selectedIndex == 0) {
      return homePage(storiesToShow);
    } else if (_selectedIndex == 1) {
      return FavoritesPage(
        favoriteStories: favoriteStories,
        storiesMap: storiesMap,
      );
    } else if (_selectedIndex == 2) {
      return OfflinePage(
        offlineStories: offlineStories,
        storiesMap: offlineStoriesMap,
        updateOfflineStoriesMap: _updateOfflineStoriesMap,
      );
    } else {
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
        controller: searchController,
        onChanged: (value) {
          setState(() {});
        },
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
              numberOfStoriesToShow = 20;
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
}
