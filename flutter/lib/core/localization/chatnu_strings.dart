import 'package:flutter/widgets.dart';

class ChatNuStrings {
  const ChatNuStrings._(this.isPersian);

  final bool isPersian;

  static ChatNuStrings of(BuildContext context) {
    return ChatNuStrings._(
      Localizations.localeOf(context).languageCode == 'fa',
    );
  }

  String get appName => 'ChatNU';
  String get chats => isPersian ? 'گفت‌وگوها' : 'Chats';
  String get contacts => isPersian ? 'مخاطبان' : 'Contacts';
  String get settings => isPersian ? 'تنظیمات' : 'Settings';
  String get profile => isPersian ? 'نمایه' : 'Profile';
  String get login => isPersian ? 'ورود' : 'Login';
  String get register => isPersian ? 'ثبت‌نام' : 'Register';
  String get onboarding => isPersian ? 'شروع' : 'Onboarding';
  String get splash => isPersian ? 'راه‌اندازی' : 'Splash';
  String get searchConversations =>
      isPersian ? 'جست‌وجوی گفت‌وگوها' : 'Search conversations';
  String get searchInChat => isPersian ? 'جست‌وجو در گفت‌وگو' : 'Search in chat';
  String get closeSearch => isPersian ? 'بستن جست‌وجو' : 'Close search';
  String get previousSearchResult =>
      isPersian ? 'نتیجهٔ قبلی' : 'Previous result';
  String get nextSearchResult => isPersian ? 'نتیجهٔ بعدی' : 'Next result';
  String get noMessageMatches =>
      isPersian ? 'پیامی پیدا نشد' : 'No matching messages';
  String messageSearchResult(int current, int total) => '$current/$total';
  String newMessages(int count) => isPersian
      ? '$count پیام جدید'
      : '$count new message${count == 1 ? '' : 's'}';
  String get scrollToLatest =>
      isPersian ? 'رفتن به تازه‌ترین پیام‌ها' : 'Jump to latest messages';
  String get all => isPersian ? 'همه' : 'All';
  String get unread => isPersian ? 'خوانده‌نشده' : 'Unread';
  String get personal => isPersian ? 'شخصی' : 'Personal';
  String get groups => isPersian ? 'گروه‌ها' : 'Groups';
  String get newConversation =>
      isPersian ? 'گفت‌وگوی جدید' : 'New conversation';
  String get newChat => isPersian ? 'گفت‌وگوی جدید' : 'New chat';
  String get newGroup => isPersian ? 'گروه جدید' : 'New group';
  String get findPeople => isPersian ? 'پیدا کردن افراد' : 'Find people';
  String get searchByUsername =>
      isPersian ? 'جست‌وجو با نام کاربری' : 'Search by username';
  String get typeTwoCharacters => isPersian
      ? 'برای جست‌وجو در سرور ChatNU حداقل دو نویسه وارد کنید.'
      : 'Type at least two characters to search the selected ChatNU server.';
  String get noUsersFound => isPersian ? 'کاربری پیدا نشد.' : 'No users found.';
  String get groupName => isPersian ? 'نام گروه' : 'Group name';
  String get selectedMembers =>
      isPersian ? 'اعضای انتخاب‌شده' : 'Selected members';
  String get create => isPersian ? 'ایجاد' : 'Create';
  String get cancel => isPersian ? 'لغو' : 'Cancel';
  String get done => isPersian ? 'انجام شد' : 'Done';
  String get encrypted =>
      isPersian ? 'رمزگذاری سرتاسری' : 'End-to-end encrypted';
  String members(int count) => isPersian ? '$count عضو' : '$count members';
  String get messageHint => isPersian ? 'پیام' : 'Message';
  String get send => isPersian ? 'ارسال' : 'Send';
  String get attach => isPersian ? 'پیوست' : 'Attach';
  String get back => isPersian ? 'بازگشت' : 'Back';
  String get voiceCall => isPersian ? 'تماس صوتی' : 'Voice call';
  String get videoCall => isPersian ? 'تماس تصویری' : 'Video call';
  String get queued => isPersian ? 'در صف ارسال' : 'Queued';
  String get sending => isPersian ? 'در حال ارسال' : 'Sending';
  String get sentToServer => isPersian ? 'ارسال‌شده به سرور' : 'Sent to server';
  String get failed => isPersian ? 'ناموفق' : 'Failed';
  String get retry => isPersian ? 'تلاش دوباره' : 'Retry';
  String get retryOlderMessages =>
      isPersian ? 'بارگیری دوبارهٔ پیام‌های قدیمی' : 'Retry older messages';
  String get couldNotLoadConversation =>
      isPersian ? 'گفت‌وگو بارگیری نشد.' : 'Couldn’t load this conversation.';
  String get syncingMessages =>
      isPersian ? 'در حال همگام‌سازی پیام‌ها…' : 'Syncing messages…';
  String get syncFailed => isPersian
      ? 'همگام‌سازی کامل نشد. برای تلاش دوباره بزنید.'
      : 'Couldn’t sync messages. Tap to retry.';
  String get draft => isPersian ? 'پیش‌نویس' : 'Draft';
  String get copy => isPersian ? 'کپی' : 'Copy';
  String get pinned => isPersian ? 'سنجاق‌شده' : 'Pinned';
  String get pin => isPersian ? 'سنجاق کردن' : 'Pin';
  String get unpin => isPersian ? 'برداشتن سنجاق' : 'Unpin';
  String get muted => isPersian ? 'بی‌صدا' : 'Muted';
  String get mute => isPersian ? 'بی‌صدا کردن' : 'Mute';
  String get unmute => isPersian ? 'فعال کردن صدا' : 'Unmute';
  String get noConversation =>
      isPersian ? 'یک گفت‌وگو را انتخاب کنید' : 'Select a conversation';
  String get noConversations => isPersian
      ? 'هنوز گفت‌وگویی ندارید.'
      : 'You do not have any conversations yet.';
  String get startConversation =>
      isPersian ? 'شروع گفت‌وگو' : 'Start a conversation';
  String get noSearchResults =>
      isPersian ? 'نتیجه‌ای پیدا نشد.' : 'No matching conversations.';
  String get account => isPersian ? 'حساب' : 'Account';
  String get connection => isPersian ? 'اتصال' : 'Connection';
  String get appearance => isPersian ? 'ظاهر' : 'Appearance';
  String get privacySecurity =>
      isPersian ? 'حریم خصوصی و امنیت' : 'Privacy & Security';
  String get server => isPersian ? 'سرور' : 'Server';
  String get systemTheme => isPersian ? 'سیستم' : 'System';
  String get lightTheme => isPersian ? 'روشن' : 'Light';
  String get darkTheme => isPersian ? 'تیره' : 'Dark';
  String get glassQuality => isPersian ? 'کیفیت شیشه' : 'Glass quality';
  String get glassFull => isPersian ? 'کامل' : 'Full';
  String get glassBalanced => isPersian ? 'متعادل' : 'Balanced';
  String get glassReduced => isPersian ? 'کاهش‌یافته' : 'Reduced';
  String get logout => isPersian ? 'خروج' : 'Log out';
  String get refresh => isPersian ? 'تازه‌سازی' : 'Refresh';
  String get realtimeConnected =>
      isPersian ? 'اتصال زنده برقرار است' : 'Realtime connected';
  String get realtimeConnecting =>
      isPersian ? 'در حال اتصال زنده' : 'Connecting realtime';
  String get realtimeDisconnected =>
      isPersian ? 'اتصال زنده قطع است' : 'Realtime disconnected';
  String get offlineSession => isPersian ? 'نشست آفلاین' : 'Offline session';
  String get offlineSessionDetail => isPersian
      ? 'اعتبارنامهٔ ذخیره‌شده موجود است، اما سرور انتخابی فعلاً قابل تأیید نیست.'
      : 'Cached credentials are available, but the selected server could not be verified right now.';
  String get secureMessaging =>
      isPersian ? 'پیام‌رسانی خصوصی و امن' : 'Private, secure messaging';
  String get dismiss => isPersian ? 'بستن' : 'Dismiss';
  String get attachmentDownload =>
      isPersian ? 'دانلود و رمزگشایی' : 'Download and decrypt';
  String get saveCancelled => isPersian ? 'ذخیره لغو شد.' : 'Save cancelled.';
  String get attachmentSaved => isPersian
      ? 'پیوست رمزگشایی و ذخیره شد.'
      : 'Attachment decrypted and saved.';
}
