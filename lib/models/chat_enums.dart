// File: lib/models/chat_enums.dart
// Purpose: Message type enums for chat integration in brokerflow_admin.

enum ChatMessageMessageType {
  text,
  image,
  video,
  audio,
  document,
  location;

  String get dbValue {
    switch (this) {
      case ChatMessageMessageType.text:
        return 'text';
      case ChatMessageMessageType.image:
        return 'image';
      case ChatMessageMessageType.video:
        return 'video';
      case ChatMessageMessageType.audio:
        return 'audio';
      case ChatMessageMessageType.document:
        return 'document';
      case ChatMessageMessageType.location:
        return 'location';
    }
  }

  static ChatMessageMessageType fromDbValue(String? value) {
    if (value == null) return ChatMessageMessageType.text;
    switch (value.toLowerCase().trim()) {
      case 'text':
        return ChatMessageMessageType.text;
      case 'image':
        return ChatMessageMessageType.image;
      case 'video':
        return ChatMessageMessageType.video;
      case 'audio':
        return ChatMessageMessageType.audio;
      case 'document':
        return ChatMessageMessageType.document;
      case 'location':
        return ChatMessageMessageType.location;
      default:
        return ChatMessageMessageType.text;
    }
  }
}
