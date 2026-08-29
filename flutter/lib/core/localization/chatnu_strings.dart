import 'package:flutter/widgets.dart';

class ChatNuStrings {
  const ChatNuStrings._(this.isPersian);

  final bool isPersian;

  static ChatNuStrings of(BuildContext context) {
    return ChatNuStrings._(Localizations.localeOf(context).languageCode == 'fa');
  }

  String get appName => 'ChatNU';
  String get chats => isPersian ? 'گفت‌وگوها' : 'Chats';
  String get contacts => isPersian ? 'مخاطبان' : 'Contacts';
  String get settings => isPersian ? 'تنظیمات' : 'Settings';
  String get profile => isPersian ? 'نمایه' : 'Profile';
  String get login => isPersian ? 'ورود' : 'Login';
  String get onboarding => isPersian ? 'شروع' : 'Onboarding';
  String get splash => isPersian ? 'راه‌اندازی' : 'Splash';
  String get searchConversations =>
      isPersian ? 'جست‌وجوی گفت‌وگوها' : 'Search conversations';
  String get all => isPersian ? 'همه' : 'All';
  String get unread => isPersian ? 'خوانده‌نشده' : 'Unread';
  String get personal => isPersian ? 'شخصی' : 'Personal';
  String get groups => isPersian ? 'گروه‌ها' : 'Groups';
  String get newConversation =>
      isPersian ? 'گفت‌وگوی جدید' : 'New conversation';
  String get newGroup => isPersian ? 'گروه جدید' : 'New group';
  String get encrypted =>
      isPersian ? 'رمزگذاری سرتاسری' : 'End-to-end encrypted';
  String members(int count) => isPersian ? '$count عضو' : '$count members';
  String get messageHint => isPersian ? 'پیام' : 'Message';
  String get send => isPersian ? 'ارسال' : 'Send';
  String get attach => isPersian ? 'پیوست' : 'Attach';
  String get back => isPersian ? 'بازگشت' : 'Back';
  String get voiceCall => isPersian ? 'تماس صوتی' : 'Voice call';
  String get videoCall => isPersian ? 'تماس تصویری' : 'Video call';
  String get mockMode => isPersian
      ? 'دادهٔ محلی — بدون اتصال به سرور'
      : 'Local data — server not connected';
  String get contactsSoon => isPersian
      ? 'جست‌وجوی واقعی مخاطبان در فاز اتصال API فعال می‌شود.'
      : 'Server-backed contact search arrives with the API migration.';
  String get settingsSoon => isPersian
      ? 'پوستهٔ تنظیمات واقعی ChatNU در این مسیر قرار می‌گیرد.'
      : 'The real ChatNU settings surface lives here during migration.';
  String get routeSoon => isPersian
      ? 'این مسیر برای فاز بعدی مهاجرت آماده است.'
      : 'This route is reserved for a later migration phase.';
  String get attachmentMock => isPersian
      ? 'پیوست در این فاز فقط نمای رابط کاربری است؛ آپلودی انجام نمی‌شود.'
      : 'Attachment controls are UI-only in this phase; nothing is uploaded.';
  String get callMock => isPersian
      ? 'رابط تماس آماده است؛ WebRTC هنوز به Flutter متصل نشده.'
      : 'Call UI is staged; WebRTC is not connected to Flutter yet.';
  String get sending => isPersian ? 'در حال ارسال' : 'Sending';
  String get sentToServer =>
      isPersian ? 'ارسال‌شده به سرور' : 'Sent to server';
  String get failed => isPersian ? 'ناموفق' : 'Failed';
  String get pinned => isPersian ? 'سنجاق‌شده' : 'Pinned';
  String get muted => isPersian ? 'بی‌صدا' : 'Muted';
  String get noConversation =>
      isPersian ? 'یک گفت‌وگو را انتخاب کنید' : 'Select a conversation';
}
