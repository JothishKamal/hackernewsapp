class User {
  final int created;
  final String id;
  final int karma;
  final List<int> submitted;

  User({
    required this.created,
    required this.id,
    required this.karma,
    required this.submitted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      created: json['created'],
      id: json['id'],
      karma: json['karma'],
      submitted: List<int>.from(json['submitted']),
    );
  }
}
