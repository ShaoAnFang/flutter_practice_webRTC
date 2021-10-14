import 'package:get/get.dart';
import 'package:practice_rtc/pages/FirstPageController.dart';
import 'package:practice_rtc/pages/SocketIOPage/SocketIOPageController.dart';

class PagesBind extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirstPageController>(() => FirstPageController());
    Get.lazyPut<SocketIOPageController>(() => SocketIOPageController());
  }
}
