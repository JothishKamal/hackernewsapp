import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hackernews/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails(widget.userId);
  }

  Future<User> _fetchUserDetails(String userId) async {
    final response = await http.get(
        Uri.parse('https://hacker-news.firebaseio.com/v0/user/$userId.json'));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user details: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _appBar(),
        body: FutureBuilder<User>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final User user = snapshot.data!;
              return _buildBody(user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody(User user) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: 320,
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    user.id,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: Text(
                    'Karma: ${user.karma}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: Text(
                    'Submissions: ${user.submitted.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Created at ${DateFormat("MMMM d, yyyy 'at' h:mm a").format(DateTime.fromMillisecondsSinceEpoch(user.created * 1000))}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
        'User Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
