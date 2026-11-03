import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../helpers/global.dart';
import '../helpers/player_widget.dart';
import '../model/canto.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _controller = AudioPlaybackController();
  final _scrollController = ItemScrollController();
  late final List<Canto> _originalOrder;
  late final List<Canto> _queue;
  int _currentSong = 0;
  bool _busy = false;
  bool _shuffle = false;
  bool _repeat = false;

  @override
  void initState() {
    super.initState();
    _originalOrder = List.of(globals.listaGlobal);
    _queue = List.of(_originalOrder);
    _controller.onComplete = () async {
      if (_currentSong + 1 < _queue.length) {
        await _selectSong(_currentSong + 1);
      } else if (_repeat && _queue.isNotEmpty) {
        await _selectSong(0);
      }
    };
    if (_queue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectSong(0);
      });
    }
  }

  Future<void> _selectSong(int index) async {
    if (_busy || !mounted || index < 0 || index >= _queue.length) return;
    setState(() {
      _busy = true;
      _currentSong = index;
      for (var i = 0; i < _queue.length; i++) {
        _queue[i].playing = i == index;
      }
    });
    try {
      await _controller.stop();
      if (!mounted) return;
      await _controller.play(_queue[index].filePath);
      if (mounted && _scrollController.isAttached) {
        _scrollController.jumpTo(index: index);
      }
    } catch (error) {
      if (mounted) snackBar(context, 'Não foi possível reproduzir o áudio: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_queue.isEmpty || _busy) return;
    try {
      if (_controller.isPlaying) {
        await _controller.pause();
      } else {
        await _controller.play(_queue[_currentSong].filePath);
      }
    } catch (error) {
      if (mounted) snackBar(context, 'Erro no áudio: $error');
    }
  }

  void _toggleShuffle() {
    if (_queue.isEmpty) return;
    final current = _queue[_currentSong];
    setState(() {
      _shuffle = !_shuffle;
      _queue
        ..clear()
        ..addAll(_originalOrder);
      if (_shuffle) {
        _queue.remove(current);
        _queue.shuffle();
        _queue.insert(0, current);
      }
      _currentSong = _queue.indexOf(current);
    });
    if (_scrollController.isAttached) _scrollController.jumpTo(index: _currentSong);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final canto in _originalOrder) {
      canto.playing = false;
    }
    globals.listaGlobal = _originalOrder;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Lista de Reprodução')),
        body: _queue.isEmpty
            ? const Center(child: Text('Nenhum áudio na lista.'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Column(children: [
                    Text(_queue[_currentSong].titulo),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      IconButton(
                        tooltip: 'Anterior',
                        icon: const Icon(Icons.skip_previous),
                        onPressed: !_busy && _currentSong > 0
                            ? () => _selectSong(_currentSong - 1)
                            : null,
                      ),
                      IconButton(
                        tooltip: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
                        iconSize: 80,
                        icon: Icon(_controller.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: _busy ? null : _togglePlayback,
                      ),
                      IconButton(
                        tooltip: 'Próxima',
                        icon: const Icon(Icons.skip_next),
                        onPressed: !_busy && _currentSong + 1 < _queue.length
                            ? () => _selectSong(_currentSong + 1)
                            : null,
                      ),
                    ]),
                    AudioProgress(controller: _controller),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      TextButton.icon(
                        icon: Icon(_shuffle ? Icons.shuffle_on : Icons.shuffle),
                        label: const Text('Aleatório'),
                        onPressed: _busy ? null : _toggleShuffle,
                      ),
                      TextButton.icon(
                        icon: Icon(_repeat ? Icons.repeat_on : Icons.repeat),
                        label: const Text('Repetir lista'),
                        onPressed: () => setState(() => _repeat = !_repeat),
                      ),
                    ]),
                    Expanded(
                      child: ScrollablePositionedList.separated(
                        itemScrollController: _scrollController,
                        itemCount: _queue.length,
                        separatorBuilder: (_, index) => const Divider(),
                        itemBuilder: (context, index) => ListTile(
                          title: Text(_queue[index].titulo),
                          selected: index == _currentSong,
                          onTap: _busy ? null : () => _selectSong(index),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
      );
}
