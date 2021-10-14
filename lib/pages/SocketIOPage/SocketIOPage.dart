import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'dart:core';
import 'package:practice_rtc/pages/SocketIOPage/SocketIOPageController.dart';

class SocketIOPage extends GetView<SocketIOPageController> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final stateString = controller.isOnConnect ? "已連線" : "未連線";
          return Text('狀態: $stateString');
        }),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_video),
            onPressed: controller.toggleCamera,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: Stack(
              children: [
                Container(
                  width: Get.width,
                  height: Get.height,
                  child: GetBuilder<SocketIOPageController>(
                    id: "remoteRenderer",
                    init: controller,
                    initState: (_) {},
                    builder: (_) {
                      return RTCVideoView(controller.remoteRenderer);
                    },
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: Container(
                    width: Get.width * 0.2,
                    height: Get.height * 0.2,
                    child: Obx(
                      () => Visibility(
                        visible: controller.isCameraEnable,
                        child: GetBuilder<SocketIOPageController>(
                          id: "localRender",
                          init: controller,
                          initState: (_) {},
                          builder: (_) {
                            return RTCVideoView(controller.localRenderer,
                                mirror: true);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          onPressed: () {
            launchCamera();
          },
          tooltip: controller.isCameraEnable ? 'Hangup' : 'Call',
          child:
              Icon(controller.isCameraEnable ? Icons.stop : Icons.play_arrow),
        ),
      ),
    );
  }

  launchCamera() async {
    controller.isCameraEnable = true;
    controller.update(['localRender']);
  }


}
