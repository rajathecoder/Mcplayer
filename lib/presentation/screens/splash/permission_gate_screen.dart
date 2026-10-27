import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/permission_manager.dart';
import '../main_nav_screen.dart';

class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> with WidgetsBindingObserver {
  final _permissionManager = getIt<PermissionManager>();
  LibraryPermissionStatus? _status;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final status = await _permissionManager.checkLibraryAccess();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _requestAccess() async {
    setState(() => _requesting = true);
    final status = await _permissionManager.requestLibraryAccess();
    if (!mounted) return;
    setState(() {
      _status = status;
      _requesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == LibraryPermissionStatus.granted) {
      return const MainNavScreen();
    }

    final permanentlyDenied = _status == LibraryPermissionStatus.permanentlyDenied;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_music_rounded, size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('MC Player', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Offline-first local music player',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        permanentlyDenied
                            ? 'Music access was denied. Please enable it from Settings to use MC Player.'
                            : 'MC Player needs access to your device storage to find and play your local music files. Everything stays on your device.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _requesting
                    ? null
                    : permanentlyDenied
                        ? () => _permissionManager.openSettings()
                        : _requestAccess,
                icon: _requesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(permanentlyDenied ? Icons.settings_rounded : Icons.lock_open_rounded),
                label: Text(permanentlyDenied ? 'Open Settings' : 'Grant Access'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
