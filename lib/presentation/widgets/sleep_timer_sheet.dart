import 'package:flutter/material.dart';

import '../../core/audio/sleep_timer.dart';
import '../../core/di/injector.dart';
import '../../core/utils/format_utils.dart';

Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => const _SleepTimerSheet(),
  );
}

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet();

  static const _presets = [5, 10, 15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final timer = getIt<SleepTimer>();

    return SafeArea(
      child: StreamBuilder<Duration?>(
        stream: timer.remainingStream,
        builder: (context, snapshot) {
          final remaining = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sleep timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (remaining != null) ...[
                Text(formatDuration(remaining), style: Theme.of(context).textTheme.headlineMedium),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => timer.extend(const Duration(minutes: 5)),
                        child: const Text('+5 min'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          timer.cancel();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel timer'),
                      ),
                    ],
                  ),
                ),
              ] else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    for (final minutes in _presets)
                      ActionChip(
                        label: Text('${minutes}m'),
                        onPressed: () {
                          timer.start(Duration(minutes: minutes));
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
