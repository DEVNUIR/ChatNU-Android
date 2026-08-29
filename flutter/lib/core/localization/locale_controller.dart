import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatNuLocalePreference { system, english, persian }

class ChatNuLocaleState {
  const ChatNuLocaleState(this.preference);

  final ChatNuLocalePreference preference;

  Locale? get locale => switch (preference) {
    ChatNuLocalePreference.system => null,
    ChatNuLocalePreference.english => const Locale('en'),
    ChatNuLocalePreference.persian => const Locale('fa'),
  };
}

class LocaleController extends Notifier<ChatNuLocaleState> {
  static const _storageKey = 'chatnu.locale.preference';
  bool _restored = false;

  @override
  ChatNuLocaleState build() {
    if (!_restored) {
      _restored = true;
      Future<void>.microtask(_restore);
    }
    return const ChatNuLocaleState(ChatNuLocalePreference.system);
  }

  Future<void> _restore() async {
    try {
      final stored = await ref.read(secretStoreProvider).read(_storageKey);
      final preference = switch (stored) {
        'english' => ChatNuLocalePreference.english,
        'persian' => ChatNuLocalePreference.persian,
        _ => ChatNuLocalePreference.system,
      };
      state = ChatNuLocaleState(preference);
    } catch (_) {
      // Language restoration is non-critical and must never block startup.
    }
  }

  Future<void> setPreference(ChatNuLocalePreference preference) async {
    state = ChatNuLocaleState(preference);
    try {
      await ref.read(secretStoreProvider).write(_storageKey, preference.name);
    } catch (_) {
      // Keep the in-memory choice even if preference persistence is unavailable.
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, ChatNuLocaleState>(
  LocaleController.new,
);
