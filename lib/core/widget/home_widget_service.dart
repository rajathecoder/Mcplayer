import 'package:home_widget/home_widget.dart';

/// Pushes now-playing info to the native Android home-screen widget.
///
/// Android only: a real iOS widget needs a WidgetKit extension target created
/// in Xcode (its own Swift files + App Group entitlement), which can't be
/// scaffolded from here, so iOS support is not implemented.
class HomeWidgetService {
  static const _androidProviderName = 'McPlayerWidgetProvider';

  Future<void> update({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    await HomeWidget.saveWidgetData<String>('title', title);
    await HomeWidget.saveWidgetData<String>('artist', artist);
    await HomeWidget.saveWidgetData<bool>('isPlaying', isPlaying);
    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }

  Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>('title', 'MC Player');
    await HomeWidget.saveWidgetData<String>('artist', 'Tap Play All in the app to start');
    await HomeWidget.saveWidgetData<bool>('isPlaying', false);
    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }
}
