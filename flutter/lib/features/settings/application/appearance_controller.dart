import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppearanceState {
  const AppearanceState({
    this.themeMode = ThemeMode.system,
    this.glassEffectLevel = GlassEffectLevel.balanced,
    this.restored = false,
  });

  final ThemeMode themeMode;
  final GlassEffectLevel glassEffectLevel;
  final bool restored;

  AppearanceState copyWith({
    ThemeMode? themeMode,
    GlassEffectLevel? glassEffectLevel,
    bool? restored,
  }) {
    return AppearanceState(
      themeMode: themeMode ?? this.themeMode,
      glassEffectLevel: glassEffectLevel ?? this.glassEffectLevel,
      restored: restored ?? this.restored,
    );
  }
}

class AppearanceController extends Notifier<AppearanceState> {
  static const _themeKey = 'chatnu.appearance.theme';
  static const _glassKey = 'chatnu.appearance.glass';

  @override
  AppearanceState build() {
    Future<void>.microtask(_restore);
    return const AppearanceState();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _safeWrite(_themeKey, mode.name);
  }

  Future<void> setGlassEffectLevel(GlassEffectLevel level) async {
    state = state.copyWith(glassEffectLevel: level);
    ref.read(glassEffectLevelProvider.notifier).setLevel(level);
    await _safeWrite(_glassKey, level.name);
  }

  Future<void> _restore() async {
    try {
      final store = ref.read(secretStoreProvider);
      final themeValue = await store.read(_themeKey);
      final glassValue = await store.read(_glassKey);
      final theme = ThemeMode.values.firstWhere(
        (value) => value.name == themeValue,
        orElse: () => ThemeMode.system,
      );
      final glass = GlassEffectLevel.values.firstWhere(
        (value) => value.name == glassValue,
        orElse: () => GlassEffectLevel.balanced,
      );
      if (!ref.mounted) return;
      ref.read(glassEffectLevelProvider.notifier).setLevel(glass);
      state = AppearanceState(
        themeMode: theme,
        glassEffectLevel: glass,
        restored: true,
      );
    } catch (_) {
      // Appearance preferences are non-critical. A storage failure must never
      // block authentication or messaging startup.
      if (ref.mounted) state = state.copyWith(restored: true);
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await ref.read(secretStoreProvider).write(key, value);
    } catch (_) {
      // Keep the in-memory choice even if persistence is unavailable.
    }
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceState>(
      AppearanceController.new,
    );
