import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'models/onboarding_profile.dart';
import 'models/premium_state.dart';
import 'models/streak_state.dart';
import 'repositories/profile_repository.dart';
import 'repositories/streak_repository.dart';
import 'screens/devotional/devotional_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/notification_service.dart';
import 'services/premium_service.dart';
import 'services/preferences_service.dart';
import 'utils/api_base.dart';
import 'utils/reminders.dart';
import 'exceptions/paywall_required_exception.dart';
import 'widgets/paywall_dialog.dart';
import 'services/paywall_service.dart';

String describeGoal(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'Find peace & stress relief';
    case SpiritualGoal.learnBible:
      return 'Deepen understanding of scripture';
    case SpiritualGoal.manifestation:
      return 'Manifestation & Neville’s teachings';
    case SpiritualGoal.dailyInspiration:
      return 'Daily inspiration & encouragement';
    case SpiritualGoal.other:
      return 'A unique spiritual journey';
  }
}

String goalHeadline(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'Let’s slow your breathing and rediscover calm.';
    case SpiritualGoal.learnBible:
      return 'Ready to uncover fresh insight in scripture today?';
    case SpiritualGoal.manifestation:
      return 'Let’s imagine the good you desire into being.';
    case SpiritualGoal.dailyInspiration:
      return 'A gentle spark is here to brighten your day.';
    case SpiritualGoal.other:
      return 'We’re honored to walk alongside your path.';
  }
}

String goalSubtext(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'A short reflection curated to steady mind and body awaits you.';
    case SpiritualGoal.learnBible:
      return 'Today’s guidance leans into context and meaning behind beloved verses.';
    case SpiritualGoal.manifestation:
      return 'We’ll weave Neville’s imagination practices into today’s prompts.';
    case SpiritualGoal.dailyInspiration:
      return 'A verse and affirmation are ready to uplift your spirit.';
    case SpiritualGoal.other:
      return 'Tailored reflections will adapt as we learn more from your check-ins.';
  }
}

String familiarityLabel(NevilleFamiliarity familiarity) {
  switch (familiarity) {
    case NevilleFamiliarity.none:
      return 'New to Neville Goddard';
    case NevilleFamiliarity.curious:
      return 'Exploring Neville’s teachings';
    case NevilleFamiliarity.fan:
      return 'Neville devotee';
  }
}

String contentPreferenceLabel(ContentPreference preference) {
  switch (preference) {
    case ContentPreference.directScripture:
      return 'Scripture';
    case ContentPreference.practicalAdvice:
      return 'Practical wisdom';
    case ContentPreference.guidedPrayer:
      return 'Guided prayer';
    case ContentPreference.affirmations:
      return 'Affirmations';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env');
  } else {
    final envMap = const {
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      'API_BASE_URL': String.fromEnvironment('API_BASE_URL', defaultValue: ''),
      'STRIPE_PUBLISHABLE_KEY': String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: ''),
      'STRIPE_CHECKOUT_MONTHLY':
          String.fromEnvironment('STRIPE_CHECKOUT_MONTHLY', defaultValue: ''),
      'STRIPE_CHECKOUT_ANNUAL':
          String.fromEnvironment('STRIPE_CHECKOUT_ANNUAL', defaultValue: ''),
    };
    final buffer = StringBuffer();
    envMap.forEach((key, value) {
      if (value.isNotEmpty) {
        buffer.writeln('$key=$value');
      }
    });
    dotenv.testLoad(fileInput: buffer.toString());
  }
  final supabaseUrl = dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via .env or --dart-define.');
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await NotificationService.instance.init();
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpiritualBibleChatApp();
  }
}

class SpiritualBibleChatApp extends StatefulWidget {
  const SpiritualBibleChatApp({super.key});

  @override
  State<SpiritualBibleChatApp> createState() => _SpiritualBibleChatAppState();
}

class _SpiritualBibleChatAppState extends State<SpiritualBibleChatApp> {
  PreferencesService? _preferences;
  OnboardingProfile? _profile;
  StreakState _streak = StreakState.initial();
  bool _isLoading = true;
  PremiumState _premiumState = PremiumState.initial();
  DateTime? _nextReminder;
  final GlobalKey<_AppShellState> _appShellKey = GlobalKey<_AppShellState>();
  StreamSubscription<String>? _notificationSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  VoidCallback? _premiumListener;

  final SupabaseClient _supabase = Supabase.instance.client;
  late final ProfileRepository _profileRepository =
      ProfileRepository(_supabase);
  late final StreakRepository _streakRepository = StreakRepository(_supabase);
  final PaywallService _paywallService = PaywallService();
  final PremiumService _premiumService = PremiumService.instance;

  @override
  void initState() {
    super.initState();
    _premiumService.configure();
    _premiumListener = () {
      final premium = _premiumService.state.value;
      if (mounted) {
        setState(() {
          _premiumState = premium;
        });
      }
    };
    _premiumService.state.addListener(_premiumListener!);

    _bootstrap();
    _notificationSubscription =
        NotificationService.instance.taps.listen(_handleNotificationPayload);
    NotificationService.instance.getLaunchPayload().then((payload) {
      if (payload != null) {
        _handleNotificationPayload(payload);
      }
    });
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (event) async {
        final userId = event.session?.user.id;
        if (userId != null) {
          await _syncFromSupabase(userId);
          await _premiumService.logIn(userId);
        } else {
          await _premiumService.logOut();
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _authSubscription?.cancel();
    if (_premiumListener != null) {
      _premiumService.state.removeListener(_premiumListener!);
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await PreferencesService.instance();
    final existingProfile = prefs.loadProfile();
    final streak = prefs.loadStreak();
    DateTime? nextReminder = prefs.loadNextReminder();
    if (existingProfile != null && nextReminder == null) {
      nextReminder = nextReminderDate(existingProfile.reminderSlot);
      await prefs.saveNextReminder(nextReminder);
      await NotificationService.instance.scheduleReminder(
        existingProfile.reminderSlot,
        nextReminder,
      );
    }
    if (!mounted) return;
    setState(() {
      _preferences = prefs;
      _profile = existingProfile;
      _streak = streak;
      _nextReminder = nextReminder;
      _isLoading = false;
    });

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _syncFromSupabase(userId);
      await _premiumService.logIn(userId);
    } else {
      await _premiumService.refreshStatus();
    }
  }

  Future<void> _syncFromSupabase(String userId) async {
    try {
      final profileRecord = await _profileRepository.fetch(userId);
      if (profileRecord != null) {
        await _preferences?.saveProfile(profileRecord.profile);
        if (profileRecord.nextReminderAt != null) {
          await _preferences?.saveNextReminder(profileRecord.nextReminderAt!);
        }
        if (mounted) {
          setState(() {
            _profile = profileRecord.profile;
            _nextReminder = profileRecord.nextReminderAt ?? _nextReminder;
          });
        }
      }

      final remoteStreak = await _streakRepository.fetch(userId);
      if (remoteStreak != null) {
        await _preferences?.saveStreak(remoteStreak);
        if (mounted) {
          setState(() {
            _streak = remoteStreak;
          });
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Supabase sync failed: $error\n$stackTrace');
    }

    await _premiumService.refreshStatus();
  }

  Future<void> _handleProfileCompleted(OnboardingProfile profile) async {
    await _saveProfile(profile);
  }

  Future<void> _saveProfile(OnboardingProfile profile) async {
    await _preferences!.saveProfile(profile);
    await _scheduleReminder(profile.reminderSlot);
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _profileRepository.upsert(
        userId,
        profile,
        nextReminder: _nextReminder,
      );
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
    });
  }

  Future<void> _handleProfileUpdated(OnboardingProfile profile) async {
    await _saveProfile(profile);
  }

  Future<void> _refreshFromSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _syncFromSupabase(userId);
    }
  }

  Future<void> _handlePaywall(BuildContext context, String message) async {
    if (!context.mounted) return;
    await _paywallService.logPaywallEvent('view', trigger: message);
    final previousPremium = _premiumService.state.value.isPremium;
    final upgradeAttempted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PaywallDialog(
        message: message,
        onSelectPlan: (annual) async {
          try {
            final success = await _premiumService.startPurchaseFlow(annual: annual);
            if (!success) {
              throw Exception('Checkout cancelled or blocked.');
            }
            await _refreshFromSupabase();
            await _premiumService.refreshStatus();
            return true;
          } catch (error) {
            debugPrint('Purchase flow failed: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.toString())),
              );
            }
            return false;
          }
        },
      ),
    );
    await _refreshFromSupabase();
    await _premiumService.refreshStatus();

    final nowPremium = _premiumService.state.value.isPremium;
    if (!context.mounted) return;

    if (nowPremium && !previousPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium unlocked! Enjoy unlimited access.'),
        ),
      );
      await _paywallService.logPaywallEvent(
        'purchase_success',
        trigger: _premiumService.state.value.planId ?? 'unknown',
      );
    } else if (upgradeAttempted == true && !nowPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete checkout in the newly opened window, then return to continue.'),
        ),
      );
      await _paywallService.logPaywallEvent('purchase_cancelled');
    }
  }

  Future<void> _handleStreakUpdated(StreakState streak) async {
    await _preferences!.saveStreak(streak);
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _streakRepository.upsert(userId, streak);
    }
    if (!mounted) return;
    setState(() {
      _streak = streak;
    });
  }

  Future<void> _handleResetStreak() async {
    await _preferences!.clearStreak();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _streakRepository.reset(userId);
    }
    if (!mounted) return;
    setState(() {
      _streak = StreakState.initial();
    });
    if (_profile != null) {
      await _scheduleReminder(_profile!.reminderSlot);
    }
  }

  Future<void> _handleManageSubscription() async {
    try {
      final opened = await _premiumService.openManageSubscription();
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open billing portal right now.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _scheduleReminder(ReminderSlot slot) async {
    if (_preferences == null) return;
    final next = nextReminderDate(slot);
    await _preferences!.saveNextReminder(next);
    await NotificationService.instance.scheduleReminder(slot, next);
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _profileRepository.updateReminder(userId, next);
    }
    if (!mounted) return;
    setState(() {
      _nextReminder = next;
    });
  }

  void _handleNotificationPayload(String payload) {
    if (_appShellKey.currentState == null) {
      return;
    }
    _appShellKey.currentState!.handleNotification(payload);
  }

  Future<void> _handleRetakeRequested() async {
    await _preferences!.clearProfile();
    await _preferences!.clearNextReminder();
    await NotificationService.instance.cancelAll();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _nextReminder = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5E4AE3),
      brightness: Brightness.light,
    );

    final theme = ThemeData(
      colorScheme: baseColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      textTheme: Theme.of(context).textTheme.apply(
            fontFamily: 'Roboto',
            bodyColor: const Color(0xFF1F1B2E),
            displayColor: const Color(0xFF1F1B2E),
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1F1B2E),
      ),
    );

    final darkTheme = ThemeData(
      colorScheme: baseColorScheme.copyWith(brightness: Brightness.dark),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF12101C),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFFE7E1FF),
            displayColor: const Color(0xFFE7E1FF),
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE7E1FF),
      ),
    );

    Widget content;
    if (_isLoading || _preferences == null) {
      content = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_profile == null) {
      content = OnboardingFlow(
        preferences: _preferences!,
        onCompleted: _handleProfileCompleted,
      );
    } else {
      content = _AppShell(
        key: _appShellKey,
        profile: _profile!,
        streak: _streak,
        onStreakUpdated: _handleStreakUpdated,
        onResetStreak: _handleResetStreak,
        nextReminder: _nextReminder,
        onScheduleReminder: _scheduleReminder,
        onProfileUpdated: _handleProfileUpdated,
        onRetakeRequested: _handleRetakeRequested,
        onSignOut: () async {
          await Supabase.instance.client.auth.signOut();
          await _premiumService.logOut();
          if (mounted) {
            setState(() {
              _profile = null;
              _premiumState = PremiumState.initial();
            });
          }
          AuthGate.continueAsGuest(context);
        },
        onSignInRequested: () => AuthGate.requestSignIn(context),
        onShowPaywall: _handlePaywall,
        premium: _premiumState,
        onManageSubscription: _handleManageSubscription,
      );
    }

    return MaterialApp(
      title: 'Spiritual Bible Chat',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: theme,
      darkTheme: darkTheme,
      routes: {
        '/payment/success': (_) => const _CheckoutResultScreen(
              title: 'Thank you!',
              message:
                  'Payment received. You now have unlimited chats and devotionals. Return to the app to continue your journey.',
            ),
        '/payment/canceled': (_) => const _CheckoutResultScreen(
              title: 'Checkout canceled',
              message:
                  'No worries—your card was not charged. You can retry the upgrade whenever you’re ready.',
            ),
      },
      home: AuthGate(
        child: content,
      ),
    );
  }
}

class _CheckoutResultScreen extends StatelessWidget {
  const _CheckoutResultScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Return to app'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({
    super.key,
    required this.profile,
    required this.streak,
    required this.onStreakUpdated,
    required this.onResetStreak,
    required this.nextReminder,
    required this.onScheduleReminder,
    required this.onProfileUpdated,
    required this.onRetakeRequested,
    required this.onSignOut,
    required this.onSignInRequested,
    required this.onShowPaywall,
    required this.premium,
    required this.onManageSubscription,
  });

  final OnboardingProfile profile;
  final StreakState streak;
  final Future<void> Function(StreakState streak) onStreakUpdated;
  final Future<void> Function() onResetStreak;
  final DateTime? nextReminder;
  final Future<void> Function(ReminderSlot slot) onScheduleReminder;
  final Future<void> Function(OnboardingProfile profile) onProfileUpdated;
  final Future<void> Function() onRetakeRequested;
  final Future<void> Function() onSignOut;
  final VoidCallback onSignInRequested;
  final Future<void> Function(BuildContext context, String message)
      onShowPaywall;
  final PremiumState premium;
  final Future<void> Function() onManageSubscription;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  final GlobalKey<_ChatScreenState> _chatKey = GlobalKey<_ChatScreenState>();

  void handleNotification(String payload) {
    if (!mounted) return;
    if (payload == 'open_chat') {
      setState(() {
        _currentIndex = 1;
      });
    } else {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  Future<void> _updateReminder(ReminderSlot slot) async {
    final updatedProfile = widget.profile.copyWith(reminderSlot: slot);
    await widget.onProfileUpdated(updatedProfile);
    await widget.onScheduleReminder(slot);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showReminderSheet() async {
    final theme = Theme.of(context);
    final reminder = await showModalBottomSheet<ReminderSlot>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose reminder time',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...ReminderSlot.values.map(
                  (slot) => ListTile(
                    title: Text(reminderLabel(slot)),
                    leading: Radio<ReminderSlot>(
                      value: slot,
                      groupValue: widget.profile.reminderSlot,
                      onChanged: (value) {
                        Navigator.of(context).pop(value);
                      },
                    ),
                    onTap: () => Navigator.of(context).pop(slot),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reminder != null && reminder != widget.profile.reminderSlot) {
      await _updateReminder(reminder);
    }
  }

  Future<void> _registerActivity() async {
    final current = widget.streak;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = current.lastCompletedDate == null
        ? null
        : DateTime(
            current.lastCompletedDate!.year,
            current.lastCompletedDate!.month,
            current.lastCompletedDate!.day,
          );

    if (last != null && last.compareTo(today) == 0) {
      return;
    }

    int nextStreak = 1;
    if (last != null) {
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        nextStreak = current.currentStreak + 1;
      }
    }

    final updated = StreakState(
      currentStreak: nextStreak,
      longestStreak: nextStreak > current.longestStreak
          ? nextStreak
          : current.longestStreak,
      lastCompletedDate: today,
    );
    await widget.onStreakUpdated(updated);
    await widget.onScheduleReminder(widget.profile.reminderSlot);
  }

  Future<void> _handleReflect(String verseText, String verseReference) async {
    final prompt =
        'Help me reflect on $verseReference which says: $verseText. Offer Neville Goddard-inspired insight and a practical application.';
    setState(() {
      _currentIndex = 1;
    });
    await _registerActivity();
    await _chatKey.currentState?.sendPrompt(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streak;
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final isSignedIn = supabaseUser != null;
    final userEmail = supabaseUser?.email;
    final destinations = [
      _NavigationDestination(
        label: 'Today',
        icon: Icons.self_improvement_outlined,
        builder: (context) => _TodayScreen(
          profile: widget.profile,
          onReflectPressed: _handleReflect,
          onMarkComplete: _registerActivity,
          onAdjustReminders: _showReminderSheet,
          streak: streak,
          nextReminder: widget.nextReminder,
          onShowPaywall: widget.onShowPaywall,
        ),
      ),
      _NavigationDestination(
        label: 'Chat',
        icon: Icons.chat_bubble_outline,
        builder: (context) => _ChatScreen(
          key: _chatKey,
          onActivityLogged: _registerActivity,
          onPaywall: widget.onShowPaywall,
        ),
      ),
      _NavigationDestination(
        label: 'Progress',
        icon: Icons.emoji_events_outlined,
        builder: (context) => _ProgressScreen(
          profile: widget.profile,
          streak: streak,
          onResetStreak: widget.onResetStreak,
          nextReminder: widget.nextReminder,
        ),
      ),
      _NavigationDestination(
        label: 'Profile',
        icon: Icons.person_outline,
        builder: (context) => _ProfileScreen(
          profile: widget.profile,
          onAdjustReminders: _showReminderSheet,
          onRetakeRequested: widget.onRetakeRequested,
          nextReminder: widget.nextReminder,
          onSignOut: widget.onSignOut,
          onSignInRequested: widget.onSignInRequested,
          isSignedIn: isSignedIn,
          userEmail: userEmail,
          onShowPaywall: widget.onShowPaywall,
          premium: widget.premium,
          onManageSubscription: widget.onManageSubscription,
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: destinations
              .map(
                (destination) => destination.builder(context),
              )
              .toList(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TodayScreen extends StatelessWidget {
  const _TodayScreen({
    required this.profile,
    required this.onReflectPressed,
    required this.onMarkComplete,
    required this.onAdjustReminders,
    required this.streak,
    required this.nextReminder,
    required this.onShowPaywall,
  });

  final OnboardingProfile profile;
  final Future<void> Function(String verseText, String verseReference)
      onReflectPressed;
  final Future<void> Function() onMarkComplete;
  final Future<void> Function() onAdjustReminders;
  final StreakState streak;
  final DateTime? nextReminder;
  final Future<void> Function(BuildContext context, String message)
      onShowPaywall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const verseText = '“Be still, and know that I am God.”';
    const verseReference = 'Psalm 46:10';
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(
            'Today',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                _TodayGreeting(theme: theme, profile: profile),
                const SizedBox(height: 16),
                _TodayStreakStatus(
                  streak: streak,
                  nextReminder: nextReminder,
                ),
                const SizedBox(height: 20),
                _VerseOfTheDayCard(
                  theme: theme,
                  onReflect: () => onReflectPressed(
                    verseText,
                    verseReference,
                  ),
                  completed: streak.hasCompletedToday,
                  onMarkComplete: onMarkComplete,
                ),
                const SizedBox(height: 24),
                _QuickActionsSection(
                  theme: theme,
                  profile: profile,
                  onOpenDevotional: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DevotionalScreen(
                          profile: profile,
                          verseText: verseText,
                          verseReference: verseReference,
                          onPaywall: onShowPaywall,
                        ),
                      ),
                    );
                  },
                  onAdjustReminders: () => onAdjustReminders(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayGreeting extends StatelessWidget {
  const _TodayGreeting({
    required this.theme,
    required this.profile,
  });

  final ThemeData theme;
  final OnboardingProfile profile;

  @override
  Widget build(BuildContext context) {
    final headline = goalHeadline(profile.goal);
    final subtext = goalSubtext(profile.goal);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TodayStreakStatus extends StatelessWidget {
  const _TodayStreakStatus({
    required this.streak,
    required this.nextReminder,
  });

  final StreakState streak;
  final DateTime? nextReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCompleted = streak.hasCompletedToday;
    final title = hasCompleted
        ? 'Beautiful! Today’s reflection is already counted.'
        : 'Keep your streak alive with a moment of reflection.';
    final subtitle = hasCompleted
        ? 'Current streak: ${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'} • Longest: ${streak.longestStreak}'
        : 'Current streak: ${streak.currentStreak} • Longest: ${streak.longestStreak}';
    final reminderLabel = describeReminderDate(context, nextReminder);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: hasCompleted
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCompleted
                    ? Icons.auto_awesome
                    : Icons.local_fire_department_outlined,
                color: hasCompleted
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Next reminder: $reminderLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  const _VerseOfTheDayCard({
    required this.theme,
    required this.onReflect,
    required this.completed,
    required this.onMarkComplete,
  });

  final ThemeData theme;
  final VoidCallback onReflect;
  final bool completed;
  final Future<void> Function() onMarkComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verse of the Day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '“Be still, and know that I am God.”',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Psalm 46:10',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: onReflect,
                child: const Text('Reflect with AI'),
              ),
              const SizedBox(width: 12),
              if (!completed)
                OutlinedButton.icon(
                  onPressed: () async {
                    await onMarkComplete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked today as complete. Great job!'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark complete'),
                )
              else
                Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('Completed today'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.theme,
    required this.profile,
    required this.onOpenDevotional,
    required this.onAdjustReminders,
  });

  final ThemeData theme;
  final OnboardingProfile profile;
  final VoidCallback onOpenDevotional;
  final VoidCallback onAdjustReminders;

  @override
  Widget build(BuildContext context) {
    final preferenceChips = profile.contentPreferences
        .map(contentPreferenceLabel)
        .map(
          (label) => Chip(
            label: Text(label),
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue your practice',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (preferenceChips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferenceChips,
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const _QuickActionChip(
              icon: Icons.auto_mode,
              label: 'Resume chat',
            ),
            _QuickActionChip(
              icon: Icons.book_outlined,
              label: 'Daily devotional',
              onPressed: onOpenDevotional,
            ),
            _QuickActionChip(
              icon: Icons.notifications_active_outlined,
              label: 'Adjust reminders',
              onPressed: onAdjustReminders,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label is on the roadmap.')),
            );
          },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

class _ChatScreen extends StatefulWidget {
  const _ChatScreen({super.key, this.onActivityLogged, this.onPaywall});

  final Future<void> Function()? onActivityLogged;
  final Future<void> Function(BuildContext, String)? onPaywall;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _listController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  bool _isSending = false;
  String? _threadId;

  @override
  void dispose() {
    _inputController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String get _apiBase => apiBaseUrl();

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!_listController.hasClients) return;
    _listController.animateTo(
      _listController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> sendPrompt(String text) =>
      _sendMessage(contentOverride: text, trackActivity: false);

  Future<void> _sendMessage({
    String? contentOverride,
    bool trackActivity = true,
  }) async {
    final rawText = (contentOverride ?? _inputController.text).trim();
    if (rawText.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: rawText, isUser: true));
    });
    if (contentOverride == null) {
      _inputController.clear();
    } else {
      _inputController.text = '';
    }
    await _scrollToBottom();

    try {
      final uri = Uri.parse('$_apiBase/api/v1/chat');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...await authHeaders(),
        },
        body: jsonEncode({
          'message': rawText,
          if (_threadId != null) 'threadId': _threadId,
        }),
      );

      if (response.statusCode >= 400) {
        if (response.statusCode == 401) {
          throw Exception('Please sign in to continue this conversation.');
        }
        if (response.statusCode == 402) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw PaywallRequiredException(
            body['error'] as String? ?? 'Upgrade required to continue.',
          );
        }
        throw Exception('Server responded with ${response.statusCode}');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final botMessage = payload['message'] as String?;
      final newThreadId = payload['threadId'] as String?;

      if (botMessage == null || botMessage.isEmpty) {
        throw Exception('Assistant returned an empty response.');
      }

      setState(() {
        _threadId = newThreadId ?? _threadId;
        _messages.add(_ChatMessage(text: botMessage, isUser: false));
      });
      await _scrollToBottom();
      if (trackActivity && widget.onActivityLogged != null) {
        await widget.onActivityLogged!();
      }
    } catch (error) {
      if (error is PaywallRequiredException) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: error.message,
              isUser: false,
            ),
          );
        });
        if (context.mounted && widget.onPaywall != null) {
          await widget.onPaywall!(context, error.message);
        }
      } else {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text:
                  'Something went wrong while contacting the assistant. Please try again shortly.',
              isUser: false,
            ),
          );
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spiritual Assistant',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ask anything on your heart. Neville-inspired, scripture-rooted guidance will appear here.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Start a conversation whenever you are ready.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _listController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final entry = _messages[index];
                          final alignment = entry.isUser
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart;
                          final bubbleColor = entry.isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant;
                          final textColor = entry.isUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface;

                          return Align(
                            alignment: alignment,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                entry.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_isSending) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your prayer, question, or reflection…',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSending ? null : () => _sendMessage(),
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressScreen extends StatelessWidget {
  const _ProgressScreen({
    required this.profile,
    required this.streak,
    required this.onResetStreak,
    required this.nextReminder,
  });

  final OnboardingProfile profile;
  final StreakState streak;
  final Future<void> Function() onResetStreak;
  final DateTime? nextReminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motivationText = profile.wantsStreaks
        ? 'Keep the momentum going! Complete today’s reflection to begin building your streak.'
        : 'You’ve opted for a gentle rhythm. We’ll keep quiet track and nudge you only when helpful.';
    final streakLabel =
        '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'}';
    final longestLabel =
        '${streak.longestStreak} day${streak.longestStreak == 1 ? '' : 's'}';
    final reminderDescription = describeReminderDate(context, nextReminder);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Journey',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    streakLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(motivationText, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Longest streak: $longestLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer
                            .withOpacity(0.8),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Achievements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_active,
                  color: theme.colorScheme.primary),
              title: const Text('Preferred reminder'),
              subtitle: Text(
                  '${reminderLabel(profile.reminderSlot)} • $reminderDescription'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.local_fire_department,
                  color: theme.colorScheme.primary),
              title: const Text('Longest streak'),
              subtitle: Text(longestLabel),
              trailing: profile.wantsStreaks
                  ? TextButton(
                      onPressed: onResetStreak,
                      child: const Text('Reset streak'),
                    )
                  : null,
            ),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text('Milestone ${index + 1}'),
                    subtitle:
                        const Text('Unlocked once streak goals are reached.'),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.profile,
    required this.onAdjustReminders,
    required this.onRetakeRequested,
    required this.nextReminder,
    required this.onSignOut,
    required this.onSignInRequested,
    required this.isSignedIn,
    required this.userEmail,
    required this.onShowPaywall,
    required this.premium,
    required this.onManageSubscription,
  });

  final OnboardingProfile profile;
  final Future<void> Function() onAdjustReminders;
  final Future<void> Function() onRetakeRequested;
  final DateTime? nextReminder;
  final Future<void> Function() onSignOut;
  final VoidCallback onSignInRequested;
  final bool isSignedIn;
  final String? userEmail;
  final Future<void> Function(BuildContext, String) onShowPaywall;
  final PremiumState premium;
  final Future<void> Function() onManageSubscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = userEmail?.trim();
    final initials = (email != null && email.isNotEmpty)
        ? email.substring(0, 1).toUpperCase()
        : 'SJ';
    final title = isSignedIn ? (email ?? 'Signed in user') : 'Guest Pilgrim';
    final subtitle = premium.isPremium
        ? 'Premium plan active.'
        : (isSignedIn
            ? 'Signed in via Supabase.'
            : 'Personalize once accounts are enabled.');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: isSignedIn
                ? null
                : TextButton(
                    onPressed: onSignInRequested,
                    child: const Text('Sign in'),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'My focus',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(describeGoal(profile.goal)),
                backgroundColor:
                    theme.colorScheme.primaryContainer.withOpacity(0.6),
              ),
              Chip(
                label: Text(familiarityLabel(profile.familiarity)),
                backgroundColor:
                    theme.colorScheme.secondaryContainer.withOpacity(0.6),
              ),
              ...profile.contentPreferences.map(
                (pref) => Chip(
                  label: Text(contentPreferenceLabel(pref)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(Icons.quiz_outlined, color: theme.colorScheme.primary),
            title: const Text(
              'Retake onboarding quiz',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Refresh your spiritual focus & preferences.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await onRetakeRequested();
            },
          ),
          if (premium.isPremium) ...[
            _PremiumSummaryCard(
              premium: premium,
              onManageSubscription: onManageSubscription,
            ),
            const SizedBox(height: 24),
          ],
          _ProfileSettingTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notification schedule',
            subtitle:
                '${reminderLabel(profile.reminderSlot)} • ${describeReminderDate(context, nextReminder)}',
            onTap: onAdjustReminders,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              profile.wantsStreaks
                  ? Icons.local_fire_department
                  : Icons.self_improvement,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Streak tracking',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              profile.wantsStreaks
                  ? 'Badges and streak celebrations are enabled.'
                  : 'Gentle mode active — no streak pressure.',
            ),
          ),
          _ProfileSettingTile(
            icon: Icons.workspace_premium_outlined,
            title:
                premium.isPremium ? 'Premium unlocked' : 'Upgrade to Premium',
            subtitle: premium.isPremium
                ? 'Thank you for supporting the mission.'
                : 'Unlock unlimited chat and devotional content.',
            isDestructive: false,
            onTap: premium.isPremium
                ? null
                : () => onShowPaywall(
                      context,
                      'Upgrade to experience unlimited guidance and devotionals.',
                    ),
          ),
          const Divider(height: 32),
          const _ProfileSettingTile(
            icon: Icons.description_outlined,
            title: 'Privacy policy',
          ),
          const _ProfileSettingTile(
            icon: Icons.security_outlined,
            title: 'Terms of service',
          ),
          const _ProfileSettingTile(
            icon: Icons.help_outline,
            title: 'Need help?',
            subtitle: 'Reach out to our support team.',
          ),
          const SizedBox(height: 16),
          if (isSignedIn)
            FilledButton.icon(
              onPressed: () async {
                await onSignOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            )
          else
            OutlinedButton(
              onPressed: onSignInRequested,
              child: const Text('Sign in to sync'),
            ),
        ],
      ),
    );
  }
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? theme.colorScheme.error : null,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title is on the roadmap.')),
            );
          },
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  const _PremiumSummaryCard({required this.premium, required this.onManageSubscription});

  final PremiumState premium;
  final Future<void> Function() onManageSubscription;

  String _planLabel(String? planId) {
    switch (planId) {
      case 'premium_annual':
        return 'Annual Premium';
      case 'premium_monthly':
        return 'Monthly Premium';
      default:
        return 'Premium plan';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renewalText = premium.expiresAt != null
        ? 'Renews on ${_formatDate(premium.expiresAt)}'
        : 'Renews automatically each cycle';
    final trialText = premium.isTrial && premium.trialEndsAt != null
        ? 'Trial ends ${_formatDate(premium.trialEndsAt)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                _planLabel(premium.planId),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            renewalText,
            style: theme.textTheme.bodyMedium,
          ),
          if (trialText != null) ...[
            const SizedBox(height: 4),
            Text(
              trialText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              await onManageSubscription();
            },
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Manage subscription'),
          ),
        ],
      ),
    );
  }
}
