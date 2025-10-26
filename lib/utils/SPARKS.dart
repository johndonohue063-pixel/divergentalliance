class GatewayPin {
  static const String pin = '8883';

  static Future<void> ensureInitialized() async {
    // placeholder for future secure storage, no work needed now
  }

  static Future<bool> verify(String value) async {
    return value.trim() == pin;
  }
}
