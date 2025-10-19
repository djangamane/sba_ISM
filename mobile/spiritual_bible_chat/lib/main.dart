import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'widgets/ankh_button.dart';
import 'widgets/glass_card.dart';
import 'widgets/ghost_button.dart';
import 'widgets/quick_action_chip.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/paywall_service.dart';
import 'data/daily_verses.dart';
import 'data/legal_content.dart';
import 'theme/app_theme.dart';

String describeGoal(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'Soothe stress & breathe easier';
    case SpiritualGoal.learnBible:
      return 'Deepen scripture understanding';
    case SpiritualGoal.manifestation:
      return 'Imagine with Neville';
    case SpiritualGoal.dailyInspiration:
      return 'Daily spark of encouragement';
    case SpiritualGoal.other:
      return 'A path uniquely yours';
  }
}

String goalHeadline(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'Let’s slow your breath and welcome ease.';
    case SpiritualGoal.learnBible:
      return 'Ready to open scripture for fresh revelation?';
    case SpiritualGoal.manifestation:
      return 'Let’s imagine boldly with Neville’s lens.';
    case SpiritualGoal.dailyInspiration:
      return 'A gentle spark is here to brighten your spirit.';
    case SpiritualGoal.other:
      return 'Your path is sacred—I’m honored to walk with you.';
  }
}

String goalSubtext(SpiritualGoal goal) {
  switch (goal) {
    case SpiritualGoal.stressRelief:
      return 'We’ll soften the nervous system with a calm verse and grounding practice.';
    case SpiritualGoal.learnBible:
      return 'Today’s guidance unwraps context and meaning woven through beloved passages.';
    case SpiritualGoal.manifestation:
      return 'We’ll blend scripture with Neville’s creative prayer to shape what you’re calling in.';
    case SpiritualGoal.dailyInspiration:
      return 'A verse, affirmation, and gentle prompt are waiting to lift your day.';
    case SpiritualGoal.other:
      return 'Each check-in teaches me your rhythm so the reflections stay lovingly tailored.';
  }
}

String familiarityLabel(NevilleFamiliarity familiarity) {
  switch (familiarity) {
    case NevilleFamiliarity.none:
      return 'New to Neville’s teachings';
    case NevilleFamiliarity.curious:
      return 'Exploring Neville’s imagination practice';
    case NevilleFamiliarity.fan:
      return 'Devoted to Neville’s wisdom';
  }
}

String contentPreferenceLabel(ContentPreference preference) {
  switch (preference) {
    case ContentPreference.directScripture:
      return 'Scripture passages';
    case ContentPreference.practicalAdvice:
      return 'Grounded life wisdom';
    case ContentPreference.guidedPrayer:
      return 'Guided prayer & meditation';
    case ContentPreference.affirmations:
      return 'Affirmations & declarations';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env');
  } else {
    const envMap = {
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      'SUPABASE_ANON_KEY':
          String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      'API_BASE_URL': String.fromEnvironment('API_BASE_URL', defaultValue: ''),
      'STRIPE_PUBLISHABLE_KEY':
          String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: ''),
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

class _SpiritualBibleChatAppState extends State<SpiritualBibleChatApp>
    with WidgetsBindingObserver {
  PreferencesService? _preferences;
  OnboardingProfile? _profile;
  StreakState _streak = StreakState.initial();
  bool _isLoading = true;
  PremiumState _premiumState = PremiumState.initial();
  DateTime? _nextReminder;
  DailyVerse? _dailyVerse;
  DateTime? _dailyVerseLoadedFor;
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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
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

    await _syncDayState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncDayState());
    }
  }

  Future<void> _syncDayState() async {
    if (_preferences == null) return;
    final now = DateTime.now();
    await _maybeResetStreak(now);
    final normalized = DateTime(now.year, now.month, now.day);
    if (_dailyVerseLoadedFor == null || _dailyVerseLoadedFor != normalized) {
      await _loadDailyVerseFor(now);
    }
  }

  Future<void> _loadDailyVerseFor(DateTime date) async {
    try {
      final verse = await DailyVerseProvider.verseForDate(date);
      if (!mounted) return;
      setState(() {
        _dailyVerse = verse;
        _dailyVerseLoadedFor = DateTime(date.year, date.month, date.day);
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load daily verse: $error\n$stackTrace');
    }
  }

  Future<void> _maybeResetStreak(DateTime now) async {
    if (_preferences == null) return;
    final current = _streak;
    final last = current.lastCompletedDate;
    if (last == null) {
      return;
    }
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDate).inDays;
    if (diff >= 1 && current.currentStreak != 0) {
      final reset = current.copyWith(currentStreak: 0);
      await _handleStreakUpdated(reset);
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
    await _syncDayState();
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
    if (!context.mounted) return;
    final previousPremium = _premiumService.state.value.isPremium;
    final upgradeAttempted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PaywallDialog(
        message: message,
        onSelectPlan: (annual) async {
          try {
            final success =
                await _premiumService.startPurchaseFlow(annual: annual);
            if (!success) {
              throw Exception('Checkout didn’t complete. Please try again.');
            }
            await _refreshFromSupabase();
            await _premiumService.refreshStatus();
            return true;
          } catch (error) {
            debugPrint('Purchase flow failed: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'We hit a snag opening checkout. Please try again in a moment.',
                  ),
                ),
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
          content: Text(
              'Premium unlocked — your inner work now flows without limits.'),
        ),
      );
      await _paywallService.logPaywallEvent(
        'purchase_success',
        trigger: _premiumService.state.value.planId ?? 'unknown',
      );
    } else if (upgradeAttempted == true && !nowPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Complete checkout in the opened window, then return to continue your practice.'),
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
          const SnackBar(
            content: Text(
                'We couldn’t open the billing portal just now. Please try again soon.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'The subscription portal is unavailable. Please try again shortly.'),
        ),
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
    final theme = buildAppTheme();

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
          if (!mounted) return;
          setState(() {
            _profile = null;
            _premiumState = PremiumState.initial();
          });
          unawaited(Future<void>.delayed(Duration.zero, () {
            if (mounted) {
              AuthGate.continueAsGuest(context);
            }
          }));
        },
        onSignInRequested: () => AuthGate.requestSignIn(context),
        onShowPaywall: _handlePaywall,
        premium: _premiumState,
        onManageSubscription: _handleManageSubscription,
        dailyVerse: _dailyVerse,
      );
    }

    return MaterialApp(
      title: 'Spiritual Bible Chat',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/temple.png',
                fit: BoxFit.cover,
                color: AppColors.obsidian.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA0B0B0F),
                      Color(0xCC0B0B0F),
                    ],
                  ),
                ),
              ),
            ),
            if (child != null) Positioned.fill(child: child),
          ],
        );
      },
      routes: {
        '/payment/success': (_) => const _CheckoutResultScreen(
              title: 'You’re all set!',
              message:
                  'Premium access is unlocked. Keep this tab open and return when you’re ready to continue the inner work.',
              headline: 'Premium unlocked',
              accentIcon: Icons.star_rounded,
              actionLabel: 'Return to temple',
            ),
        '/payment/canceled': (_) => const _CheckoutResultScreen(
              title: 'Maybe next time?',
              message:
                  'No charge was made. When you’re ready, the premium temple awaits—unlimited conversations, devotionals, and sacred practices.',
              headline: 'Your seat is still open',
              accentIcon: Icons.auto_fix_high_rounded,
              actionLabel: 'Return & upgrade',
              promptUpgrade: true,
            ),
      },
      home: AuthGate(
        child: content,
      ),
    );
  }
}

class _CheckoutResultScreen extends StatelessWidget {
  const _CheckoutResultScreen({
    required this.title,
    required this.message,
    required this.headline,
    required this.accentIcon,
    this.actionLabel,
    this.promptUpgrade = false,
  });

  final String title;
  final String message;
  final String headline;
  final IconData accentIcon;
  final String? actionLabel;
  final bool promptUpgrade;

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
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  accentIcon,
                  color: theme.colorScheme.onPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              if (promptUpgrade) ...[
                AnkhButton(
                  label: actionLabel ?? 'Return & upgrade',
                  onPressed: () => Navigator.of(context).maybePop(),
                  expand: true,
                ),
              ] else ...[
                AnkhButton(
                  label: actionLabel ?? 'Return to temple',
                  onPressed: () => Navigator.of(context).maybePop(),
                  expand: true,
                ),
              ],
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
    required this.dailyVerse,
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
  final DailyVerse? dailyVerse;

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

  Future<void> _showStreakModeSheet() async {
    final current = widget.profile.wantsStreaks;
    final selection = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => _StreakModeBottomSheet(current: current),
    );
    if (selection == null || selection == current) {
      return;
    }
    final updatedProfile = widget.profile.copyWith(wantsStreaks: selection);
    await widget.onProfileUpdated(updatedProfile);
    if (!mounted) return;
    final message = selection
        ? 'Streak celebrations are back on.'
        : 'Gentle rhythm activated — streak celebrations hidden.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          onResumeChat: () {
            setState(() {
              _currentIndex = 1;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _chatKey.currentState?.focusInput();
            });
          },
          streak: streak,
          nextReminder: widget.nextReminder,
          onShowPaywall: widget.onShowPaywall,
          dailyVerse: widget.dailyVerse,
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
          onToggleStreakMode: _showStreakModeSheet,
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
    required this.onResumeChat,
    required this.streak,
    required this.nextReminder,
    required this.onShowPaywall,
    required this.dailyVerse,
  });

  final OnboardingProfile profile;
  final Future<void> Function(String verseText, String verseReference)
      onReflectPressed;
  final Future<void> Function() onMarkComplete;
  final Future<void> Function() onAdjustReminders;
  final VoidCallback onResumeChat;
  final StreakState streak;
  final DateTime? nextReminder;
  final Future<void> Function(BuildContext context, String message)
      onShowPaywall;
  final DailyVerse? dailyVerse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = dailyVerse;
    const fallbackText = 'Be still, and know that I am God.';
    final rawText = verse?.text.trim();
    final versePlainText =
        (rawText == null || rawText.isEmpty) ? fallbackText : rawText;
    final sanitized = versePlainText
        .replaceAll('“', '')
        .replaceAll('”', '')
        .replaceAll('"', '')
        .trim();
    final verseText = '“$sanitized”';
    final verseReference = (verse?.reference.trim().isNotEmpty ?? false)
        ? verse!.reference
        : 'Psalm 46:10';
    final verseThemes = verse?.themes ?? const <String>[];
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
                    versePlainText,
                    verseReference,
                  ),
                  completed: streak.hasCompletedToday,
                  onMarkComplete: onMarkComplete,
                  verseText: verseText,
                  verseReference: verseReference,
                  themes: verseThemes,
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
                          verseText: versePlainText,
                          verseReference: verseReference,
                          onPaywall: onShowPaywall,
                        ),
                      ),
                    );
                  },
                  onAdjustReminders: () => onAdjustReminders(),
                  onResumeChat: onResumeChat,
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
    return GlassCard(
      padding: const EdgeInsets.all(26),
      backgroundGradient: AppGradients.aurora,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.obsidian.withOpacity(0.85),
            ),
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
    final backgroundColor = hasCompleted
        ? AppColors.scarabGreen.withOpacity(0.18)
        : AppColors.onyx.withOpacity(0.6);
    final iconColor =
        hasCompleted ? AppColors.scarabGreen : theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(22),
      backgroundColor: backgroundColor,
      borderColor: iconColor.withOpacity(0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCompleted
                    ? Icons.auto_awesome
                    : Icons.local_fire_department_outlined,
                color: iconColor,
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
              color: AppColors.quartz,
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
    required this.verseText,
    required this.verseReference,
    this.themes = const [],
  });

  final ThemeData theme;
  final VoidCallback onReflect;
  final bool completed;
  final Future<void> Function() onMarkComplete;
  final String verseText;
  final String verseReference;
  final List<String> themes;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.onyx.withOpacity(0.58),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verse of the Day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            verseText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verseReference,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.maatGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (themes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themes
                  .map(
                    (label) => Chip(
                      label: Text(label),
                      backgroundColor: AppColors.onyx.withOpacity(0.45),
                      labelStyle: theme.textTheme.bodySmall,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AnkhButton(
                label: 'Reflect with AI',
                onPressed: onReflect,
              ),
              if (!completed)
                GhostButton(
                  label: 'Count today',
                  icon: Icons.check_circle_outline,
                  onPressed: () async {
                    await onMarkComplete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Today’s reflection is counted. Keep shining.',
                          ),
                        ),
                      );
                    }
                  },
                )
              else
                const QuickActionChip(
                  icon: Icons.check_circle,
                  label: 'Counted today',
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
    required this.onResumeChat,
  });

  final ThemeData theme;
  final OnboardingProfile profile;
  final VoidCallback onOpenDevotional;
  final VoidCallback onAdjustReminders;
  final VoidCallback onResumeChat;

  @override
  Widget build(BuildContext context) {
    final preferenceChips = profile.contentPreferences
        .map(contentPreferenceLabel)
        .map(
          (label) => Chip(
            label: Text(label),
            backgroundColor: AppColors.onyx.withOpacity(0.45),
            labelStyle: theme.textTheme.bodySmall,
          ),
        )
        .toList();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.onyx.withOpacity(0.52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue your inner work',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (preferenceChips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferenceChips,
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickActionChip(
                icon: Icons.auto_mode,
                label: 'Resume sacred chat',
                onPressed: onResumeChat,
              ),
              QuickActionChip(
                icon: Icons.book_outlined,
                label: 'Open devotional',
                onPressed: onOpenDevotional,
              ),
              QuickActionChip(
                icon: Icons.notifications_active_outlined,
                label: 'Refine reminders',
                onPressed: onAdjustReminders,
              ),
            ],
          ),
        ],
      ),
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

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.onFocusInput});

  final VoidCallback onFocusInput;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.aurora,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.obsidian,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ask from the heart.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Offer a question, a tension, or a gratitude. I’ll respond with scripture-rooted wisdom. — OMEGA',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.quartz,
            ),
          ),
          const SizedBox(height: 24),
          GhostButton(
            label: 'Open the channel',
            icon: Icons.edit_note_outlined,
            onPressed: onFocusInput,
          ),
        ],
      ),
    );
  }
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
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _listController.dispose();
    _inputFocusNode.dispose();
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

  void focusInput() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_inputFocusNode);
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
          throw Exception('Sign in to continue this conversation.');
        }
        if (response.statusCode == 402) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw PaywallRequiredException(
            body['error'] as String? ??
                'Premium unlock required to continue the dialogue.',
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
        if (!mounted) return;
        if (widget.onPaywall != null) {
          await widget.onPaywall!(context, error.message);
        }
      } else {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text:
                  'The temple connection flickered. Give it a breath and try again.',
              isUser: false,
            ),
          );
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Connection dipped for a moment. Please try once more.'),
          ),
        );
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
          'Inner Temple Guide',
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
            Expanded(
              child: GlassCard(
                padding: _messages.isEmpty
                    ? const EdgeInsets.all(32)
                    : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                backgroundColor: AppColors.onyx.withOpacity(0.62),
                child: _messages.isEmpty
                    ? _ChatEmptyState(onFocusInput: focusInput)
                    : ListView.builder(
                        controller: _listController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final entry = _messages[index];
                          final alignment = entry.isUser
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart;
                          final bubbleColor = entry.isUser
                              ? AppGradients.aurora.colors.last
                              : AppColors.onyx.withOpacity(0.65);
                          final textColor = entry.isUser
                              ? AppColors.obsidian
                              : AppColors.papyrus;

                          return Align(
                            alignment: alignment,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(18),
                                border: entry.isUser
                                    ? Border.all(
                                        color:
                                            AppColors.maatGold.withOpacity(0.4),
                                      )
                                    : Border.all(
                                        color: AppColors.maatGold
                                            .withOpacity(0.22),
                                      ),
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
            AnimatedOpacity(
              opacity: _isSending ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : const SizedBox(height: 12),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: AppColors.onyx.withOpacity(0.72),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Type your prayer, question, or reflection…',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.quartz.withOpacity(0.8),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnkhButton(
                    label: 'Send',
                    icon: Icons.send,
                    onPressed: _isSending ? null : () => _sendMessage(),
                    isLoading: _isSending,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ],
              ),
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            backgroundGradient: const LinearGradient(
              colors: [
                Color(0x332A2721),
                Color(0x665BD6E0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  streakLabel,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.maatGold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  motivationText,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Longest streak: $longestLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.quartz,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.onyx.withOpacity(0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestones & reminders',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _ProgressDetailRow(
                  icon: Icons.notifications_active,
                  title: 'Preferred reminder',
                  subtitle:
                      '${reminderLabel(profile.reminderSlot)} • $reminderDescription',
                ),
                const SizedBox(height: 16),
                _ProgressDetailRow(
                  icon: Icons.local_fire_department,
                  title: 'Longest streak',
                  subtitle: longestLabel,
                  trailing: profile.wantsStreaks
                      ? GhostButton(
                          label: 'Reset streak',
                          onPressed: onResetStreak,
                          dense: true,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _ProgressDetailRow(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Milestones',
                  subtitle:
                      'Badges unlock as you sustain your rhythm. Stay consistent to reveal them.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDetailRow extends StatelessWidget {
  const _ProgressDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.onyx.withOpacity(0.7),
          ),
          child: Icon(icon, color: AppColors.maatGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.quartz,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _StreakModeBottomSheet extends StatelessWidget {
  const _StreakModeBottomSheet({required this.current});

  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How should streaks feel?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose how we honor your daily rhythm. You can switch this anytime.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _StreakModeTile(
              value: true,
              groupValue: current,
              title: 'Celebrate my streaks',
              subtitle:
                  'Show flames, milestones, and celebratory prompts as you stay consistent.',
            ),
            _StreakModeTile(
              value: false,
              groupValue: current,
              title: 'Keep it gentle',
              subtitle:
                  'Hide streak celebrations and keep the journey soft and private.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakModeTile extends StatelessWidget {
  const _StreakModeTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final bool groupValue;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RadioListTile<bool>(
      value: value,
      groupValue: groupValue,
      onChanged: (selection) {
        Navigator.of(context).pop(selection ?? groupValue);
      },
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
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
    required this.onToggleStreakMode,
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
  final Future<void> Function() onToggleStreakMode;

  Future<void> _showLegalDocument(
    BuildContext context,
    LegalDocumentType type,
  ) async {
    try {
      final content = await LegalContent.document(type);
      if (!context.mounted) return;
      final title = type == LegalDocumentType.privacy
          ? 'Privacy Policy'
          : 'Terms of Service';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LegalDocumentScreen(
            title: title,
            content: content,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load document: $error')),
      );
    }
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'janga.bussaja@gmail.com',
      queryParameters: {
        'subject': 'Spiritual Bible Chat Support Request',
      },
    );
    final launched = await launchUrl(uri);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No email app detected. Reach us at janga.bussaja@gmail.com.'),
        ),
      );
    }
  }

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
          GlassCard(
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.onyx.withOpacity(0.62),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.maatGold.withOpacity(0.18),
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.maatGold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.quartz,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSignedIn)
                  GhostButton(
                    label: 'Sign in',
                    onPressed: onSignInRequested,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.onyx.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My focus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    QuickActionChip(
                      icon: Icons.self_improvement_outlined,
                      label: describeGoal(profile.goal),
                    ),
                    QuickActionChip(
                      icon: Icons.menu_book_outlined,
                      label: familiarityLabel(profile.familiarity),
                    ),
                    ...profile.contentPreferences.map(
                      (pref) => QuickActionChip(
                        icon: Icons.brightness_5_outlined,
                        label: contentPreferenceLabel(pref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.onyx.withOpacity(0.55),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              leading:
                  const Icon(Icons.quiz_outlined, color: AppColors.maatGold),
              title: Text(
                'Revisit onboarding journey',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Refresh your intention and practice preferences.',
                style: theme.textTheme.bodySmall,
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.maatGold),
              onTap: () async {
                await onRetakeRequested();
              },
            ),
          ),
          if (premium.isPremium) ...[
            const SizedBox(height: 24),
            _PremiumSummaryCard(
              premium: premium,
              onManageSubscription: onManageSubscription,
            ),
          ],
          const SizedBox(height: 24),
          _ProfileSettingTile(
            icon: Icons.notifications_active_outlined,
            title: 'Sacred reminders',
            subtitle:
                '${reminderLabel(profile.reminderSlot)} • ${describeReminderDate(context, nextReminder)}',
            onTap: onAdjustReminders,
          ),
          _ProfileSettingTile(
            icon: profile.wantsStreaks
                ? Icons.local_fire_department
                : Icons.self_improvement,
            title: 'Streak rhythm',
            subtitle: profile.wantsStreaks
                ? 'Badges and streak celebrations are enabled.'
                : 'Gentle mode active — no streak pressure.',
            onTap: onToggleStreakMode,
          ),
          _ProfileSettingTile(
            icon: Icons.workspace_premium_outlined,
            title:
                premium.isPremium ? 'Premium unlocked' : 'Upgrade to Premium',
            subtitle: premium.isPremium
                ? 'Thank you for supporting the mission.'
                : 'Unlock limitless sacred conversations and devotionals.',
            onTap: premium.isPremium
                ? null
                : () => onShowPaywall(
                      context,
                      'Unlock limitless guidance and devotionals with Premium.',
                    ),
          ),
          const SizedBox(height: 8),
          _ProfileSettingTile(
            icon: Icons.description_outlined,
            title: 'Privacy policy',
            onTap: () => _showLegalDocument(
              context,
              LegalDocumentType.privacy,
            ),
          ),
          _ProfileSettingTile(
            icon: Icons.security_outlined,
            title: 'Terms of service',
            onTap: () => _showLegalDocument(
              context,
              LegalDocumentType.terms,
            ),
          ),
          _ProfileSettingTile(
            icon: Icons.help_outline,
            title: 'Need support? Notice something off?',
            subtitle: 'Reach out and we’ll respond with care.',
            onTap: () => _contactSupport(context),
          ),
          const SizedBox(height: 20),
          if (isSignedIn)
            GhostButton(
              label: 'Sign out',
              icon: Icons.logout,
              onPressed: () async {
                await onSignOut();
              },
            )
          else
            AnkhButton(
              label: 'Sign in to sync',
              onPressed: onSignInRequested,
              expand: true,
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.onyx.withOpacity(0.5),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          leading: Icon(
            icon,
            color: AppColors.maatGold,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.quartz,
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.maatGold),
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'That doorway isn’t open yet, but it’s on the roadmap.'),
                  ),
                );
              },
        ),
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SelectableText(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  const _PremiumSummaryCard(
      {required this.premium, required this.onManageSubscription});

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

    return GlassCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.onyx.withOpacity(0.65),
      borderColor: AppColors.maatGold.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.aurora,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.obsidian,
                  size: 22,
                ),
              ),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.quartz,
            ),
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
          GhostButton(
            label: 'Manage subscription',
            icon: Icons.manage_accounts_outlined,
            onPressed: () async {
              await onManageSubscription();
            },
          ),
        ],
      ),
    );
  }
}
