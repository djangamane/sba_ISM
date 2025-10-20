import 'package:flutter/material.dart';

import '../../models/onboarding_profile.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

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

  IntentionFocus? _intention;
  String? _intentionOther;
  final Set<GuidanceStyle> _guidanceStyles = <GuidanceStyle>{};
  InnerAnchorFocus? _innerAnchor;
  ClimateFeeling? _climateFeeling;
  final Set<JusticeTension> _justiceTensions = <JusticeTension>{};
  final Set<ProtectionFocus> _protectionFocus = <ProtectionFocus>{};
  String? _protectionOther;
  final Set<SolidarityPractice> _solidarityPractices = <SolidarityPractice>{};
  String _collectiveTruth = '';
  ReminderSlot? _reminderSlot;
  bool? _wantsStreaks;

  final TextEditingController _truthController = TextEditingController();
  final TextEditingController _intentionOtherController =
      TextEditingController();
  final TextEditingController _protectionOtherController =
      TextEditingController();

  @override
  void dispose() {
    _truthController.dispose();
    _intentionOtherController.dispose();
    _protectionOtherController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    final profile = OnboardingProfile(
      intention: _intention!,
      intentionOther:
          _intention == IntentionFocus.other ? _intentionOther?.trim() : null,
      guidanceStyles: _guidanceStyles.toList(),
      innerAnchor: _innerAnchor!,
      reminderSlot: _reminderSlot!,
      wantsStreaks: _wantsStreaks ?? true,
      climateFeeling: _climateFeeling!,
      justiceTensions: _justiceTensions.toList(),
      protectionFocus: _protectionFocus.toList(),
      protectionOther: _protectionFocus.contains(ProtectionFocus.other)
          ? _protectionOther?.trim()
          : null,
      solidarityPractices: _solidarityPractices.toList(),
      collectiveTruth: _collectiveTruth.trim(),
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
        if (_intention == null) return false;
        if (_intention == IntentionFocus.other) {
          return _intentionOther?.trim().isNotEmpty ?? false;
        }
        return true;
      case 1:
        return _guidanceStyles.isNotEmpty;
      case 2:
        return _innerAnchor != null;
      case 3:
        return _climateFeeling != null;
      case 4:
        return _justiceTensions.isNotEmpty;
      case 5:
        return _protectionFocus.isNotEmpty &&
            (!_protectionFocus.contains(ProtectionFocus.other) ||
                (_protectionOther?.trim().isNotEmpty ?? false));
      case 6:
        return true; // solidarity can be optional
      case 7:
        return _collectiveTruth.trim().isNotEmpty;
      case 8:
        return _reminderSlot != null;
      case 9:
        return _wantsStreaks != null;
    }
    return false;
  }

  List<_OnboardingStep> get _steps => [
        _buildIntentionStep(),
        _buildGuidanceStep(),
        _buildAnchorStep(),
        _buildClimateStep(),
        _buildJusticeStep(),
        _buildProtectionStep(),
        _buildSolidarityStep(),
        _buildTruthStep(),
        _buildReminderStep(),
        _buildStreakStep(),
      ];

  _OnboardingStep _buildIntentionStep() => _OnboardingStep(
        title: 'Where should we focus first?',
        description:
            'Choose the intention that feels most alive so I can tailor your guidance.',
        body: Column(
          children: [
            _ChoiceList<IntentionFocus>(
              options: const [
                (IntentionFocus.innerCalm, 'Find inner calm & grounding'),
                (IntentionFocus.sacredStudy, 'Drink deeply from sacred wisdom'),
                (
                  IntentionFocus.imaginalCreation,
                  'Shape the reality you’re calling in',
                ),
                (IntentionFocus.dailySpark, 'Keep a daily spark lit'),
                (IntentionFocus.other, 'Something I’ll name below'),
              ],
              selected: _intention,
              onSelected: (value) => setState(() {
                _intention = value;
              }),
            ),
            if (_intention == IntentionFocus.other) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _intentionOtherController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Share your custom intention',
                ),
                onChanged: (value) => setState(() {
                  _intentionOther = value;
                }),
              ),
            ],
          ],
        ),
      );

  _OnboardingStep _buildGuidanceStep() => _OnboardingStep(
        title: 'Which forms of wisdom feed you?',
        description:
            'Choose as many as you like; I’ll weave them into devotional prompts.',
        body: _MultiChoiceChips<GuidanceStyle>(
          options: const [
            (GuidanceStyle.scripturePassages, 'Scripture passages'),
            (GuidanceStyle.practicalWisdom, 'Practical life wisdom'),
            (GuidanceStyle.guidedPrayer, 'Guided prayer & meditation'),
            (
              GuidanceStyle.affirmationsDeclarations,
              'Affirmations & declarations',
            ),
            (GuidanceStyle.sacredHistory, 'Sacred history & context'),
          ],
          selected: _guidanceStyles,
          onChanged: (value) => setState(() {
            if (_guidanceStyles.contains(value)) {
              _guidanceStyles.remove(value);
            } else {
              _guidanceStyles.add(value);
            }
          }),
        ),
      );

  _OnboardingStep _buildAnchorStep() => _OnboardingStep(
        title: 'What inner anchor should we hold?',
        description:
            'This determines where I point you back to when things feel noisy.',
        body: _ChoiceList<InnerAnchorFocus>(
          options: const [
            (InnerAnchorFocus.bodyBreath, 'Body & breath awareness'),
            (InnerAnchorFocus.mindHeart, 'Mind & heart coherence'),
            (
              InnerAnchorFocus.ancestorsLineage,
              'Ancestors & lineage reverence'
            ),
            (InnerAnchorFocus.creativityVoice, 'Creative expression & voice'),
            (InnerAnchorFocus.sacredAction, 'Sacred action & service'),
          ],
          selected: _innerAnchor,
          onSelected: (value) => setState(() => _innerAnchor = value),
        ),
      );

  _OnboardingStep _buildClimateStep() => _OnboardingStep(
        title: 'How are you feeling in this moment of history?',
        description:
            'I’ll calibrate tone and practices based on how your nervous system feels.',
        body: _ChoiceList<ClimateFeeling>(
          options: const [
            (ClimateFeeling.grounded, 'Grounded & awake'),
            (ClimateFeeling.concerned, 'Concerned about the moment'),
            (ClimateFeeling.overwhelmed, 'Carrying overwhelm'),
            (ClimateFeeling.grieving, 'Moving through grief'),
            (ClimateFeeling.hopefulButTired, 'Hopeful yet tired'),
          ],
          selected: _climateFeeling,
          onSelected: (value) => setState(() => _climateFeeling = value),
        ),
      );

  _OnboardingStep _buildJusticeStep() => _OnboardingStep(
        title: 'Where do you sense tension around justice & power?',
        description:
            'Choose the spaces where you want clarity, support, or insight.',
        body: _MultiChoiceChips<JusticeTension>(
          options: const [
            (JusticeTension.personal, 'Personal wellbeing & safety'),
            (JusticeTension.familyCommunity, 'Family & community spaces'),
            (JusticeTension.workplace, 'Workplace or industry'),
            (JusticeTension.nationalGlobal, 'National or global shifts'),
            (
              JusticeTension.spiritualInstitutions,
              'Spiritual or religious institutions',
            ),
            (JusticeTension.unsure, 'I’m still discerning'),
          ],
          selected: _justiceTensions,
          onChanged: (value) => setState(() {
            if (_justiceTensions.contains(value)) {
              _justiceTensions.remove(value);
            } else {
              _justiceTensions.add(value);
            }
          }),
        ),
      );

  _OnboardingStep _buildProtectionStep() => _OnboardingStep(
        title: 'What do you want spiritual protection or peace from?',
        description:
            'I’ll shape prayers, rituals, and reflections around what you name here.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MultiChoiceChips<ProtectionFocus>(
              options: const [
                (ProtectionFocus.racialTrauma, 'Racialized trauma'),
                (ProtectionFocus.politicalTurmoil, 'Political turmoil'),
                (ProtectionFocus.violenceInNews, 'Violence in the news'),
                (ProtectionFocus.helplessness, 'Feelings of helplessness'),
                (ProtectionFocus.other, 'Something else'),
              ],
              selected: _protectionFocus,
              onChanged: (value) => setState(() {
                if (_protectionFocus.contains(value)) {
                  _protectionFocus.remove(value);
                  if (value == ProtectionFocus.other) {
                    _protectionOther = null;
                    _protectionOtherController.clear();
                  }
                } else {
                  _protectionFocus.add(value);
                }
              }),
            ),
            if (_protectionFocus.contains(ProtectionFocus.other)) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _protectionOtherController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Name the situation or energy',
                ),
                onChanged: (value) => setState(() {
                  _protectionOther = value;
                }),
              ),
            ],
          ],
        ),
      );

  _OnboardingStep _buildSolidarityStep() => _OnboardingStep(
        title: 'How do you practice solidarity or sacred resistance?',
        description:
            'This helps me suggest rituals that nourish your collective work.',
        body: _MultiChoiceChips<SolidarityPractice>(
          options: const [
            (SolidarityPractice.communityOrganizing, 'Community organizing'),
            (SolidarityPractice.prayerOrRitual, 'Prayer, ritual, ceremony'),
            (SolidarityPractice.teachingEducating, 'Teaching & educating'),
            (
              SolidarityPractice.financialSupport,
              'Financial support & mutual aid',
            ),
            (SolidarityPractice.storytellingArt, 'Storytelling, art, or media'),
            (
              SolidarityPractice.seekingGuidance,
              'Seeking guidance on where to begin'
            ),
          ],
          selected: _solidarityPractices,
          onChanged: (value) => setState(() {
            if (_solidarityPractices.contains(value)) {
              _solidarityPractices.remove(value);
            } else {
              _solidarityPractices.add(value);
            }
          }),
        ),
      );

  _OnboardingStep _buildTruthStep() => _OnboardingStep(
        title: 'Name a truth you’re holding about the world changing.',
        description:
            'Speak a sentence or two. I’ll weave it into affirmations and reflections.',
        body: TextField(
          controller: _truthController,
          maxLength: 240,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:
                'For example: “Liberation is inevitable when we remember who we are.”',
          ),
          onChanged: (value) => setState(() {
            _collectiveTruth = value;
          }),
        ),
      );

  _OnboardingStep _buildReminderStep() => _OnboardingStep(
        title: 'When should I whisper a reminder?',
        description: 'Choose the rhythm that keeps you supported.',
        body: _ChoiceList<ReminderSlot>(
          options: const [
            (ReminderSlot.morning, 'Sunrise centering'),
            (ReminderSlot.midday, 'Midday reset'),
            (ReminderSlot.evening, 'Twilight wind-down'),
            (ReminderSlot.gentle, 'Only if I slip the rhythm'),
          ],
          selected: _reminderSlot,
          onSelected: (value) => setState(() => _reminderSlot = value),
        ),
      );

  _OnboardingStep _buildStreakStep() => _OnboardingStep(
        title: 'How should streaks feel?',
        description:
            'Choose whether you want celebratory streak energy or a gentle, private rhythm.',
        body: _ChoiceList<bool>(
          options: const [
            (true, 'Celebrate my streaks'),
            (false, 'Keep it gentle and private'),
          ],
          selected: _wantsStreaks,
          onSelected: (value) => setState(() => _wantsStreaks = value),
        ),
      );

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
                          intention: IntentionFocus.dailySpark,
                          guidanceStyles: const [
                            GuidanceStyle.scripturePassages,
                          ],
                          innerAnchor: InnerAnchorFocus.bodyBreath,
                          reminderSlot: ReminderSlot.morning,
                          wantsStreaks: true,
                          climateFeeling: ClimateFeeling.grounded,
                          justiceTensions: const [],
                          protectionFocus: const [],
                          solidarityPractices: const [],
                          collectiveTruth: 'Transformation starts within me.',
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                  ? AppColors.maatGold.withOpacity(0.15)
                  : AppColors.onyx.withOpacity(0.45),
              border: Border.all(
                color: isSelected
                    ? AppColors.maatGold
                    : AppColors.maatGold.withOpacity(0.2),
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
                    color: AppColors.maatGold,
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
    final theme = Theme.of(context);
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
          selectedColor: AppColors.maatGold.withOpacity(0.25),
          backgroundColor: AppColors.onyx.withOpacity(0.35),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}
