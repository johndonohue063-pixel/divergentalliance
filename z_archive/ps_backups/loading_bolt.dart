import 'package:flutter/material.dart';

class LoadingBolt {
  static bool _isShowing = false;
  static BuildContext? _ctx;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (c) {
        _ctx = c;
        return const _BoltDialog();
      },
    );
  }

  static void hide() {
    if (!_isShowing) return;
    _isShowing = false;
    if (_ctx != null) {
      Navigator.of(_ctx!, rootNavigator: true).pop();
      _ctx = null;
    }
  }
}

class _BoltDialog extends StatefulWidget {
  const _BoltDialog();

  @override
  State<_BoltDialog> createState() => _BoltDialogState();
}

class _BoltDialogState extends State<_BoltDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFF38B2B);
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: RotationTransition(
          turns: _c,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: brand.withOpacity(0.55),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.bolt, size: 96, color: brand),
          ),
        ),
      ),
    );
  }
}
