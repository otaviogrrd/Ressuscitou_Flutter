import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../model/canto.dart';
import 'global.dart';

class AudioPlaybackController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  PlayerState state = PlayerState.stopped;
  Future<void> Function()? onComplete;
  String? _source;
  bool _disposed = false;

  AudioPlaybackController() {
    _subscriptions.addAll([
      _player.onDurationChanged.listen((value) {
        duration = value;
        _changed();
      }),
      _player.onPositionChanged.listen((value) {
        position = value;
        _changed();
      }),
      _player.onPlayerStateChanged.listen((value) {
        state = value;
        _changed();
      }),
      _player.onPlayerComplete.listen((_) {
        position = duration;
        _changed();
        if (!_disposed) onComplete?.call();
      }),
    ]);
  }

  bool get isPlaying => state == PlayerState.playing;
  double get progress => duration.inMilliseconds > 0
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0).toDouble()
      : 0.0;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> play(String path) async {
    if (_disposed) return;
    if (path.isEmpty) throw StateError('Arquivo de áudio indisponível.');
    if (_source == path && state == PlayerState.paused) {
      await _player.resume();
    } else {
      _source = path;
      final uri = Uri.tryParse(path);
      final source = uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
          ? UrlSource(path)
          : DeviceFileSource(path);
      await _player.play(source);
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    position = Duration.zero;
    _changed();
  }

  Future<void> seek(double value) => _player.seek(Duration(
      milliseconds: (duration.inMilliseconds * value.clamp(0.0, 1.0).toDouble()).round()));

  @override
  void dispose() {
    _disposed = true;
    onComplete = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}

class AudioProgress extends StatelessWidget {
  final AudioPlaybackController controller;
  const AudioProgress({super.key, required this.controller});

  String _time(Duration value) => value.toString().split('.').first;

  @override
  Widget build(BuildContext context) => Column(children: [
        Slider(
          value: controller.progress,
          onChanged: controller.duration > Duration.zero
              ? (value) async {
                  try {
                    await controller.seek(value);
                  } catch (error) {
                    if (context.mounted) snackBar(context, 'Erro no áudio: $error');
                  }
                }
              : null,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_time(controller.position)),
          Text(_time(controller.duration)),
        ]),
      ]);
}

class PlayerWidget extends StatefulWidget {
  final String url;
  final Canto? canto;
  const PlayerWidget({super.key, required this.url, this.canto});

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  final _controller = AudioPlaybackController();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) snackBar(context, 'Não foi possível reproduzir o áudio: $error');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(children: [
          IconButton(
            tooltip: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
            icon: Icon(_controller.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => _run(_controller.isPlaying
                ? _controller.pause
                : () => _controller.play(widget.url)),
          ),
          Expanded(child: AudioProgress(controller: _controller)),
          IconButton(
            tooltip: 'Parar',
            icon: const Icon(Icons.stop),
            onPressed: () => _run(_controller.stop),
          ),
        ]),
      );
}
