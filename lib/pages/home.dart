import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> sortByList = ['Top', 'New', 'Best'];
  String? sortBy = 'New';
  List<dynamic> stories = [];

  @override
  void initState() {
    super.initState();
    _fetchStories(sortBy);
  }

  void _fetchStories(String? sortBy) async {
    final response = await http.get(Uri.parse(
        'https://hacker-news.firebaseio.com/v0/${sortBy!.toLowerCase()}stories.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        stories = data.cast<dynamic>();
      });
    } else {
      throw Exception('Failed to fetch stories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchField(),
            const SizedBox(
              height: 20,
            ),
            _sortByDB(),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: ListView.separated(
                itemCount: stories.length,
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Divider(),
                ),
                itemBuilder: (context, index) {
                  return _storyCard(index);
                },
              ),
            ),
          ],
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
                sortBy = value;
              });
              _fetchStories(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _storyCard(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          'Story Title ${stories[index]}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('By: Author $index'),
        onTap: () {},
      ),
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
