import 'package:flutter/material.dart';

import '../../models/onboarding_profile.dart';
import '../../services/preferences_service.dart';

typedef OnboardingCompleteCallback = void Function(OnboardingProfile profile);

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.preferences,
    required this.onCompleted,
  });

  final PreferencesService preferences;
  final OnboardingCompleteCallback onCompleted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;

  SpiritualGoal? _goal;
  NevilleFamiliarity? _familiarity;
  final Set<ContentPreference> _contentPrefs = <ContentPreference>{};
  ReminderSlot? _reminderSlot;
  bool? _wantsStreaks;

  Future<void> _next() async {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    final profile = OnboardingProfile(
      goal: _goal!,
      familiarity: _familiarity!,
      contentPreferences: _contentPrefs.toList(),
      reminderSlot: _reminderSlot!,
      wantsStreaks: _wantsStreaks ?? true,
    );

    await widget.preferences.saveProfile(profile);
    widget.onCompleted(profile);
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
    });
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _goal != null;
      case 1:
        return _familiarity != null;
      case 2:
        return _contentPrefs.isNotEmpty;
      case 3:
        return _reminderSlot != null;
      case 4:
        return _wantsStreaks != null;
    }
    return false;
  }

  List<_OnboardingStep> get _steps => [
        _OnboardingStep(
          title: 'What intention brings you to the temple?',
          description:
              'Select the guiding intention so we can tailor your inner work.',
          body: _ChoiceList<SpiritualGoal>(
            options: const [
              (SpiritualGoal.stressRelief, 'Seek calm & release stress'),
              (
                SpiritualGoal.learnBible,
                'Deepen your understanding of scripture',
              ),
              (
                SpiritualGoal.manifestation,
                'Explore Neville’s imagination practice',
              ),
              (
                SpiritualGoal.dailyInspiration,
                'Invite daily inspiration & encouragement'
              ),
              (SpiritualGoal.other, 'Something else entirely'),
            ],
            selected: _goal,
            onSelected: (value) => setState(() => _goal = value),
          ),
        ),
        _OnboardingStep(
          title: 'How familiar are you with Neville Goddard’s teachings?',
          description: 'We’ll tune the guidance based on your familiarity.',
          body: _ChoiceList<NevilleFamiliarity>(
            options: const [
              (NevilleFamiliarity.none, 'New to his teachings'),
              (NevilleFamiliarity.curious, 'I know a little'),
              (NevilleFamiliarity.fan, 'I’m an avid follower'),
            ],
            selected: _familiarity,
            onSelected: (value) => setState(() => _familiarity = value),
          ),
        ),
        _OnboardingStep(
          title: 'Which guidance styles resonate with you?',
          description: 'Choose the forms of guidance that nurture you.',
          body: _MultiChoiceChips<ContentPreference>(
            options: const [
              (ContentPreference.directScripture, 'Direct scripture'),
              (
                ContentPreference.practicalAdvice,
                'Practical wisdom for daily life'
              ),
              (ContentPreference.guidedPrayer, 'Guided prayers & meditations'),
              (ContentPreference.affirmations, 'Affirmations & declarations'),
            ],
            selected: _contentPrefs,
            onChanged: (value) => setState(() {
              if (_contentPrefs.contains(value)) {
                _contentPrefs.remove(value);
              } else {
                _contentPrefs.add(value);
              }
            }),
          ),
        ),
        _OnboardingStep(
          title: 'When should we gently nudge you?',
          description: 'Choose when you’d like a soft reminder to reflect.',
          body: _ChoiceList<ReminderSlot>(
            options: const [
              (ReminderSlot.morning, 'Morning • begin the day centered'),
              (ReminderSlot.midday, 'Midday • a lunchtime reset'),
              (ReminderSlot.evening, 'Evening • wind down with peace'),
              (ReminderSlot.gentle, 'Only if I forget • gentle nudge'),
            ],
            selected: _reminderSlot,
            onSelected: (value) => setState(() => _reminderSlot = value),
          ),
        ),
        _OnboardingStep(
          title: 'Would streak tracking support you?',
          description:
              'We can celebrate your consistency with streaks—or keep things quiet if you prefer.',
          body: _ChoiceList<bool>(
            options: const [
              (true, 'Yes, celebrate my streaks'),
              (false, 'No thanks, keep it gentle'),
            ],
            selected: _wantsStreaks,
            onSelected: (value) => setState(() => _wantsStreaks = value),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps[_currentStep];
    final total = _steps.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / total,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 32),
              Text(
                step.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Expanded(child: step.body),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  if (_currentStep == 0)
                    TextButton(
                      onPressed: () async {
                        final profile = OnboardingProfile(
                          goal: SpiritualGoal.dailyInspiration,
                          familiarity: NevilleFamiliarity.none,
                          contentPreferences: const [
                            ContentPreference.directScripture
                          ],
                          reminderSlot: ReminderSlot.morning,
                          wantsStreaks: true,
                        );
                        await widget.preferences.saveProfile(profile);
                        widget.onCompleted(profile);
                      },
                      child: const Text('I’ll set this later'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canContinue ? _next : null,
                    child: Text(
                      _currentStep == total - 1 ? 'Begin my journey' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.body,
  });

  final String title;
  final String description;
  final Widget body;
}

class _ChoiceList<T> extends StatelessWidget {
  const _ChoiceList({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (value, label) = options[index];
        final isSelected = selected == value;
        return InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MultiChoiceChips<T> extends StatelessWidget {
  const _MultiChoiceChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final Set<T> selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((entry) {
        final (value, label) = entry;
        final isSelected = selected.contains(value);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(value),
        );
      }).toList(),
    );
  }
}
