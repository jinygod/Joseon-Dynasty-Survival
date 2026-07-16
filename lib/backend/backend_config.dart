class BackendConfig {
  const BackendConfig({required this.url, required this.publishableKey});

  const BackendConfig.disabled() : url = '', publishableKey = '';

  factory BackendConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (url.isEmpty || publishableKey.isEmpty) {
      return const BackendConfig.disabled();
    }
    return const BackendConfig(url: url, publishableKey: publishableKey);
  }

  final String url;
  final String publishableKey;

  bool get enabled => url.isNotEmpty && publishableKey.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendConfig &&
          url == other.url &&
          publishableKey == other.publishableKey;

  @override
  int get hashCode => Object.hash(url, publishableKey);
}
