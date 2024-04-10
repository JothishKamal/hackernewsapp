import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

import 'package:hackernews/models/comment.dart';

class StoryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> result;
  const StoryDetailsPage({super.key, required this.result});

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
                '${result['title']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
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
                      onTap: () => _launchURL(result['url']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          '${result['url']}',
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
                    '${result['descendants']}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  )
                ],
              ),
            ),
            _buildComments(result['kids'], 0),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    await FlutterWebBrowser.openWebPage(url: url);
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
                    Text(
                      comment.by,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
