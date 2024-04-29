enum GroupType { Normal, Free, Restricted, Organization }

class GroupInfo {
  GroupInfo(
      {this.type = GroupType.Restricted,
      this.memberCount = 0,
      this.mute = 0,
      this.joinType = 0,
      this.privateChat = 0,
      this.searchable = 0,
      this.historyMessage = 0,
      this.maxMemberCount = 0,
      this.superGroup = 0,
      this.deleted = 0,
      this.memberDt = 0,
      this.updateDt = 0});
  late String target;
  GroupType type;
  String? name;
  String? portrait;
  int memberCount;
  String? owner;
  String? extra;
  String? remark;
  int mute;
  int joinType;
  int privateChat;
  int searchable;
  int historyMessage;
  int maxMemberCount;
  int superGroup;
  int deleted;
  int memberDt;
  int updateDt;
}
