import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';

void initFirebasePlatform() {
  // ignore: invalid_use_of_visible_for_testing_member
  Firebase.delegatePackingProperty = FirebaseCoreWeb();
}
