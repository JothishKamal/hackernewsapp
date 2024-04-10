import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

class StoryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> result;
  const StoryDetailsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: _appBar(),
      body: Center(
        child: Column(
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
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Text(
                          '${result['url']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    ));
  }

  Future<void> _launchURL(String url) async {
    await FlutterWebBrowser.openWebPage(url: url);
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
