// FixMate — online/offline banner wrapper
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWrapper
    extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState
    extends State<ConnectivityWrapper> {
  StreamSubscription<
          List<ConnectivityResult>>?
      subscription;
  Timer? onlineTimer;

  bool isOffline = false;
  bool showOnline = false;

  @override
  void initState() {
    super.initState();

    _checkConnectivity();

    subscription =
        Connectivity().onConnectivityChanged.listen(
      (results) {
        final nextIsOffline = results.isEmpty ||
            results.every(
              (result) =>
                  result == ConnectivityResult.none,
            );

        setState(() {
          if (nextIsOffline) {
            onlineTimer?.cancel();
            showOnline = false;
          } else if (isOffline) {
            showOnline = true;
            onlineTimer?.cancel();
            onlineTimer = Timer(
              const Duration(seconds: 3),
              () {
                if (mounted) {
                  setState(() => showOnline = false);
                }
              },
            );
          }
          isOffline = nextIsOffline;
        });
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final results =
        await Connectivity().checkConnectivity();

    if (!mounted) return;

    setState(() {
      isOffline = results.isEmpty ||
          results.every(
            (result) =>
                result ==
                ConnectivityResult.none,
          );
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    onlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        Positioned(
          left: 0,
          right: 0,
          top: 12,
          child: Center(
            child: IgnorePointer(
              child: isOffline
                  ? const OfflineBanner()
                  : showOnline
                      ? const OnlineBanner()
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}


class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController blinkController;

  @override
  void initState() {
    super.initState();
    blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      lowerBound: 0.2,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: blinkController,
      child: const _ConnectivityIcon(
        color: Colors.red,
        icon: Icons.wifi_off,
      ),
    );
  }
}


class OnlineBanner extends StatelessWidget {
  const OnlineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ConnectivityIcon(
      color: Colors.green,
      icon: Icons.wifi,
    );
  }
}

class _ConnectivityIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ConnectivityIcon({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
