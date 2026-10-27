import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/audio_player_handler.dart';
import '../../../core/di/injector.dart';
import '../../../data/datasources/local/eq_local_datasource.dart';
import '../../bloc/settings/settings_cubit.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final _equalizer = getIt<AudioPlayerHandler>().equalizer;
  final _eqLocal = getIt<EqLocalDataSource>();
  AndroidEqualizerParameters? _params;
  List<EqPresetRow> _presets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final params = await _equalizer.parameters;
    final presets = await _eqLocal.getPresets();
    if (!mounted) return;
    setState(() {
      _params = params;
      _presets = presets;
    });
  }

  Future<void> _applyPreset(EqPresetRow preset) async {
    final params = _params;
    if (params == null) return;
    for (var i = 0; i < params.bands.length && i < preset.bandValues.length; i++) {
      await params.bands[i].setGain(preset.bandValues[i].toDouble());
    }
    setState(() {});
  }

  Future<void> _saveAsPreset() async {
    final params = _params;
    if (params == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save preset'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Preset name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _eqLocal.savePreset(name, params.bands.map((b) => b.gain.round()).toList());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final params = _params;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          IconButton(icon: const Icon(Icons.save_rounded), onPressed: _saveAsPreset),
        ],
      ),
      body: params == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable equalizer'),
                  value: settings.state.eqEnabled,
                  onChanged: settings.setEqEnabled,
                ),
                if (_presets.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final preset in _presets)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(preset.name),
                              onPressed: () => _applyPreset(preset),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final band in params.bands)
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: StreamBuilder<double>(
                                  stream: band.gainStream,
                                  initialData: band.gain,
                                  builder: (context, snapshot) {
                                    return RotatedBox(
                                      quarterTurns: 3,
                                      child: Slider(
                                        min: params.minDecibels,
                                        max: params.maxDecibels,
                                        value: (snapshot.data ?? 0).clamp(params.minDecibels, params.maxDecibels),
                                        onChanged: band.setGain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Text('${band.centerFrequency >= 1000 ? '${(band.centerFrequency / 1000).round()}k' : band.centerFrequency.round()}Hz',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up_rounded),
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 150,
                              divisions: 30,
                              value: settings.state.volumeBoostPercent.toDouble(),
                              label: '${settings.state.volumeBoostPercent}%',
                              onChanged: (v) => settings.setVolumeBoost(v.round()),
                            ),
                          ),
                          Text('${settings.state.volumeBoostPercent}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
