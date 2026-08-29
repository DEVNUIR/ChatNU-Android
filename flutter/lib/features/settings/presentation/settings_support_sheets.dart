import 'package:chatnu/core/config/server_endpoint.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:flutter/material.dart';

Future<void> showChatNuProfileSheet(
  BuildContext context, {
  required ChatNuUser user,
  required ChatNuServerEndpoint endpoint,
}) => _showSheet(
  context,
  title: _fa(context) ? 'نمایهٔ ChatNU' : 'ChatNU profile',
  icon: Icons.person_rounded,
  children: <Widget>[
    Center(child: _ProfileAvatar(user: user, size: 84)),
    const SizedBox(height: 16),
    Text(
      user.displayName,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      '@${user.username}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: context.chatNu.textMuted,
      ),
    ),
    if (user.bio?.trim().isNotEmpty == true) ...<Widget>[
      const SizedBox(height: 12),
      Text(user.bio!.trim(), textAlign: TextAlign.center),
    ],
    const SizedBox(height: 24),
    _InfoRow(
      icon: Icons.dns_outlined,
      title: _fa(context) ? 'سرور فعال' : 'Active server',
      value: endpoint.restUri.host,
    ),
    _InfoRow(
      icon: Icons.lock_outline_rounded,
      title: _fa(context) ? 'رمزگذاری' : 'Encryption',
      value: 'Device Envelope v2',
    ),
    const SizedBox(height: 14),
    _Notice(
      icon: Icons.edit_outlined,
      text: _fa(context)
          ? 'ویرایش نام، تصویر و توضیح نمایه پس از افزودن قرارداد امن به‌روزرسانی نمایه به API فعال می‌شود. این نسخه اطلاعات محلی جعلی ذخیره نمی‌کند.'
          : 'Editing display name, avatar and bio will be enabled after the authenticated profile-update contract lands. This build does not save fake local-only profile data.',
    ),
  ],
);

Future<void> showAccountsServersSheet(
  BuildContext context, {
  required ChatNuUser user,
  required ChatNuServerEndpoint endpoint,
}) => _showSheet(
  context,
  title: _fa(context) ? 'حساب‌ها و سرورها' : 'Accounts & servers',
  icon: Icons.switch_account_rounded,
  children: <Widget>[
    _AccountServerCard(user: user, endpoint: endpoint),
    const SizedBox(height: 16),
    _Notice(
      icon: Icons.security_rounded,
      text: _fa(context)
          ? 'هر حساب ChatNU باید توکن‌ها، شناسهٔ دستگاه، کلیدهای رمزگذاری و اتصال زندهٔ مستقل خود را داشته باشد. سوییچ حساب فقط پس از مهاجرت امن خزانهٔ نشست‌ها فعال می‌شود.'
          : 'Each ChatNU account needs its own tokens, device identity, encryption keys and realtime lifecycle. Account switching will be enabled only after the secure session vault is migrated to a multi-account registry.',
    ),
    const SizedBox(height: 12),
    _Notice(
      icon: Icons.qr_code_2_rounded,
      text: _fa(context)
          ? 'QR و پیوندهای chatnu:// برای افزودن سرور/relay در قرارداد provisioning نسخه‌دار تعریف می‌شوند؛ QR هرگز شامل توکن، کلید خصوصی یا کد بازیابی نخواهد بود.'
          : 'QR and chatnu:// links for server/relay provisioning will use a versioned configuration contract. QR payloads will never contain tokens, private keys or recovery codes.',
    ),
  ],
);

Future<void> showGettingStartedSheet(BuildContext context) => _showSheet(
  context,
  title: _fa(context) ? 'شروع کار با ChatNU' : 'Getting started',
  icon: Icons.auto_awesome_rounded,
  children: <Widget>[
    _GuideStep(
      number: 1,
      icon: Icons.person_add_alt_1_rounded,
      title: _fa(context) ? 'هویت خود را بسازید' : 'Create your identity',
      body: _fa(context)
          ? 'نام نمایشی، نام کاربری و رمز عبور را در جریان ثبت‌نام مرحله‌ای انتخاب کنید و کد بازیابی را در جای امن نگه دارید.'
          : 'Choose your display name, username and password in the staged signup flow, then store your recovery code somewhere safe.',
    ),
    _GuideStep(
      number: 2,
      icon: Icons.dns_outlined,
      title: _fa(context) ? 'سرور را بررسی کنید' : 'Verify your server',
      body: _fa(context)
          ? 'سرور انتخابی مرز اعتماد شماست. ChatNU اتصال TLS نامعتبر را برای راحتی دور نمی‌زند.'
          : 'Your selected server is part of your trust boundary. ChatNU does not bypass invalid TLS for convenience.',
    ),
    _GuideStep(
      number: 3,
      icon: Icons.person_search_rounded,
      title: _fa(context) ? 'افراد را پیدا کنید' : 'Find people',
      body: _fa(context)
          ? 'با نام کاربری جست‌وجو کنید، گفت‌وگوی مستقیم امن بسازید یا اعضا را برای یک گروه انتخاب کنید.'
          : 'Search by username, start an encrypted direct conversation, or select members for a group.',
    ),
    _GuideStep(
      number: 4,
      icon: Icons.attach_file_rounded,
      title: _fa(context) ? 'رسانه را امن بفرستید' : 'Share media securely',
      body: _fa(context)
          ? 'فایل‌ها قبل از آپلود روی دستگاه رمز می‌شوند. تصاویر، ویدیو و صدا از همان مسیر پیوست رمزگذاری‌شده استفاده می‌کنند.'
          : 'Files are encrypted on-device before upload. Images, video and audio use the same encrypted attachment transport.',
    ),
    _GuideStep(
      number: 5,
      icon: Icons.video_call_rounded,
      title: _fa(context) ? 'تماس مستقیم برقرار کنید' : 'Make a direct call',
      body: _fa(context)
          ? 'تماس صوتی و تصویری یک‌به‌یک از بالای گفت‌وگوی مستقیم در دسترس است. تماس گروهی نیازمند signaling چندطرفهٔ جداگانه است.'
          : 'One-to-one audio/video calling is available from a direct chat. Group calling needs a separate multiparty signaling design.',
    ),
  ],
);

Future<void> showFaqSheet(BuildContext context) => _showSheet(
  context,
  title: _fa(context) ? 'پرسش‌های متداول' : 'FAQ',
  icon: Icons.help_outline_rounded,
  children: <Widget>[
    _Faq(
      question: _fa(context)
          ? 'آیا سرور پیام‌های من را می‌خواند؟'
          : 'Can the server read my messages?',
      answer: _fa(context)
          ? 'محتوای پیام با ChatNU Device Envelope v2 روی دستگاه رمز می‌شود. سرور ciphertext و فرادادهٔ لازم برای تحویل را نگهداری می‌کند.'
          : 'Message content is encrypted on-device with ChatNU Device Envelope v2. The server stores ciphertext plus the delivery metadata required by the protocol.',
    ),
    _Faq(
      question: _fa(context)
          ? 'پیوست‌ها چگونه محافظت می‌شوند؟'
          : 'How are attachments protected?',
      answer: _fa(context)
          ? 'بایت‌های فایل با کلید تصادفی AES-GCM روی دستگاه رمز می‌شوند؛ کلید و nonce داخل payload پیام رمزگذاری‌شده قرار می‌گیرند.'
          : 'Attachment bytes are encrypted on-device with a random AES-GCM key; the key and nonce travel inside the encrypted message payload.',
    ),
    _Faq(
      question: _fa(context)
          ? 'چرا بعضی قابلیت‌ها هنوز نمایش داده نمی‌شوند؟'
          : 'Why are some features not shown yet?',
      answer: _fa(context)
          ? 'ChatNU کنترل بدون backend واقعی اضافه نمی‌کند. قابلیت‌هایی مثل تماس گروهی فقط زمانی نمایش داده می‌شوند که قرارداد production آن‌ها وجود داشته باشد.'
          : 'ChatNU does not add controls without real backend semantics. Features such as group calls appear only when their production contract exists.',
    ),
    _Faq(
      question: _fa(context)
          ? 'آیا می‌توانم سرور خودم را اجرا کنم؟'
          : 'Can I run my own server?',
      answer: _fa(context)
          ? 'بله. ChatNU برای self-hosting طراحی شده است؛ کلاینت باید endpoint و الزامات TLS آن سرور را به‌طور صریح تأیید کند.'
          : 'Yes. ChatNU is designed for self-hosting; the client must explicitly trust the endpoint and TLS requirements of that server.',
    ),
  ],
);

Future<void> showAboutSheet(BuildContext context) => _showSheet(
  context,
  title: _fa(context) ? 'دربارهٔ ChatNU' : 'About ChatNU',
  icon: Icons.info_outline_rounded,
  children: <Widget>[
    const Center(child: Icon(Icons.forum_rounded, size: 52)),
    const SizedBox(height: 14),
    Text(
      'ChatNU',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      _fa(context)
          ? 'پیام‌رسان خصوصی و self-hostable با رمزگذاری سمت دستگاه.'
          : 'A private, self-hostable messenger with device-side encryption.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    const SizedBox(height: 24),
    const _InfoRow(
      icon: Icons.code_rounded,
      title: 'Developed by',
      value: 'devnu.ir',
    ),
    const _InfoRow(
      icon: Icons.tag_rounded,
      title: 'Client',
      value: 'ChatNU Flutter 1.2.0',
    ),
    _InfoRow(
      icon: Icons.lock_rounded,
      title: _fa(context) ? 'مدل امنیتی' : 'Security model',
      value: 'ChatNU Device Envelope v2',
    ),
  ],
);

Future<void> _showSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  final palette = context.chatNu;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: palette.backgroundElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 9),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.borderHighlight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: <Widget>[
                        Icon(icon, size: 23),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: palette.borderSubtle),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
              sliver: SliverList(delegate: SliverChildListDelegate(children)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final ChatNuUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.chatNu.glassMedium,
        image: url == null || url.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(user.initials, style: Theme.of(context).textTheme.labelLarge)
          : null,
    );
  }
}

class _AccountServerCard extends StatelessWidget {
  const _AccountServerCard({required this.user, required this.endpoint});

  final ChatNuUser user;
  final ChatNuServerEndpoint endpoint;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.glassWeak,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          _ProfileAvatar(user: user, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('@${user.username}'),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(Icons.dns_outlined, size: 14),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        endpoint.restUri.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: palette.success),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.glassMedium,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$number. $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 14),
    title: Text(question, style: Theme.of(context).textTheme.titleMedium),
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20, color: context.chatNu.textMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(title)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.glassWeak,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

bool _fa(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'fa';
