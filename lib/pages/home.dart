import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> sortByList = ['Top', 'New', 'Best'];
  String? sortMode;

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
            _sortByDB()
          ],
        ),
      ),
    );
  }

  Container _sortByDB() {
    return Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey)),
            child: DropdownButton<String>(
                hint: const Text('Sort By'),
                underline: Container(),
                value: sortMode,
                items: sortByList.map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    sortMode = value;
                  });
                }),
          );
  }

  Container _searchField() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 10, right: 10),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            color: const Color(0xFF1D1617).withOpacity(0.11),
            blurRadius: 20,
            spreadRadius: 0)
      ]),
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
              //borderSide: BorderSide.none
            )),
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
