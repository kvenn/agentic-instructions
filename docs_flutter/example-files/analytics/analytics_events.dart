import '../../../ping/utils/date_time_extensions.dart';
import '../ping/home/view_model/ping_home_view_model.dart';
import '../ping/map/markers/hang_spot/map_hang_spot_details.dart';
import '../ping/map/markers/marker_types.dart';
import '../ping/status/view/widgets/emoji_based_status.dart';
import '../schema/generated/fragments.graphql.dart';
import '../shared/share_destinations.dart';
import 'analytics.dart';
import 'analytics_pages.dart';
import 'analytics_param.dart';

extension AnalyticsEvents on Analytics {
  void logInviteClickEvent(AnalyticsPage page) =>
      logEvent('click invite', eventProperties: {'page': page.toShortString()});
  void logInviteLinkShared() => logEvent('shared invite link');

  /// Sends the current page along with the screenshot.
  void logScreenShotEvent(bool isAppOpen) {
    if (!isAppOpen) {
      return logEvent('unknown screenshot');
    }
    return logEvent(
      'screenshot',
      eventProperties: {'current page': currentPageName, ...?currentPageData},
    );
  }
}

extension OnboardingAnalytics on Analytics {
  void logOnboardingError(
    String errorMessage,
    String inputValue,
    String _,
  ) =>
      logEvent(
        'onboarding error',
        eventProperties: {
          'page': currentPageName,
          'error message': errorMessage,
          'input value': inputValue,
        },
      );
}

extension ProfilePictureAnalytics on Analytics {
  void uploadProfilePicture() => logEvent(
        'Upload new profile photo',
        eventProperties: {
          'page': currentPageName,
        },
      );
}

extension FriendActionAnalytics on Analytics {
  void logFriendActionEvent(String action, String toUserId) => logEvent(
        action,
        eventProperties: {'to user id': toUserId, 'page': currentPageName},
      );
}

extension PingLevelAnalytics on Analytics {
  void clickAddFriendIncentive(
    String action,
    String title,
    int level,
  ) =>
      logEvent(
        action,
        eventProperties: {
          'page': currentPageName,
          'title': title,
          'level': level,
        },
      );

  void clickClaimReward(
    String title,
    int level,
  ) =>
      logEvent(
        'click claim reward',
        eventProperties: {
          'page': currentPageName,
          'title': title,
          'level': level,
        },
      );
  void clickSeeGiftCard(
    String title,
    int level,
  ) =>
      logEvent(
        'click see gift card',
        eventProperties: {
          'page': currentPageName,
          'title': title,
          'level': level,
        },
      );
}

extension AccountSettingsAnalytics on Analytics {
  void logDetailsClickEvent(String section) => logEvent(
        'click account detail section',
        eventProperties: {'name': section},
      );

  void logDeleteAccountClickEvent() => logEvent('click delete account');

  void logPrivacyPolicyClick() => logEvent('click privacy policy');

  void logTOSClick() => logEvent('click terms of service');

  void logContactSupportClick() => logEvent('click contact support');

  void logReportBugClick() => logEvent('click report a bug');

  void logAccountDeleted() => logEvent('account deleted');
}

extension FeedActionAnalytics on Analytics {
  void logFeedUserActivityActionEvent(
    String type,
    String userId,
    String friendshipStatus,
  ) =>
      logEvent(
        'feed item action',
        eventProperties: {
          'type': type,
          'user id': userId,
          'friendship status': friendshipStatus,
        },
      );

  void logFeedItemClickEvent({
    required int index,
    required List<Fragment$MetadataField> metadata,
  }) =>
      logEvent(
        'click feed item',
        eventProperties: {
          'index': index,
          ...{
            for (final element in metadata)
              element.entityProperty: element.entityValue,
          },
        },
      );

  void logFeedItemShareEvent({
    required int index,
    required List<Fragment$MetadataField> metadata,
  }) =>
      logEvent(
        'feed item share',
        eventProperties: {
          'index': index,
          ...{
            for (final element in metadata)
              element.entityProperty: element.entityValue,
          },
        },
      );
}

extension InviteAnalytics on Analytics {
  void logShareProfileLink() => logEvent(
        'share profile link',
        eventProperties: {
          'destination': 'copy',
          // attibutes defined in airtable that might be used in the future
          // 'contact id': some contact id,
          // page: currentPageName
        },
      );

  void logInvitePromptClick(
    String listType,
    int listSize,
    String ctaCopy,
  ) =>
      logEvent(
        'invite prompt lick',
        eventProperties: {
          'list': listType,
          'list count': listSize,
          'cta copy': ctaCopy,
          'page': currentPageName,
        },
      );
}

extension CoachMarksAnalytics on Analytics {
  void logViewCoachMark(String type) =>
      logEvent('view coach mark', eventProperties: {'type': type});
  void logTapCoachMark(String type) =>
      logEvent('tap coach mark', eventProperties: {'type': type});
}

extension PingHomePageAnalytics on Analytics {
  void sendPing(
    Fragment$PingNotificationOption pingOption,
    String? analyticOrigin,
    bool hasUnlockedPinging,
    String? pingSentToIdentifier,
  ) =>
      logEvent(
        'send ping',
        eventProperties: {
          'is unlocked': hasUnlockedPinging,
          'origin': analyticOrigin,
          'page': currentPageName,
          'type': pingOption.analyticsLabel,
          AnalyticsParam.userIdKey: pingSentToIdentifier,
        },
      );

  void logSettingsClick() => logEvent('click settings');
  void logLevelExplainer({String? origin, String? briefTitle}) => logEvent(
        'click level',
        eventProperties: {
          'origin': origin,
          'brief title': briefTitle,
        },
      );

  void logToggleLocation({
    required bool location,
  }) =>
      logEvent(
        'toggle location',
        eventProperties: {
          'location value': location,
        },
      );

  void viewSettingConfirmationDialog({
    required String title,
  }) =>
      logEvent(
        'view setting confirmation dialog',
        eventProperties: {
          'setting': title,
        },
      );

  void logToggleNearbyNotifications({
    required bool nearbyNotification,
  }) =>
      logEvent(
        'toggle nearby notifications',
        eventProperties: {
          'nearby notification value': nearbyNotification,
        },
      );

  void logToggleLiveActivities({
    required bool isEnabled,
  }) =>
      logEvent(
        'toggle live activities',
        eventProperties: {
          'live activities value': isEnabled,
        },
      );

  void logToggleFriendsOrder({
    required FriendsSortOrder previousSortOrder,
    required FriendsSortOrder newSortOrder,
  }) =>
      logEvent(
        'toggle friend order',
        eventProperties: {
          'previous sort order': enumToString(previousSortOrder),
          'new sort order': enumToString(newSortOrder),
        },
      );
}

String enumToString(FriendsSortOrder order) {
  return order.toString().split('.').last;
}

extension PingQRFriendingPageAnalytics on Analytics {
  void logProfileShare() => logEvent('share profile link');

  void logMemoriesShareStatus() => logEvent('tap memories share a status');

  void logScannerOpened() => logEvent('scan code');

  void logCodeScanned() => logEvent('scanned code');
}

extension PingFrienshipSettings on Analytics {
  void logGetNearbyToggle(bool value) => logEvent(
        'toggle receives nearby notifications',
        eventProperties: {'new value': value},
      );
  void logSendNearbyToggle(bool value) => logEvent(
        'toggle sends nearby notifications',
        eventProperties: {'new value': value},
      );
  void logGetPingToggle(bool value) => logEvent(
        'toggle receives ping notifications',
        eventProperties: {'new value': value},
      );

  void logGetDTHToggle(bool value) => logEvent(
        'toggle receives dth notifications',
        eventProperties: {'new value': value},
      );

  void logSendDTHToggle(bool value) => logEvent(
        'toggle sends dth notifications',
        eventProperties: {'new value': value},
      );
}

extension PingProfileAnalytics on Analytics {
  void logProfilePictureBannerView() => logEvent('view profile picture banner');

  void logProfilePictureBannerClick() =>
      logEvent('click profile picture banner');
}

extension DTHShareAnalytics on Analytics {
  void logDTHShare(ShareDestination shareDestination) => logEvent(
        'share dth',
        eventProperties: {
          'share destination': shareDestination.name,
        },
      );

  void logSuccessfulDTHShare(ShareDestination shareDestination) => logEvent(
        'dth shared',
        eventProperties: {
          'share destination': shareDestination.name,
        },
      );
}

extension PermissionAnalytics on Analytics {
  static const String locationFirst = 'location first';
  static const String locationAlways = 'location always';
  static const String motion = 'motion';

  static const String permissionAccepted = 'allow';
  static const String permissionDenied = 'deny';

  // location while-in-use permission view logs
  void logLocationFirstFakePromptView() =>
      logPermissionView(permission: locationFirst, isSystemPrompt: false);

  void logLocationFirstSystemPromptView() =>
      logPermissionView(permission: locationFirst, isSystemPrompt: true);

  // location always permission view logs
  void logLocationAlwaysFakePromptView() =>
      logPermissionView(permission: locationAlways, isSystemPrompt: false);

  void logLocationAlwaysSystemPromptView() =>
      logPermissionView(permission: locationAlways, isSystemPrompt: true);

  // motion permission view logs
  void logMotionFakePromptView() =>
      logPermissionView(permission: motion, isSystemPrompt: false);

  void logMotionSystemPromptView() =>
      logPermissionView(permission: motion, isSystemPrompt: true);

  void logPermissionView({
    required String permission,
    required bool isSystemPrompt,
  }) =>
      logEvent(
        'view $permission prompt',
        eventProperties: {
          'prompt type': isSystemPrompt ? 'system' : 'fake',
        },
      );

  // location while-in-use permission answer logs
  void logLocationFirstFakePromptDenied() => logPermissionAnswer(
        permission: locationFirst,
        isSystemPrompt: false,
        answerValue: permissionDenied,
      );

  void logLocationFirstFakePromptAccepted() => logPermissionAnswer(
        permission: locationFirst,
        isSystemPrompt: false,
        answerValue: permissionAccepted,
      );

  void logLocationFirstSystemPromptDenied() => logPermissionAnswer(
        permission: locationFirst,
        isSystemPrompt: true,
        answerValue: permissionDenied,
      );

  void logLocationFirstSystemPromptAccepted() => logPermissionAnswer(
        permission: locationFirst,
        isSystemPrompt: true,
        answerValue: permissionAccepted,
      );

  // location always permission answer logs
  void logLocationAlwaysFakePromptDenied() => logPermissionAnswer(
        permission: locationAlways,
        isSystemPrompt: false,
        answerValue: permissionDenied,
      );

  void logLocationAlwaysFakePromptAccepted() => logPermissionAnswer(
        permission: locationAlways,
        isSystemPrompt: false,
        answerValue: permissionAccepted,
      );

  void logLocationAlwaysSystemPromptDenied() => logPermissionAnswer(
        permission: locationAlways,
        isSystemPrompt: true,
        answerValue: permissionDenied,
      );

  void logLocationAlwaysSystemPromptAccepted() => logPermissionAnswer(
        permission: locationAlways,
        isSystemPrompt: true,
        answerValue: permissionAccepted,
      );

  // motion permission answer logs
  void logMotionFakePromptDenied() => logPermissionAnswer(
        permission: motion,
        isSystemPrompt: false,
        answerValue: permissionDenied,
      );

  void logMotionFakePromptAccepted() => logPermissionAnswer(
        permission: motion,
        isSystemPrompt: false,
        answerValue: permissionAccepted,
      );

  void logMotionSystemPromptDenied() => logPermissionAnswer(
        permission: motion,
        isSystemPrompt: true,
        answerValue: permissionDenied,
      );

  void logMotionSystemPromptAccepted() => logPermissionAnswer(
        permission: motion,
        isSystemPrompt: true,
        answerValue: permissionAccepted,
      );

  void logPermissionAnswer({
    required bool isSystemPrompt,
    required String answerValue,
    required String permission,
  }) =>
      logEvent(
        'answer $permission prompt',
        eventProperties: {
          'prompt type': isSystemPrompt ? 'system' : 'fake',
          'prompt answer': answerValue,
        },
      );
}

extension ScrollAnalytics on Analytics {
  void logPageScroll() => logEvent('scroll page');
}

extension MapEvents on Analytics {
  void logMapCentered() => logEvent('center map');

  void logMapMovement() => logEvent('move map');

  void logMarkerTap(
    MarkerType type, {
    Map<String, dynamic>? properties,
  }) =>
      logEvent(
        'click marker',
        eventProperties: {
          'type': type.name,
          ...?properties,
        },
      );

  void logHangSpotMarkerTap(MapHangSpotDetails spotDetails) => logMarkerTap(
        MarkerType.hangSpot,
        properties: spotDetails.toAnalyticsProperties(),
      );

  void logSchoolMarkerTap() => logMarkerTap(MarkerType.school);

  void logAddFriendMarkerTap() => logMarkerTap(MarkerType.addFriend);
}

extension StatusAnalytics on Analytics {
  void logStatusShare({
    required bool isPrefill,
  }) =>
      logEvent('status shared', eventProperties: {'is prefill': isPrefill});

  void logStatusTapStartTime() => logEvent('tap status start time');

  void logStatusTapEndTime() => logEvent('tap status end time');

  void logStatusCloseTimePicker() => logEvent('close status time picker');

  void logStatusTimeChange(
    String timeType,
    String? startTime,
    String? endTime,
  ) =>
      logEvent(
        'change status $timeType time',
        eventProperties: {
          'startTime': startTime,
          'endTime': endTime,
        },
      );

  void logStatusClearStartTime() => logEvent('clear status start time');
  void logStatusClearEndTime() => logEvent('clear status end time');

  void logStatusTextChange() => logEvent('type status text');
  void logStatusNoChange() => logEvent('share no change status');

  void logShareStatus({
    required String text,
    required bool isRecommendedStatus,
    required bool isOnboardingStatus,
    String? emojiAtFirstPosition,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    logEvent(
      'share status',
      eventProperties: {
        'character count': text.length,
        'emoji': emojiAtFirstPosition,
        // Datetime formatted as 8:34pm as a string
        'startTime': startTime?.localClockTime,
        'endTime': endTime?.localClockTime,
        'inspo': isRecommendedStatus ? text : null,
        'is onboarding': isOnboardingStatus,
      },
    );
  }

  void logStatusIsPublicChange(bool isPublic) => logEvent(
        'status visibility change',
        eventProperties: {
          'isPublic': isPublic,
        },
      );

  void logStatusReactionCreation(String emoji, String component) => logEvent(
        'create status reaction',
        eventProperties: {
          'emoji': emoji,
          'component': component,
        },
      );

  void logStatusReactionDeleted(String component) => logEvent(
        'delete status reaction',
        eventProperties: {
          'component': component,
        },
      );

  void logStatusEmojiPromptTap(EmojiBasedStatus ebs, bool isTextEmpty) =>
      logEvent(
        'emoji prompt tapped',
        eventProperties: {
          'emoji': ebs.emoji,
          'prompt': ebs.prompt,
          'isTextEmpty': isTextEmpty,
        },
      );

  void logQuickStatusShare(String pingEmoji) {
    logEvent(
      'quick emoji ping tapped',
      eventProperties: {
        'emoji': pingEmoji,
      },
    );
  }
}

extension StatusConnectionsAnalytics on Analytics {
  void logMapTapStatusConnections() =>
      logEvent('map tapped on status connections');
}
