class PremiumState {
  const PremiumState({
    required this.isPremium,
    required this.source,
    required this.expiresAt,
    required this.isTrial,
    required this.trialEndsAt,
    required this.isLoading,
    this.errorMessage,
  });

  final bool isPremium;
  final String? source;
  final DateTime? expiresAt;
  final bool isTrial;
  final DateTime? trialEndsAt;
  final bool isLoading;
  final String? errorMessage;

  factory PremiumState.initial() => const PremiumState(
        isPremium: false,
        source: null,
        expiresAt: null,
        isTrial: false,
        trialEndsAt: null,
        isLoading: false,
      );

  PremiumState copyWith({
    bool? isPremium,
    String? source,
    DateTime? expiresAt,
    bool? isTrial,
    DateTime? trialEndsAt,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      source: source ?? this.source,
      expiresAt: expiresAt ?? this.expiresAt,
      isTrial: isTrial ?? this.isTrial,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
