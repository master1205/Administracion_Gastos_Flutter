import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum EnNotificationPermision { granted, denied, permanentlyDenied, none }

class PermissionHandler extends ChangeNotifier {
  EnNotificationPermision notificationPermision =
      EnNotificationPermision.denied;

  Future<EnNotificationPermision> getNotificationPermission() async {
    var state = await Permission.notification.status;
    return converStatus(state);
  }

  Future checkPermission() async {
    notificationPermision = await getNotificationPermission();
    notifyListeners();
  }

  EnNotificationPermision converStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return EnNotificationPermision.granted;
      case PermissionStatus.denied:
        return EnNotificationPermision.denied;
      case PermissionStatus.permanentlyDenied:
        return EnNotificationPermision.permanentlyDenied;
      default:
        return EnNotificationPermision.none;
    }
  }
}
