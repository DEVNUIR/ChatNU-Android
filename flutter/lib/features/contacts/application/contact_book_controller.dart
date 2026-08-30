import 'dart:async';
import 'dart:convert';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/features/accounts/domain/chatnu_user.dart';
import 'package:chatnu/features/auth/application/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactBookState {
  const ContactBookState({
    this.contacts = const <ChatNuUser>[],
    this.loading = true,
  });

  final List<ChatNuUser> contacts;
  final bool loading;

  bool contains(String userId) => contacts.any((user) => user.id == userId);
}

class ContactBookController extends Notifier<ContactBookState> {
  @override
  ContactBookState build() {
    final session = ref.watch(sessionProvider);
    final endpoint = ref.watch(serverEndpointProvider);
    final user = session.user;
    if (user == null) {
      return const ContactBookState(loading: false);
    }
    final scope = '${endpoint.identityNamespace}|${user.id}';
    Future<void>.microtask(() => _hydrate(scope));
    return const ContactBookState();
  }

  Future<void> add(ChatNuUser user) async {
    if (state.contains(user.id)) {
      return;
    }
    final next = <ChatNuUser>[...state.contacts, user]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    state = ContactBookState(contacts: next, loading: false);
    await _persist();
  }

  Future<void> remove(String userId) async {
    state = ContactBookState(
      contacts: state.contacts
          .where((user) => user.id != userId)
          .toList(growable: false),
      loading: false,
    );
    await _persist();
  }

  Future<void> _hydrate(String scope) async {
    try {
      final encoded = await ref.read(secretStoreProvider).read(_key(scope));
      if (encoded == null || encoded.isEmpty) {
        if (ref.mounted) {
          state = const ContactBookState(loading: false);
        }
        return;
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Invalid contact book.');
      }
      final contacts = decoded
          .whereType<Map>()
          .map(
            (raw) => raw.map((key, value) => MapEntry(key.toString(), value)),
          )
          .map(_fromJson)
          .whereType<ChatNuUser>()
          .toList(growable: false)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      if (ref.mounted) {
        state = ContactBookState(contacts: contacts, loading: false);
      }
    } catch (_) {
      if (ref.mounted) {
        state = const ContactBookState(loading: false);
      }
    }
  }

  Future<void> _persist() async {
    final session = ref.read(sessionProvider);
    final user = session.user;
    if (user == null) {
      return;
    }
    final endpoint = ref.read(serverEndpointProvider);
    final scope = '${endpoint.identityNamespace}|${user.id}';
    final encoded = jsonEncode(
      state.contacts
          .map(
            (contact) => <String, dynamic>{
              'id': contact.id,
              'username': contact.username,
              'displayName': contact.displayName,
              'avatarUrl': contact.avatarUrl,
              'bio': contact.bio,
            },
          )
          .toList(growable: false),
    );
    try {
      await ref.read(secretStoreProvider).write(_key(scope), encoded);
    } catch (_) {
      // Saving a convenience contact must never break messaging.
    }
  }

  String _key(String scope) =>
      'chatnu.contacts.v1.${base64Url.encode(utf8.encode(scope)).replaceAll('=', '')}';

  ChatNuUser? _fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final username = json['username']?.toString();
    if (id == null || id.isEmpty || username == null || username.isEmpty) {
      return null;
    }
    return ChatNuUser(
      id: id,
      username: username,
      displayName: json['displayName']?.toString() ?? username,
      avatarUrl: json['avatarUrl']?.toString(),
      bio: json['bio']?.toString(),
    );
  }
}

final contactBookProvider =
    NotifierProvider<ContactBookController, ContactBookState>(
      ContactBookController.new,
    );
