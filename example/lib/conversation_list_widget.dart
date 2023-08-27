import 'dart:async';

import 'package:badges/badges.dart' as badge;
import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:imclient/imclient.dart';
import 'package:imclient/model/channel_info.dart';
import 'package:imclient/model/conversation.dart';
import 'package:imclient/model/conversation_info.dart';
import 'package:imclient/model/group_info.dart';
import 'package:imclient/model/user_info.dart';
import 'package:intl/intl.dart';
import 'package:wfc_example/utilities.dart';

import 'cache.dart';
import 'messages/messages_screen.dart';

// ignore: must_be_immutable
class ConversationListWidget extends StatefulWidget {
  Function(int unreadCount) unreadCountCallback;

  ConversationListWidget(this.unreadCountCallback, {Key? key}) : super(key: key);

  @override
  ConversationListWidgetState createState() => ConversationListWidgetState();
}

class ConversationListWidgetState extends State<ConversationListWidget> {
  List<ConversationInfo> conversationInfos = [];
  late StreamSubscription<ConnectionStatusChangedEvent> _connectionStatusSubscription;
  late StreamSubscription<ReceiveMessagesEvent> _receiveMessageSubscription;
  late StreamSubscription<UserSettingUpdatedEvent> _userSettingUpdatedSubscription;
  late StreamSubscription<RecallMessageEvent> _recallMessageSubscription;
  late StreamSubscription<DeleteMessageEvent> _deleteMessageSubscription;
  late StreamSubscription<ClearConversationUnreadEvent> _clearConveratonUnreadSubscription;
  late StreamSubscription<ClearConversationsUnreadEvent> _clearConveratonsUnreadSubscription;
  final EventBus _eventBus = Imclient.IMEventBus;

  @override
  void initState() {
    super.initState();
    _connectionStatusSubscription = _eventBus.on<ConnectionStatusChangedEvent>().listen((event) {
      if(event.connectionStatus == kConnectionStatusConnected) {
        _loadConversation();
      }
    });

    _receiveMessageSubscription = _eventBus.on<ReceiveMessagesEvent>().listen((event) {
      if(!event.hasMore) {
        _loadConversation();
      }
    });
    _userSettingUpdatedSubscription = _eventBus.on<UserSettingUpdatedEvent>().listen((event) => _loadConversation());
    _recallMessageSubscription = _eventBus.on<RecallMessageEvent>().listen((event) => _loadConversation());
    _deleteMessageSubscription = _eventBus.on<DeleteMessageEvent>().listen((event) => _loadConversation());
    _clearConveratonUnreadSubscription = _eventBus.on<ClearConversationUnreadEvent>().listen((event) => _loadConversation());
    _clearConveratonsUnreadSubscription = _eventBus.on<ClearConversationsUnreadEvent>().listen((event) => _loadConversation());
    _loadConversation();
  }

  void _loadConversation() {
    Imclient.getConversationInfos([ConversationType.Single, ConversationType.Group, ConversationType.Channel], [0]).then((value){
      int unreadCount = 0;
      value.forEach((element) {
        if(!element.isSilent) {
          unreadCount += element.unreadCount.unread;
        }
      });
      widget.unreadCountCallback(unreadCount);
      setState(() {
        conversationInfos = value;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView.builder(
          itemCount: conversationInfos.length,
          itemBuilder: /*1*/ (context, i) {
            ConversationInfo info = conversationInfos[i];
            return _row(info);
          }),),
    );
  }

  Widget _row(ConversationInfo conversationInfo) {
    return ConversationListItem(conversationInfo);
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _receiveMessageSubscription?.cancel();
    _userSettingUpdatedSubscription?.cancel();
    _recallMessageSubscription?.cancel();
    _deleteMessageSubscription?.cancel();
    _clearConveratonUnreadSubscription?.cancel();
    _clearConveratonsUnreadSubscription?.cancel();
    super.dispose();
  }
}

class ConversationListItem extends StatefulWidget {
  final ConversationInfo conversationInfo;

  ConversationListItem(this.conversationInfo) : super(key: ValueKey(conversationInfo));

  @override
  State<StatefulWidget> createState() {
    return ConversationListItemState(conversationInfo);
  }

}

class ConversationListItemState extends State<ConversationListItem> {
  late ConversationInfo conversationInfo;
  UserInfo? userInfo;
  GroupInfo? groupInfo;
  ChannelInfo? channelInfo;

  UserInfo? fromUser;

  String? digest = "";
  bool disposed = false;

  var defaultAvatar = 'assets/images/user_avatar_default.png';

  final EventBus _eventBus = Imclient.IMEventBus;

  ConversationListItemState(this.conversationInfo) {
   if(conversationInfo.conversation.conversationType == ConversationType.Single) {
     userInfo = Cache.getUserInfo(conversationInfo.conversation.target);
     Imclient.getUserInfo(conversationInfo.conversation.target).then((value) {
       if(value != null && value != userInfo && value.userId == conversationInfo.conversation.target) {
         Cache.putUserInfo(value);
         if(!disposed) {
           setState(() {
             userInfo = value;
           });
         }
       }
     });
   } else if(conversationInfo.conversation.conversationType == ConversationType.Group) {
     groupInfo = Cache.getGroupInfo(conversationInfo.conversation.target);
     Imclient.getGroupInfo(conversationInfo.conversation.target).then((value) {
       if(value != null && value != groupInfo && value.target == conversationInfo.conversation.target) {
         Cache.putGroupInfo(value);
         if(!disposed) {
           setState(() {
             groupInfo = value;
           });
         }
       }
     });
   } else if(conversationInfo.conversation.conversationType == ConversationType.Channel) {
     Imclient.getChannelInfo(conversationInfo.conversation.target).then((value) {
       channelInfo = Cache.getChannelInfo(conversationInfo.conversation.target);
       if(value != null && value != channelInfo && value.channelId == conversationInfo.conversation.target) {
         Cache.putChannelInfo(value);
         if(!disposed) {
           setState(() {
             channelInfo = channelInfo;
           });
         }
       }
     });
   }

   if(conversationInfo.lastMessage != null && conversationInfo.lastMessage!.content != null) {
     digest = Cache.getConversationDigest(conversationInfo.conversation);
     conversationInfo.lastMessage!.content.digest(conversationInfo.lastMessage!).then((value) {
       if(digest != value) {
         Cache.putConversationDigest(conversationInfo.conversation, value);
         if(!disposed) {
           setState(() {
             digest = value;
           });
         }
       }
     });
   }
  }

  @override
  Widget build(BuildContext context) {
    String? portrait;
    String? localPortrait;
    String? convTitle;
    if(conversationInfo.conversation.conversationType == ConversationType.Single) {
      if(userInfo != null && userInfo!.portrait != null && userInfo!.portrait!.isNotEmpty) {
        portrait = userInfo!.portrait!;
        convTitle = userInfo!.displayName!;
      } else {
        convTitle = '私聊';
      }
      localPortrait = 'assets/images/user_avatar_default.png';
    } else if(conversationInfo.conversation.conversationType == ConversationType.Group) {
      if(groupInfo != null) {
        if(groupInfo!.portrait != null && groupInfo!.portrait!.isNotEmpty) {
          portrait = groupInfo!.portrait!;
        }
        if(groupInfo!.name != null && groupInfo!.name!.isNotEmpty) {
          convTitle = groupInfo!.name!;
        }
      } else {
        convTitle = '群聊';
      }
      localPortrait = 'assets/images/group_avatar_default.png';
    } else if(conversationInfo.conversation.conversationType == ConversationType.Channel) {
      if(channelInfo != null && channelInfo!.portrait != null && channelInfo!.portrait!.isNotEmpty) {
        portrait = channelInfo!.portrait!;
        convTitle = channelInfo!.name!;
      } else {
        convTitle = '频道';
      }
      localPortrait = 'assets/images/channel_avatar_default.png';
    }



    return new GestureDetector(
      child: new Container(
        color: conversationInfo.isTop > 0 ? CupertinoColors.secondarySystemBackground :  CupertinoColors.systemBackground,
        child: new Column(
          children: <Widget>[
            new Container(
              height: 64.0,
              margin: new EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
              child: new Row(
                children: <Widget>[
                  badge.Badge(
                    showBadge: conversationInfo.unreadCount.unread > 0,
                    badgeContent: Text(conversationInfo.isSilent ? '' : '${conversationInfo.unreadCount.unread}'),
                    child: portrait == null ? new Image.asset(localPortrait!, width: 44.0, height: 44.0) : Image.network(portrait, width: 44.0, height: 44.0),
                  ),
                  new Expanded(
                      child: new Container(
                          height: 48.0,
                          alignment: Alignment.centerLeft,
                          margin: new EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Text(
                                '$convTitle',
                                style: TextStyle(fontSize: 15.0),
                              ),
                              new Container(
                                height: 2,
                              ),
                              new Text(
                                '$digest',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    color: const Color(0xffaaaaaa)),
                                maxLines: 1,
                                softWrap: true,
                              ),
                            ],
                          ))),
                  new Column(children: [
                    new Padding(
                      padding: new EdgeInsets.fromLTRB(0.0, 15.0, 15.0, 0.0),
                      child: new Text(
                        '${Utilities.formatTime(conversationInfo.timestamp)}',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: const Color(0xffaaaaaa),
                        ),
                      ),
                    ),
                    new Padding(
                      padding: new EdgeInsets.fromLTRB(0.0, 5.0, 15.0, 0.0),
                      child: conversationInfo.isSilent ? new Image.asset('assets/images/conversation_mute.png', width: 10, height: 10,) : null,
                    ),
                  ],),
                ],
              ),
            ),
            new Container(
              margin: new EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
              height: 0.5,
              color: const Color(0xffebebeb),
            ),
          ],
        ),
      ),
     onTap: (){
       _toChatPage(conversationInfo.conversation);
     },
    );
  }

  ///
  /// 跳转聊天界面
  ///
  ///
  _toChatPage(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MessagesScreen(conversation)),
    );
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
