class Group {
  final String? groupId;
  final String name;
  final String? description;
  final String? ownerId;
  final String? inviteCode;
  final int? memberCount;
  final int? createdAt;
  final int? joinedAt;
  final String currentUserRole; // 新增：当前用户的角色 (owner, admin, member)

  Group({
    this.groupId,
    required this.name,
    this.description,
    this.ownerId,
    this.inviteCode,
    this.memberCount,
    this.createdAt,
    this.joinedAt,
    this.currentUserRole = 'member', // 默认设为普通成员
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'createdAt': createdAt,
      'joinedAt': joinedAt,
      'currentUserRole': currentUserRole,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      ownerId: json['ownerId']?.toString(),
      inviteCode: json['inviteCode']?.toString(),
      memberCount: json['memberCount'] as int?,
      createdAt: json['createdAt'] as int?,
      joinedAt: json['joinedAt'] as int?,
      currentUserRole: json['currentUserRole']?.toString() ?? 'member',
    );
  }
}
