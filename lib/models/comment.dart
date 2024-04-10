class Comment {
  final String by;
  final int id;
  final List<int>? kids;
  final int time;
  final String text;
  final int indentLevel;

  Comment({
    required this.by,
    required this.id,
    required this.kids,
    required this.time,
    required this.text,
    required this.indentLevel,
  });

  factory Comment.fromJson(Map<String, dynamic> json, int indentLevel) {
    return Comment(
      by: json['by'] ?? '',
      id: json['id'] ?? 0,
      kids: json['kids'] != null ? List<int>.from(json['kids']) : null,
      time: json['time'] ?? 0,
      text: json['text'] ?? '',
      indentLevel: indentLevel,
    );
  }
}