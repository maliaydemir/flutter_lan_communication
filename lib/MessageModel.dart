class MessageModel {
  late String data;
  late String sender;
  MessageType type = MessageType.text;

  MessageModel(
      {required this.data, required this.sender, this.type = MessageType.text});

  MessageModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    sender = json['sender'];
    type = MessageTypeParse(json['type']);
  }

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json['data'] = data;
    json['sender'] = sender;
    json['type'] = type.index;
    return json;
  }
  MessageType MessageTypeParse(int index) {
    switch (index) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }
}

enum MessageType { text, audio }

