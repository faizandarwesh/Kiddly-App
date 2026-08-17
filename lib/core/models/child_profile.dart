/// A single child's profile: identity plus collected rewards and progress.
///
/// Everything is stored locally (see ProfileService) — no child data ever
/// leaves the device.
class ChildProfile {
  final String id;
  String name;
  String avatar; // an emoji, e.g. 🐰
  int stars;
  int rainbows;
  int hearts;

  /// Ids of activity "wins" completed, used for gentle progress tracking.
  Set<String> completed;

  ChildProfile({
    required this.id,
    required this.name,
    this.avatar = '🐰',
    this.stars = 0,
    this.rainbows = 0,
    this.hearts = 0,
    Set<String>? completed,
  }) : completed = completed ?? <String>{};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'stars': stars,
        'rainbows': rainbows,
        'hearts': hearts,
        'completed': completed.toList(),
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String? ?? '🐰',
        stars: json['stars'] as int? ?? 0,
        rainbows: json['rainbows'] as int? ?? 0,
        hearts: json['hearts'] as int? ?? 0,
        completed: ((json['completed'] as List?)?.cast<String>() ?? const [])
            .toSet(),
      );
}
