class ChatNuUser {
  const ChatNuUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'.toUpperCase();
  }
}
