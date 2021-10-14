import 'package:get/get.dart';
import 'package:collection/collection.dart';


class FirstPageController extends GetxController {
  final _dataList = [
    "SocketIOPage",
  ].obs;
  get dataList => this._dataList.toList();

  @override
  void onInit() {

    super.onInit();
  }


}
