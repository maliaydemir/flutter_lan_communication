import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lan_communication/MessageModel.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class HomeScreen extends StatefulWidget {
  String name;

  HomeScreen({Key? key, required this.name}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late InternetAddress DESTINATION_ADDRESS;
  late InternetAddress SELF_IP_ADDRESS;

  late RawDatagramSocket udpSocket;
  late HttpServer httpServer;

  int PORT = 8889;
  List<MessageModel> receivedDatas = [];

  var textC = TextEditingController();

  final record = Record();
  final player = AudioPlayer();

  MessageModel? lastAudioModel;

  var isRecording = false;

  var scrollC=ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: const Text('LAN Messaging'),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded)),
      ),
      bottomSheet: SafeArea(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                  onLongPress: () {
                    startRecording();
                  },
                  onLongPressEnd: (_) async {
                    if (await record.isRecording()) {
                      var dataStr = await stopRecording();
                      if (dataStr != null) {
                        sendData(dataStr, type: MessageType.audio);
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRecording ? Colors.green : null,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.mic),
                    ),
                  )),
            ),
            Expanded(
                child: TextFormField(
              onFieldSubmitted: (val) {
                sendData(textC.text);
                textC.clear();
              },
              decoration: InputDecoration(
                hintText: 'Type here..',
                suffixIcon: IconButton(
                    onPressed: () {
                      sendData(textC.text);
                      textC.clear();
                    },
                    icon: const Icon(Icons.send)),
              ),
              controller: textC,
            )),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          controller: scrollC,
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: receivedDatas.length,
          itemBuilder: (context, i) {
            var data = receivedDatas[i];
            return ListTile(
              title: data.type == MessageType.text
                  ? Text(data.data)
                  : const Text('AUDIO'),
              leading: data.type == MessageType.audio
                  ?const Icon(Icons.play_arrow_rounded)
                  : null,
              onTap:  data.type == MessageType.audio?() async {
                await player.stop();
                await player.setAudioSource(AudioSource.uri(
                    Uri.dataFromBytes(base64Decode(data.data))));
                await player.load();
                player.play();
              }:null,
              subtitle: Text(data.sender),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    strtUdp().then((value) {
      startHttp();
    });
    Permission.storage.request();
    super.initState();
  }

  @override
  void dispose() {
    udpSocket.close();
    httpServer.close();
    super.dispose();
  }

  Future<void> strtUdp() async {
    var linkList = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: true);
    if (linkList.isEmpty) return;
    SELF_IP_ADDRESS = linkList.first.addresses.first;
    DESTINATION_ADDRESS = linkList.first.addresses.first;
    DESTINATION_ADDRESS = GenerateDestAddress(DESTINATION_ADDRESS);
    // DESTINATION_ADDRESS =
    //     InternetAddress('192.168.1.255', type: InternetAddressType.IPv4);

    udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
    udpSocket.broadcastEnabled = true;
    udpSocket.listen((e) async {
      Datagram? dg = udpSocket.receive();
      if (dg != null) {
        var str = utf8.decode(dg.data);
        if (!str.startsWith('{')) {
          print(str);
          var res = await get(Uri.parse(str));
          if (res.statusCode == 200) {
            var model = MessageModel.fromJson(jsonDecode(res.body));
            setState(() {
              receivedDatas.add(model);
            });
          }
        } else {
          var model = MessageModel.fromJson(jsonDecode(utf8.decode(dg.data)));
          setState(() {
            receivedDatas.add(model);
          });
        }
        scrollC.jumpTo(scrollC.position.maxScrollExtent+90);
      }
    });
  }

  Future<void> startHttp() async {
    httpServer = await HttpServer.bind(SELF_IP_ADDRESS, 8080);
    // print("Server running on IP : " +
    //     httpServer.address.toString() +
    //     " On Port : " +
    //     httpServer.port.toString());
    await for (var request in httpServer) {
      if (lastAudioModel == null) {
        request.response
          ..statusCode = 204
          ..close();
      } else {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType("text", "plain", charset: "utf-8")
          ..write(jsonEncode(lastAudioModel))
          ..close();
      }
    }
  }

  sendData(String data, {MessageType type = MessageType.text}) {
    try {
      var model = MessageModel(data: data, sender: widget.name, type: type);
      if (model.type == MessageType.text) {
        List<int> bytes = utf8.encode(jsonEncode(model));
        udpSocket.send(bytes, DESTINATION_ADDRESS, PORT);
      } else {
        // post(Uri.parse('http://127.0.0.1:8080'),headers: {'data':jsonEncode(model)});
        lastAudioModel = model;
        var bytes = utf8.encode('http://${SELF_IP_ADDRESS.address}:8080');
        udpSocket.send(bytes, DESTINATION_ADDRESS, PORT);
        // post(Uri.parse('http://${DESTINATION_ADDRESS.address}:8080'),
        //     headers: {'data': jsonEncode(model)});
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> startRecording() async {
    setState(() {
      isRecording = true;
    });
    Directory tempDir = await getApplicationDocumentsDirectory();
    String tempPath = tempDir.path;
    if (await record.hasPermission()) {
      await record.start(
        path: tempPath + '/tmpAudio.m4a',
      );
    }
  }

  Future<String?> stopRecording() async {
    var path = await record.stop();
    Directory tempDir = await getApplicationDocumentsDirectory();
    String tempPath = tempDir.path;
    setState(() {
      isRecording = false;
    });
    if (path != null) {
      var file = File.fromUri(Uri.parse(path));
      var data = await file.readAsBytes();

      return base64.encode(data);
    }
    return null;
  }

  InternetAddress GenerateDestAddress(InternetAddress destination_address) {
    var strArr = destination_address.address.split('.');
    var str = '${strArr[0]}.${strArr[1]}.${strArr[2]}.255';
    return InternetAddress(str, type: destination_address.type);
  }
}
