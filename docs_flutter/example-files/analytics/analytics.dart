// ignore_for_file: number_of_parameters, cyclomatic_complexity
import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/identify.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../flavors_util.dart';
import '../logging/crash_reporting.dart';
import '../logging/logger.dart';
import '../schema/generated/fragments.graphql.dart';
import '../service_locator.dart';
import '../shared/model_extensions/user_extensions.dart';
import '../shared/server.dart';
import 'analytics_pages.dart';

/// The keys for user properties
class _UserPropertyKeys {
  static const id = 'id';
  static const packCount = 'pack count';
  static const isPushEnabled = 'is push enabled';
  static const isContactsEnabled = 'is contacts enabled';
  static const birthday = 'birthday';
  static const age = 'age';
  static const friendCount = 'friend count';
  static const firstName = 'first name';
  static const lastName = 'last name';
  static const isAmbassador = 'is ambassador';
  static const isStaff = 'is staff';
  static const inviteCode = 'invite code';
  static const inviterCode = 'inviter code';

  static const appName = 'app';
  static const isForegrounded = 'is foregrounded';

  // Ping
  static const currentLevel = 'current level';
  static const hungFriends = 'hung friends';
  static const contactsPermission = 'contacts permission';
  static const locationPermission = 'location permission';
  static const isHanging = 'is hanging';
  static const hasProfilePic = 'has profile pic';
  static const hangCount = 'hang count';
  static const currentStreak = 'current status streak';
  static const postsThisWeek = 'status posts this week';
  static const schoolEmailDomain = 'school email domain';

  // UTM
  static const utmSource = 'utm_source';
  static const utmMedium = 'utm_medium';
  static const utmCampaign = 'utm_campaign';
  static const utmContent = 'utm_content';
}

/// The keys that are shared between other events
class _Keys {
  static const page = 'page';
}

// final analytics = Analytics();

abstract class AnalyticsEngine {
  String getLogName();

  Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  });

  void incrementProperty(String propertyName);

  void identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? app,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  });
}

class Analytics {
  final _log = AppLogger.withName('analytics');

  final List<AnalyticsEngine> _engines = [];

  /// Updated via [logPageView]. Used for logging screenshots / sending the
  /// page name along with other events. It will always be the last [logPageView]
  /// event that occurred.
  String currentPageName = 'n/a';
  Map<String, dynamic>? currentPageData;

  Analytics() {
    addEngine(_SentryEngine());
    addEngine(_DatadogEngine());
  }

  AnalyticsEngine addEngine(AnalyticsEngine engine) {
    _engines.add(engine);
    return engine;
  }

  /// Log an event to all available engines (consumers).
  ///
  /// If [eventProperties] don't contain [_Keys.page] already, set it to the
  /// default stateful one of [analytics.currentPageName].
  void logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  }) {
    try {
      if (!(eventProperties?.containsKey(_Keys.page) ?? false)) {
        eventProperties ??= {};
        eventProperties[_Keys.page] = currentPageName;
      }

      final String debugMessage =
          'Event Name: $eventType, Event Props: $eventProperties';
      _log.debug(debugMessage);

      for (final AnalyticsEngine engine in _engines) {
        engine.logEvent(eventType, eventProperties: eventProperties);
      }
    } catch (exception) {
      _log.error('Analytics exception occurred: $exception');
    }
  }

  /// Log event and store off the pageName and page event properties
  /// as a side effect.
  void logPageView(
    AnalyticsPage page, {
    Map<String, dynamic>? eventProperties,
  }) {
    // These break the home page for some reason, still log the page view, just
    // don't set them as the "current page"
    // TODO: find a better way
    final List<AnalyticsPage> pagesToIgnore = [
      AnalyticsPage.locationVisibilitySheet,
      AnalyticsPage.locationVisibilityExplainer,
      AnalyticsPage.statusStreakExplainer,
      AnalyticsPage.stealthModeSheet,
    ];
    final String pageName = page.toShortString();
    if (!pagesToIgnore.contains(page)) {
      currentPageName = pageName;
      currentPageData = eventProperties;
    }
    logEvent('$pageName page view', eventProperties: eventProperties);
  }

  void trackRouteView(String pageName) {
    return logEvent('route view', eventProperties: {'route': pageName});
  }

  void incrementInvitesSentUserProperty() {
    _incrementProperty('invites sent count');
  }

  void incrementSharesClickedUserProperty() {
    _incrementProperty('share click count');
  }

  void incrementSkipsUserProperty() {
    _incrementProperty('skip count');
  }

  _incrementProperty(String propertyName) {
    for (final AnalyticsEngine engine in _engines) {
      engine.incrementProperty(propertyName);
    }
  }

  void identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    String? app,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  }) {
    for (final AnalyticsEngine engine in _engines) {
      engine.identifyUserProperty(
        userId: userId,
        packCount: packCount,
        isPushEnabled: isPushEnabled,
        isContactsEnabled: isContactsEnabled,
        contactsPermission: contactsPermission,
        birthday: birthday,
        friendCount: friendCount,
        firstName: firstName,
        lastName: lastName,
        isAmbassador: isAmbassador,
        isStaff: isStaff,
        inviteCode: inviteCode,
        inviterCode: inviterCode,
        currentLevel: currentLevel,
        hungFriends: hungFriends,
        locationPermission: locationPermission,
        hasNotificationPermission: hasNotificationPermission,
        isHanging: isHanging,
        isForegrounded: isForegrounded,
        app: app,
        utmSource: utmSource,
        utmMedium: utmMedium,
        utmCampaign: utmCampaign,
        utmContent: utmContent,
        hasProfilePic: hasProfilePic,
        hangCount: hangCount,
        currentStreak: currentStreak,
        postsThisWeek: postsThisWeek,
        schoolEmailDomain: schoolEmailDomain,
        featureFlags: featureFlags,
      );
    }
  }

  void identifyUser(Fragment$CurrentUser user) {
    _log.debug('User Identified: ${user.id}');

    identifyUserProperty(
      userId: user.id,
      app: AppFlavor.assets.appHeader,
      birthday: user.birthday,
      isAmbassador: user.isAmbassador,
      isStaff: user.isStaff,
      hasProfilePic: user.hasNonDefaultProfilePicture,
      featureFlags: user.featureFlags,
    );
  }
}

class AmplitudeEngine implements AnalyticsEngine {
  final Amplitude _amplitude = Amplitude.getInstance(instanceName: 'rlly');
  // ignore: avoid_late_keyword
  late final Future<void> _amplitudeInitializer;

  AmplitudeEngine(String key) {
    _amplitudeInitializer =
        key.isNotEmpty ? _amplitude.init(key) : Future.value();
  }

  @override
  String getLogName() {
    return 'Amplitude';
  }

  @override
  Future<void> identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? app,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  }) async {
    await _amplitudeInitializer;
    if (userId != null) {
      _amplitude.setUserId(userId);
    }

    final userProps = Identify();
    if (packCount != null) {
      userProps.set(_UserPropertyKeys.packCount, packCount);
    }
    if (friendCount != null) {
      userProps.set(_UserPropertyKeys.friendCount, friendCount);
    }
    if (isPushEnabled != null) {
      userProps.set(_UserPropertyKeys.isPushEnabled, isPushEnabled);
    }
    if (isContactsEnabled != null) {
      userProps.set(_UserPropertyKeys.isContactsEnabled, isContactsEnabled);
    }
    if (contactsPermission != null) {
      userProps.set(_UserPropertyKeys.contactsPermission, contactsPermission);
    }
    if (birthday != null) {
      final prettyBirthday = DateFormat('yyyy-MM-dd').format(birthday);
      userProps.set(_UserPropertyKeys.birthday, prettyBirthday);

      final age = (DateTime.now().difference(birthday).inDays / 365).floor();
      userProps.set(_UserPropertyKeys.age, age);
    }
    if (firstName != null) {
      userProps.set(_UserPropertyKeys.firstName, firstName);
    }
    if (lastName != null) {
      userProps.set(_UserPropertyKeys.lastName, lastName);
    }
    if (isAmbassador != null) {
      userProps.set(_UserPropertyKeys.isAmbassador, isAmbassador);
    }
    if (isStaff != null) {
      userProps.set(_UserPropertyKeys.isStaff, isStaff);
    }
    if (inviteCode != null) {
      userProps.set(_UserPropertyKeys.inviteCode, inviteCode);
    }
    if (inviterCode != null) {
      userProps.set(_UserPropertyKeys.inviterCode, inviterCode);
    }
    if (currentLevel != null) {
      userProps.set(_UserPropertyKeys.currentLevel, currentLevel);
    }
    if (hungFriends != null) {
      userProps.set(_UserPropertyKeys.hungFriends, hungFriends);
    }
    if (locationPermission != null) {
      userProps.set(_UserPropertyKeys.locationPermission, locationPermission);
    }
    if (isHanging != null) {
      userProps.set(_UserPropertyKeys.isHanging, isHanging);
    }
    if (isForegrounded != null) {
      userProps.set(_UserPropertyKeys.isForegrounded, isForegrounded);
    }
    if (app != null) {
      userProps.set(_UserPropertyKeys.appName, app);
    }
    if (utmSource != null) {
      userProps.set(_UserPropertyKeys.utmSource, utmSource);
    }
    if (utmMedium != null) {
      userProps.set(_UserPropertyKeys.utmMedium, utmMedium);
    }
    if (utmCampaign != null) {
      userProps.set(_UserPropertyKeys.utmCampaign, utmCampaign);
    }
    if (utmContent != null) {
      userProps.set(_UserPropertyKeys.utmContent, utmContent);
    }
    if (hasProfilePic != null) {
      userProps.set(_UserPropertyKeys.hasProfilePic, hasProfilePic);
    }
    if (hangCount != null) {
      userProps.set(_UserPropertyKeys.hangCount, hangCount);
    }
    if (currentStreak != null) {
      userProps.set(_UserPropertyKeys.currentStreak, currentStreak);
    }
    if (postsThisWeek != null) {
      userProps.set(_UserPropertyKeys.postsThisWeek, postsThisWeek);
    }
    if (schoolEmailDomain != null) {
      userProps.set(_UserPropertyKeys.schoolEmailDomain, schoolEmailDomain);
    }
    if (featureFlags != null) {
      try {
        featureFlags.toJson().forEach((key, value) {
          if (key == '__typename') return;
          userProps.set('flag_$key', value);
        });
      } catch (e) {
        // no-op
      }
    }

    final isDevBuild = !Server.isProd || !BuildFlavor.isProd;
    userProps.set('is dev build', isDevBuild);

    _amplitude.identify(userProps);
  }

  @override
  Future<void> incrementProperty(String propertyName) async {
    await _amplitudeInitializer;
    final userProps = Identify();
    userProps.add(propertyName, 1);
    _amplitude.identify(userProps);
  }

  @override
  Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  }) async {
    await _amplitudeInitializer;
    _amplitude.logEvent(eventType, eventProperties: eventProperties);
  }
}

class FirebaseEngine implements AnalyticsEngine {
  final FirebaseAnalytics _firebase;

  @override
  String getLogName() {
    return 'Firebase';
  }

  FirebaseEngine(this._firebase);

  @override
  Future<void> identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? app,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  }) async {
    if (userId != null) {
      _firebase.setUserId(id: userId);
    }

    if (packCount != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.packCount,
        value: packCount.toString(),
      );
    }
    if (isPushEnabled != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isPushEnabled,
        value: isPushEnabled.toString(),
      );
    }
    if (isContactsEnabled != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isContactsEnabled,
        value: isContactsEnabled.toString(),
      );
    }
    if (contactsPermission != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.contactsPermission,
        value: contactsPermission,
      );
    }
    if (birthday != null) {
      final prettyBirthday = DateFormat('yyyy-MM-dd').format(birthday);
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.birthday,
        value: prettyBirthday,
      );

      final age = (DateTime.now().difference(birthday).inDays / 365).floor();
      _setFirebaseUserProperty(name: _UserPropertyKeys.age, value: age);
    }
    if (friendCount != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.friendCount,
        value: friendCount.toString(),
      );
    }
    if (isAmbassador != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isAmbassador,
        value: isAmbassador.toString(),
      );
    }
    if (isStaff != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isStaff,
        value: isStaff.toString(),
      );
    }
    if (inviteCode != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.inviteCode,
        value: inviteCode,
      );
    }
    if (inviterCode != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.inviterCode,
        value: inviterCode,
      );
    }
    if (hungFriends != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.hungFriends,
        value: hungFriends.toString(),
      );
    }
    if (currentLevel != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.currentLevel,
        value: currentLevel.toString(),
      );
    }
    if (isHanging != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isHanging,
        value: isHanging.toString(),
      );
    }
    if (isForegrounded != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.isForegrounded,
        value: isForegrounded.toString(),
      );
    }
    if (app != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.appName,
        value: app,
      );
    }
    if (locationPermission != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.locationPermission,
        value: locationPermission,
      );
    }
    if (utmSource != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.utmSource,
        value: utmSource,
      );
    }
    if (utmMedium != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.utmMedium,
        value: utmMedium,
      );
    }
    if (utmCampaign != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.utmCampaign,
        value: utmCampaign,
      );
    }
    if (utmContent != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.utmContent,
        value: utmContent,
      );
    }
    if (hasProfilePic != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.hasProfilePic,
        value: hasProfilePic,
      );
    }
    if (hangCount != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.hangCount,
        value: hangCount,
      );
    }
    if (currentStreak != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.currentStreak,
        value: currentStreak,
      );
    }
    if (postsThisWeek != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.postsThisWeek,
        value: postsThisWeek,
      );
    }
    if (schoolEmailDomain != null) {
      _setFirebaseUserProperty(
        name: _UserPropertyKeys.schoolEmailDomain,
        value: schoolEmailDomain,
      );
    }
  }

  @override
  void incrementProperty(String propertyName) {}

  @override
  Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  }) async {
    _firebase.logEvent(
      name: eventType.cleanText(),
      parameters: eventProperties.cleanText(),
    );
  }

  ///Note: Make sure [value] has an acceptable `toString()` method
  _setFirebaseUserProperty({required String name, required Object value}) {
    _firebase.setUserProperty(
      name: name.cleanText(),
      value: value.toString(),
    );
  }
}

extension AnalyticsStringUtils on String {
  String cleanText() {
    return replaceAll(' ', '_').replaceAll(RegExp('[^a-zA-Z0-9_]'), '');
  }
}

extension AnalyticsMapUtils on Map<String, dynamic>? {
  /// Convert keys to be underscored and values to be strings
  Map<String, String>? cleanText() {
    final Map<String, String> acc = {};
    this?.forEach((k, v) => acc[k.cleanText()] = v.toString());
    return acc;
  }
}

extension UtmUtils on String {
  /// Returns a map of UTM parameters.
  /// If none provided, the map will be empty
  static Map<String, String>? _toUtmMap({
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
  }) {
    final Map<String, String> utmMap = {};
    if (utmSource != null) {
      utmMap[_UserPropertyKeys.utmSource] = utmSource;
    }
    if (utmMedium != null) {
      utmMap[_UserPropertyKeys.utmMedium] = utmMedium;
    }
    if (utmCampaign != null) {
      utmMap[_UserPropertyKeys.utmCampaign] = utmCampaign;
    }
    if (utmContent != null) {
      utmMap[_UserPropertyKeys.utmContent] = utmContent;
    }
    return utmMap;
  }

  /// Returns UTM params as a [String] or empty string if none provided.
  /// Default the source to rlly
  /// Example: utm_source=rlly&utm_medium=cpc&utm_campaign=brand
  String appendUtmQueryString({
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
  }) {
    final Map<String, String>? utmMap = _toUtmMap(
      utmSource: utmSource ?? AppFlavor.assets.name,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
      utmContent: utmContent,
    );

    if (utmMap?.isEmpty ?? false) {
      return this;
    }

    String baseUrl = this;
    // Remove trailing slash (if there is one)
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return '$baseUrl?${Uri(queryParameters: utmMap).query}';
  }
}

class _SentryEngine implements AnalyticsEngine {
  @override
  String getLogName() {
    return 'Sentry';
  }

  @override
  void identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? app,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  }) {
    // Sentry overwrites the values each time, so we can't use it like we
    // do the other platforms. It's either all or nothing.
    // At minimum, ensure the id is always there.
    if (userId == null || app == null) return;

    Sentry.configureScope(
      (scope) => scope.setUser(
        SentryUser(
          id: userId,
          data: {
            _UserPropertyKeys.appName: app,
            _UserPropertyKeys.packCount: packCount,
            _UserPropertyKeys.isPushEnabled: isPushEnabled,
            _UserPropertyKeys.isContactsEnabled: isContactsEnabled,
            _UserPropertyKeys.friendCount: friendCount,
            _UserPropertyKeys.isAmbassador: isAmbassador,
            _UserPropertyKeys.isStaff: isStaff,
            _UserPropertyKeys.currentLevel: currentLevel,
            _UserPropertyKeys.hungFriends: hungFriends,
            _UserPropertyKeys.contactsPermission: contactsPermission,
            _UserPropertyKeys.locationPermission: locationPermission,
            _UserPropertyKeys.isHanging: isHanging,
            _UserPropertyKeys.isForegrounded: isForegrounded,
            _UserPropertyKeys.hasProfilePic: hasProfilePic,
            _UserPropertyKeys.hangCount: hangCount,
            _UserPropertyKeys.schoolEmailDomain: schoolEmailDomain,
          },
        ),
      ),
    );
  }

  @override
  void incrementProperty(String propertyName) {}

  @override
  Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  }) async {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'analytics',
        message: eventType,
        data: eventProperties.cleanText(),
      ),
    );
  }
}

class _DatadogEngine implements AnalyticsEngine {
  @override
  String getLogName() {
    return 'Datadog';
  }

  @override
  void identifyUserProperty({
    String? userId,
    int? packCount,
    bool? isPushEnabled,
    bool? isContactsEnabled,
    DateTime? birthday,
    int? friendCount,
    String? firstName,
    String? lastName,
    bool? isAmbassador,
    bool? isStaff,
    String? inviteCode,
    String? inviterCode,
    int? hungFriends,
    int? currentLevel,
    String? contactsPermission,
    String? locationPermission,
    bool? hasNotificationPermission,
    bool? isHanging,
    bool? isForegrounded,
    bool? hasProfilePic,
    int? hangCount,
    String? app,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    int? currentStreak,
    int? postsThisWeek,
    String? schoolEmailDomain,
    Fragment$FeatureFlags? featureFlags,
  }) {
    // For RUM, which is too expensive
    // DatadogSdk.instance.setUserInfo(id: userId, extraInfo: {
    //   _UserPropertyKeys.appName: app,
    //   _UserPropertyKeys.packCount: packCount,
    //   _UserPropertyKeys.isPushEnabled: isPushEnabled,
    //   _UserPropertyKeys.isContactsEnabled: isContactsEnabled,
    //   _UserPropertyKeys.friendCount: friendCount,
    //   _UserPropertyKeys.isAmbassador: isAmbassador,
    //   _UserPropertyKeys.isStaff: isStaff,
    //   _UserPropertyKeys.hungFriends: hungFriends,
    //   _UserPropertyKeys.currentLevel: currentLevel,
    //   _UserPropertyKeys.locationPermission: locationPermission,
    // });

    // We'll nest a `user` attribute on all DataDog logs (crash/analytics)
    final Map<String, Object> userAttributes = {};
    if (userId != null) {
      userAttributes[_UserPropertyKeys.id] = userId;
    }

    if (packCount != null) {
      userAttributes[_UserPropertyKeys.packCount] = packCount;
    }
    if (isPushEnabled != null) {
      userAttributes[_UserPropertyKeys.isPushEnabled] = isPushEnabled;
    }
    if (isContactsEnabled != null) {
      userAttributes[_UserPropertyKeys.isContactsEnabled] = isContactsEnabled;
    }
    if (contactsPermission != null) {
      userAttributes[_UserPropertyKeys.contactsPermission] = contactsPermission;
    }
    if (birthday != null) {
      final prettyBirthday = DateFormat('yyyy-MM-dd').format(birthday);
      userAttributes[_UserPropertyKeys.birthday] = prettyBirthday;

      final age = (DateTime.now().difference(birthday).inDays / 365).floor();
      userAttributes[_UserPropertyKeys.age] = age;
    }
    if (friendCount != null) {
      userAttributes[_UserPropertyKeys.friendCount] = friendCount;
    }
    if (isAmbassador != null) {
      userAttributes[_UserPropertyKeys.isAmbassador] = isAmbassador;
    }
    if (isStaff != null) {
      userAttributes[_UserPropertyKeys.isStaff] = isStaff;
    }
    if (currentLevel != null) {
      userAttributes[_UserPropertyKeys.currentLevel] = currentLevel;
    }
    if (hungFriends != null) {
      userAttributes[_UserPropertyKeys.hungFriends] = hungFriends;
    }
    if (isHanging != null) {
      userAttributes[_UserPropertyKeys.isHanging] = isHanging;
    }
    if (isForegrounded != null) {
      userAttributes[_UserPropertyKeys.isForegrounded] = isForegrounded;
    }
    if (app != null) {
      userAttributes[_UserPropertyKeys.appName] = app;
    }
    if (locationPermission != null) {
      userAttributes[_UserPropertyKeys.locationPermission] = locationPermission;
    }
    if (utmSource != null) {
      userAttributes[_UserPropertyKeys.utmSource] = utmSource;
    }
    if (utmMedium != null) {
      userAttributes[_UserPropertyKeys.utmMedium] = utmMedium;
    }
    if (utmCampaign != null) {
      userAttributes[_UserPropertyKeys.utmCampaign] = utmCampaign;
    }
    if (utmContent != null) {
      userAttributes[_UserPropertyKeys.utmContent] = utmContent;
    }
    if (hasProfilePic != null) {
      userAttributes[_UserPropertyKeys.hasProfilePic] = hasProfilePic;
    }
    if (hangCount != null) {
      userAttributes[_UserPropertyKeys.hangCount] = hangCount;
    }
    if (schoolEmailDomain != null) {
      userAttributes[_UserPropertyKeys.schoolEmailDomain] = schoolEmailDomain;
    }

    // Sets it on the global log instance so all logs (crash/analytics) will
    // have this user attributes
    CrashReporting.setDataDogUser(userAttributes);
  }

  @override
  void incrementProperty(String propertyName) {}

  @override
  Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? eventProperties,
  }) async {}
}

extension AnalyticsShortcutWidget on Widget {
  Analytics get analytics => sl<Analytics>();
}

extension AnalyticsShortcutState on State {
  Analytics get analytics => sl<Analytics>();
}
