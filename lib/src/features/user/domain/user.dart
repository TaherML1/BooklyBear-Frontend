// A helper class for the 'settings' object
class UserSettings {
  final String theme;
  final bool emailNotifications;
  final bool pushNotifications;

  UserSettings({
    required this.theme,
    required this.emailNotifications,
    required this.pushNotifications,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] ?? 'system',
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
    );
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  
  // --- 2. Public Profile Fields ---
  final String? bio;
  final String? avatarUrl;
  final String? profileBannerUrl; // For later

  // --- 3. Gamification Fields ---
  final int points;
  final int level;
  final int currentStreak;
  final List<String> achievementIds;

  // --- 4. App Settings ---
  final UserSettings settings;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.profileBannerUrl,
    required this.points,
    required this.level,
    required this.currentStreak,
    required this.achievementIds,
    required this.settings,
  });

  // Updated factory to parse all new fields from the backend
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      
      // Nullable fields
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      profileBannerUrl: json['profileBannerUrl'] as String?,

      // Gamification
      points: json['points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['currentStreak'] as int? ?? 0,
      achievementIds: (json['achievementIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),

      // Settings (using our helper class)
      settings: json['settings'] != null 
        ? UserSettings.fromJson(json['settings'])
        : UserSettings.fromJson({}), // Provide default settings if null
    );
  }
}