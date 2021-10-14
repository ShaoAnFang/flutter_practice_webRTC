
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:core';
import 'package:flutter_webrtc/src/native/rtc_peerconnection_factory.dart' as PF;

class SocketIOPageController extends GetxController {

  late IO.Socket socket;

  final _isOnConnect = false.obs;
  set isOnConnect(value) => this._isOnConnect.value = value;
  get isOnConnect => this._isOnConnect.value;

  final _room = 'someRoom'.obs;
  set room(value) => this._room.value = value;
  get room => this._room.value;

  late RTCIceCandidate candidate;

  RTCPeerConnection? _peerConnection;

  final _isCameraEnable = false.obs;
  set isCameraEnable(value) {
    this._isCameraEnable.value = value;
    changeLocalStreamTracks();
  }

  get isCameraEnable => this._isCameraEnable.value;

  String _sdp = '';

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;

  @override
  onInit() async {
    initRenderers();
    connectSokcetIO();
    super.onInit();
  }

  @override
  onClose() {
    socket.close();
    hangup();

    stopLoaclStream();
    Get.delete<SocketIOPageController>();
  }

  initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  connectSokcetIO() {
    socket = IO.io('wss://192.168.x.xx:8088', <String, dynamic>{
      'transports': ['websocket'],
      // 'auth': {'token': "Bearer $token"}
    });

    socket.onConnect((_) {
      print('on connect');
      isOnConnect = true;
    });

    socket.on('auth', (status) {
      if (status) {
        print('auth :$status');
        isOnConnect = true;
      }
    });

    socket.on('ready', (msg) async {
      print(msg);
      // 發送 offer
      print('發送 offer ');
      await sendSDP(true);
    });

    socket.on('ice_candidate', (data) async {
      print('收到 ice_candidate');
      candidate = RTCIceCandidate(data["candidate"], "", data["label"]);
      await _peerConnection!.addCandidate(candidate);
    });

    socket.on('offer', (data) async {
      print('收到 offer');
      // print(data);
      final desc = RTCSessionDescription(data['sdp'], data['type']);
      // 設定對方的配置
      // 發送 answer
      await sendSDP(false, desc: desc);
    });

    socket.on('answer', (data) async {
      print('收到 answer');
      final desc = RTCSessionDescription(data['sdp'], data['type']);
      // 設定對方的配置
      await _peerConnection!.setRemoteDescription(desc);
    });

    socket.on('leaved', (_) {
      print('收到 leaved');
      socket.disconnect();
      // closeLocalMedia()
    });

    socket.on('bye', (_) {
      print('收到 bye');
      hangup();
    });

    socket.onDisconnect((data) {
      print('disconnect');
      if (data == 'io server disconnect') {
        print('伺服器中斷連線，請確認Token');
      } else {
        print(data);
      }
    });

    socket.onConnectError((data) {
      print(data);
    });

    socket.emit('join', room);
  }

  sendSDP(bool isOffer, {RTCSessionDescription? desc}) async {
    try {
      if (_peerConnection == null) {
        await initPeerConnection();
      }

      final offerSdpConstraints = <String, dynamic>{
        'mandatory': {
          'OfferToReceiveAudio': true, 
          'OfferToReceiveVideo': true, 
        },
        'optional': [],
      };

      final RTCSessionDescription localSDP;

      if (isOffer) {
        var description =
            await _peerConnection!.createOffer(offerSdpConstraints);
        //設定本地的SDP
        await _peerConnection?.setLocalDescription(description);
        localSDP = await _peerConnection!.createOffer();
      } else {
        // 設定對方的配置
        await _peerConnection!.setRemoteDescription(desc!);
        localSDP = await _peerConnection!.createAnswer();
      }
      // 設定本地SDP
      await _peerConnection?.setLocalDescription(localSDP);

      // 寄出SDP信令
      final e = isOffer ? 'offer' : 'answer';
      // print(_peerConnection?.getLocalDescription);
      final localDescription = await _peerConnection!.getLocalDescription();
      print(localDescription);
      socket.emit(e, [room, localDescription!.toMap()]);
    } catch (err) {
      throw err;
    }
  }

  hangup() {
    if (_peerConnection != null) {
      _peerConnection?.close();
      _peerConnection = null;
    }
  }

  _onSignalingState(RTCSignalingState state) {
    print(state);
  }

  _onIceGatheringState(RTCIceGatheringState state) {
    print(state);
  }

  // 監聽 ICE 連接狀態
  _onIceConnectionState(RTCIceConnectionState state) {
    print('ICE Connection State: $state');
  }

  // 找尋到 ICE 候選位置
  _onIceCandidate(RTCIceCandidate candidate) {
    print('onCandidate: ${candidate.candidate}');
    _peerConnection?.addCandidate(candidate);
    _sdp += '\n';
    _sdp += candidate.candidate ?? '';
    // print(_sdp);
    // 發送 ICE
    socket.emit('ice_candidate', [
      room,
      {
        "label": candidate.sdpMlineIndex,
        "id": candidate.sdpMid,
        "candidate": candidate.toMap(),
      }
    ]);
  }

  _onRenegotiationNeeded() {
    print('RenegotiationNeeded');
  }

 
  _onTrack(RTCTrackEvent event) {
    print('onTrack');
    if (event.track.kind == 'video') {
      remoteRenderer.srcObject = event.streams[0];
    }
  }

  _onAddStream(MediaStream stream) {
    print('New stream: ' + stream.id);
    remoteRenderer.srcObject = stream;
    update(['remoteRenderer']);
  }

  _onRemoveStream(MediaStream stream) {
    remoteRenderer.srcObject = null;
  }

  initPeerConnection() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    final loopbackConstraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    if (_peerConnection != null) return;

    try {
      _peerConnection =
          await createPeerConnection(configuration, loopbackConstraints);
      _peerConnection!.onSignalingState = _onSignalingState;
      _peerConnection!.onIceGatheringState = _onIceGatheringState;
      _peerConnection!.onIceConnectionState = _onIceConnectionState;
      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onRenegotiationNeeded = _onRenegotiationNeeded;

      _peerConnection!.onTrack = _onTrack;
      _peerConnection!.onAddStream = _onAddStream;
      _peerConnection!.onRemoveStream = _onRemoveStream;

      setLocalStream();
    } catch (e) {
      print(e.toString());
    }
  }

  setLocalStream() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '20',
        },
        "facingMode": "user", //加這個預設是前鏡頭
      }
    };

    try {
      var sstream =
          await PF.navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      print(sstream);

      var stream =
          await PF.navigator.mediaDevices.getUserMedia(mediaConstraints);
      localStream = stream;
      localRenderer.srcObject = stream;

      /* 增加本地串流, 預設關閉
         由isCameraEnable 的setter觸發打開
      */
      localStream!
          .getTracks()
          .forEach((track) => _peerConnection!.addTrack(track, localStream!));
      localStream!.getAudioTracks().forEach((item) => item.enabled = false);
      localStream!.getVideoTracks().forEach((item) => item.enabled = false);
    } catch (e) {
      print(e.toString());
    }
  }

  changeLocalStreamTracks() {
    localStream!
        .getAudioTracks()
        .forEach((item) => item.enabled = isCameraEnable);
    localStream!
        .getVideoTracks()
        .forEach((item) => item.enabled = isCameraEnable);
  }

  toggleCamera() async {
    if (localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await Helper.switchCamera(videoTrack);
  }

  stopLoaclStream() async {
    await localStream?.dispose();
    localStream = null;
    localRenderer.srcObject = null;
  }
}
