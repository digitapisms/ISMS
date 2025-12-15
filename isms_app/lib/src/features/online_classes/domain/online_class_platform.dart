/// Supported online class platforms
enum OnlineClassPlatform {
  zoom,
  googleMeet,
  microsoftTeams,
  custom,
}

/// Extension methods for OnlineClassPlatform
extension OnlineClassPlatformX on OnlineClassPlatform {
  /// Get display name for the platform
  String get displayName {
    switch (this) {
      case OnlineClassPlatform.zoom:
        return 'Zoom';
      case OnlineClassPlatform.googleMeet:
        return 'Google Meet';
      case OnlineClassPlatform.microsoftTeams:
        return 'Microsoft Teams';
      case OnlineClassPlatform.custom:
        return 'Custom Platform';
    }
  }

  /// Get icon asset path for the platform
  String get iconAsset {
    switch (this) {
      case OnlineClassPlatform.zoom:
        return 'assets/icons/zoom.png';
      case OnlineClassPlatform.googleMeet:
        return 'assets/icons/google_meet.png';
      case OnlineClassPlatform.microsoftTeams:
        return 'assets/icons/teams.png';
      case OnlineClassPlatform.custom:
        return 'assets/icons/video.png';
    }
  }

  /// Check if platform requires API integration
  bool get requiresApiIntegration {
    switch (this) {
      case OnlineClassPlatform.zoom:
      case OnlineClassPlatform.googleMeet:
      case OnlineClassPlatform.microsoftTeams:
        return true;
      case OnlineClassPlatform.custom:
        return false;
    }
  }

  /// Get platform documentation URL
  String get documentationUrl {
    switch (this) {
      case OnlineClassPlatform.zoom:
        return 'https://marketplace.zoom.us/docs';
      case OnlineClassPlatform.googleMeet:
        return 'https://developers.google.com/meet';
      case OnlineClassPlatform.microsoftTeams:
        return 'https://docs.microsoft.com/en-us/microsoftteams/platform';
      case OnlineClassPlatform.custom:
        return '';
    }
  }
}