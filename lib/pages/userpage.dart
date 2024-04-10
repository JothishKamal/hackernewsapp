import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hackernews/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  const UserDetailsPage({Key? key, required this.userId}) : super(key: key);

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

  Widget _buildBody(User user) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User: ${user.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Karma: ${user.karma}',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Submissions: ${user.submitted.length}',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Created: ${DateFormat("MMMM d, yyyy 'at' h:mm a").format(DateTime.fromMillisecondsSinceEpoch(user.created * 1000))}',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
