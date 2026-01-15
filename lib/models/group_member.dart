class GroupMember {
  final String userId;
  final String username;
  final String? avatar;
  final String groupRole; // 'owner', 'admin', 'member'
  final int? joinedAt;

  GroupMember({
    required this.userId,
    required this.username,
    this.avatar,
    required this.groupRole,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '未知用户',
      avatar: json['avatar']?.toString(),
      groupRole: json['groupRole']?.toString() ?? 'member',
      joinedAt: json['joinedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'groupRole': groupRole,
      'joinedAt': joinedAt,
    };
  }
}
