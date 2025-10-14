class PaywallRequiredException implements Exception {
  PaywallRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}
