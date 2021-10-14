import 'package:get/get.dart';
import 'package:practice_rtc/pages/FirstPage.dart';
import 'package:practice_rtc/pages/SocketIOPage/SocketIOPage.dart';
import 'package:practice_rtc/routes/PagesBind.dart';
part 'app_routes.dart';

class AppPages {
  static const initPage = AppRoutes.FirstPage;
  static final routes = [
    GetPage(
      name: AppRoutes.SocketIOPage,
      page: () => SocketIOPage(),
      binding: PagesBind(),
    ),
    GetPage(
      name: AppRoutes.FirstPage,
      page: () => FirstPage(),
      binding: PagesBind(),
      children: [
        GetPage(
          name: AppRoutes.SocketIOPage,
          page: () => SocketIOPage(),
          binding: PagesBind(),
        )
      ],
    ),
  ];
}
