class Story {
  final String by;
  final int descendants;
  final int id;
  final List<int> kids;
  final int score;
  final int time;
  final String title;
  final String type;
  final String url;

  Story({
    required this.by,
    required this.descendants,
    required this.id,
    required this.kids,
    required this.score,
    required this.time,
    required this.title,
    required this.type,
    required this.url,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      by: json['by'] ?? '',
      descendants: json['descendants'] ?? 0,
      id: json['id'] ?? 0,
      kids: json['kids'] != null ? List<int>.from(json['kids']) : [],
      score: json['score'] ?? 0,
      time: json['time'] ?? 0,
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'by': by,
      'descendants': descendants,
      'id': id,
      'kids': kids,
      'score': score,
      'time': time,
      'title': title,
      'type': type,
      'url': url,
    };
  }
}
