import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:pure_live/common/core/interface/live_danmaku.dart';
import 'package:pure_live/common/index.dart';

import 'widgets/video_player/video_controller.dart';

class LivePlayController extends GetxController {
  LivePlayController(this.room);

  final LiveRoom room;
  late final Site site = Sites.of(room.platform);
  late final LiveDanmaku liveDanmaku = site.liveSite.getDanmaku();

  final settings = Get.find<SettingsService>();

  final messages = <LiveMessage>[].obs;

  // 控制唯一子组件
  VideoController? controller;
  final playerKey = GlobalKey();
  final danmakuViewKey = GlobalKey();

  final success = false.obs;
  Map<String, Map<String, String>> liveStream = {};
  String selectedResolution = '';
  String selectedStreamUrl = '';

  @override
  void onInit() {
    super.onInit();
    liveDanmaku.onMessage = (msg) {
      messages.add(msg);
    };
    site.liveSite.getLiveStream(room).then((value) {
      liveStream = value;
      setPreferResolution();

      // add delay to avoid hero animation lag
      int delay = (Platform.isWindows || Platform.isLinux) ? 500 : 0;
      Timer(Duration(milliseconds: delay), () {
        controller = VideoController(
          playerKey: playerKey,
          room: room,
          datasourceType: 'network',
          datasource: selectedStreamUrl,
          allowBackgroundPlay: settings.enableBackgroundPlay.value,
          allowScreenKeepOn: settings.enableScreenKeepOn.value,
          fullScreenByDefault: settings.enableFullScreenDefault.value,
          autoPlay: true,
        );
        success.value = true;
      });
    });
  }

  void setResolution(String name, String url) {
    selectedResolution = name;
    selectedStreamUrl = url;
    controller?.setDataSource(selectedStreamUrl);
    update();
  }

  void setPreferResolution() {
    if (liveStream.isEmpty || liveStream.values.first.isEmpty) return;

    for (var key in liveStream.keys) {
      if (settings.preferResolution.contains(key)) {
        selectedResolution = key;
        selectedStreamUrl = liveStream[key]!.values.first;
        return;
      }
    }
    // 原画选择缺陷
    if (settings.preferResolution.value == '原画') {
      for (var key in liveStream.keys) {
        if (key.contains('原画')) {
          selectedResolution = key;
          selectedStreamUrl = liveStream[key]!.values.first;
          return;
        }
      }
    }
    // 蓝光8M/4M选择缺陷
    if (settings.preferResolution.contains('蓝光')) {
      for (var key in liveStream.keys) {
        if (key.contains('蓝光')) {
          selectedResolution = key;
          selectedStreamUrl = liveStream[key]!.values.first;
          return;
        }
      }
    }
    // 偏好选择失败，选择最低清晰度
    selectedResolution = liveStream.keys.last;
    selectedStreamUrl = liveStream.values.last.values.first;
  }
}
