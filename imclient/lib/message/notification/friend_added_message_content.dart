import '../../model/message_payload.dart';
import '../message.dart';
import '../message_content.dart';
import 'notification_message_content.dart';


// ignore: non_constant_identifier_names
MessageContent FriendAddedMessageContentCreator() {
  return FriendAddedMessageContent();
}

const friendAddedContentMeta = MessageContentMeta(MESSAGE_FRIEND_ADDED_NOTIFICATION,
    MessageFlag.PERSIST, FriendAddedMessageContentCreator);

class FriendAddedMessageContent extends NotificationMessageContent {

  @override
  void decode(MessagePayload payload) {
    super.decode(payload);
  }

  @override
  MessagePayload encode() {
    MessagePayload payload = super.encode();
    return payload;
  }


  @override
  Future<String> formatNotification(Message message) async {
    return digest(message);
  }

  @override
  Future<String> digest(Message message) async {
    return "你们已经是好友了，可以开始聊天了。";
  }

  @override
  MessageContentMeta get meta => friendAddedContentMeta;

}
