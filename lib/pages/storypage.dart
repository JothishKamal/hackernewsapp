import 'dart:convert';
import 'package:hackernews/pages/userpage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:intl/intl.dart';

import 'package:hackernews/models/comment.dart';

class StoryDetailsPage extends StatefulWidget {
  final Map<String, dynamic> result;
  final bool isOffline;
  const StoryDetailsPage(
      {super.key, required this.result, required this.isOffline});

  @override
  State<StoryDetailsPage> createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends State<StoryDetailsPage> {
  void _launchURL(String url) async {
    await FlutterWebBrowser.openWebPage(url: url);
  }

  void _onUserTap(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsPage(
          userId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _appBar(),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                '${widget.result['title']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => widget.isOffline ? {} : _onUserTap(widget.result['by']),
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  'By ${widget.result['by']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  const Text(
                    'URI: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchURL(widget.result['url']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          '${widget.result['url']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _commentsSection(),
          ],
        ),
      ),
    );
  }

  Column _commentsSection() {
    return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    const Text(
                      'Comments ',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    Text(
                      '${widget.result['descendants']}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey),
                    )
                  ],
                ),
              ),
              if (!widget.isOffline &&
                  widget.result['kids'] != null &&
                  (widget.result['kids'] as List).isNotEmpty)
                _buildComments(widget.result['kids'], 0),
            ],
          );
  }

  Widget _buildComments(List<dynamic>? kids, int indentLevel) {
    if (kids == null || kids.isEmpty) {
      return Container();
    }

    return FutureBuilder<List<Comment>>(
      future: _getCommentsByIds(kids, indentLevel),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: snapshot.data!.map<Widget>((comment) {
              return _buildComment(comment);
            }).toList(),
          );
        }
      },
    );
  }

  Future<List<Comment>> _getCommentsByIds(
      List<dynamic> ids, int indentLevel) async {
    List<Future<Comment>> futures = [];
    for (var id in ids) {
      futures.add(_getCommentById(id, indentLevel));
    }
    return await Future.wait(futures);
  }

  Future<Comment> _getCommentById(int id, int indentLevel) async {
    final response = await http
        .get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Comment.fromJson(data, indentLevel);
    } else {
      throw Exception('Failed to load comment');
    }
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < comment.indentLevel; i++)
                Container(
                  width: 1.0,
                  height: 20.0,
                  color: Colors.grey,
                  margin: const EdgeInsets.only(right: 10.0),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _onUserTap(comment.by),
                      child: Text(
                        '${comment.by} - ${DateFormat("MMMM d, yyyy 'at' h:mm a").format(DateTime.fromMillisecondsSinceEpoch(comment.time * 1000))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Html(data: comment.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildComments(comment.kids, comment.indentLevel + 1),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: const Color.fromRGBO(255, 100, 4, 1),
      title: const Text(
        'Story Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
