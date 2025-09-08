import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_info.g.dart';

/// Information about a user session
@JsonSerializable()
class SessionInfo extends Equatable {
  /// Session ID
  final String sessionId;
  
  /// Device information
  final String deviceInfo;
  
  /// IP address
  final String? ipAddress;
  
  /// Location (if available)
  final String? location;
  
  /// When the session was created
  final DateTime createdAt;
  
  /// When the session was last active
  final DateTime lastActiveAt;
  
  /// Whether this is the current session
  final bool isCurrent;
  
  /// User agent string
  final String? userAgent;

  const SessionInfo({
    required this.sessionId,
    required this.deviceInfo,
    this.ipAddress,
    this.location,
    required this.createdAt,
    required this.lastActiveAt,
    this.isCurrent = false,
    this.userAgent,
  });

  /// Create SessionInfo from JSON
  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);

  /// Convert SessionInfo to JSON
  Map<String, dynamic> toJson() => _$SessionInfoToJson(this);

  /// Create a copy with updated values
  SessionInfo copyWith({
    String? sessionId,
    String? deviceInfo,
    String? ipAddress,
    String? location,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isCurrent,
    String? userAgent,
  }) {
    return SessionInfo(
      sessionId: sessionId ?? this.sessionId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isCurrent: isCurrent ?? this.isCurrent,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  /// Get display text for session duration
  String get sessionDurationText {
    final duration = DateTime.now().difference(createdAt);
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get display text for last active time
  String get lastActiveText {
    final duration = DateTime.now().difference(lastActiveAt);
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Active now';
    }
  }

  @override
  List<Object?> get props => [
        sessionId,
        deviceInfo,
        ipAddress,
        location,
        createdAt,
        lastActiveAt,
        isCurrent,
        userAgent,
      ];
}
