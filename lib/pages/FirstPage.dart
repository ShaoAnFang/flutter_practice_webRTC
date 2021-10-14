import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:practice_rtc/pages/FirstPageController.dart';

class FirstPage extends GetView<FirstPageController> {
  final controller = Get.put(FirstPageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FirstPage')),
      body: SafeArea(
        child: Container(
          color: Colors.grey[50],
          child: _buildListView(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      itemCount: controller.dataList.length,
      itemBuilder: (BuildContext context, int index) {
        final title = controller.dataList[index];
        return _buildCardCell(title);
      },
    );
  }

  Widget _buildCardCell(String title) {
    return Card(
      elevation: 3.0,
      child: ListTile(
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Get.deleteAll();
          Get.toNamed("/FirstPage/$title");
        },
      ),
    );
  }
}
