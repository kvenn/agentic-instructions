import '../../../../graphql/fragments.graphql.dart';

abstract class NavigationService {
  void goToOnboarding();
  void goToEventsList();
  void pushToEventDetail(String eventId);
  void goToEventDetail(String eventId);
  void pushToCreateEvent();
  void goToEditEvent(Fragment$Event event);
  void goToProfile();
  void goBack();
}
