import "dart:async";

import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import "../helpers/global.dart";
import '../model/canto.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

enum PlayerState { stopped, playing, paused }
enum PlayingRouteState { speakers, earpiece }

// ignore: must_be_immutable
class PlayerPage extends StatefulWidget {
  PlayerPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  int currentSong = 0;
  int beforeShufflePos = 0;
  String songTitle = "";
  bool processando = false;
  bool shuffle = false;
  bool shuffleNotifi = false;
  bool repeat = false;
  bool repeatNotifi = false;
  List<Canto> listaLocal = [];
  ItemScrollController itemScrollController = ItemScrollController();

  AudioPlayer _audioPlayer;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;

  get _durationText => _duration?.toString()?.split(".")?.first ?? "";

  get _positionText => _position?.toString()?.split(".")?.first ?? "";

  _PlayerPageState();

  @override
  void initState() {
    listaLocal.addAll(globals.listaGlobal);
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    globals.listaGlobal = [];
    globals.listaGlobal.addAll(listaLocal);
    _stop();
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0.0, centerTitle: false, title: Text("Lista de Reprodução")),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
//          Padding(
//            padding: EdgeInsets.all(8.0),
//            child: Text(
//              songTitle,
//              overflow: TextOverflow.ellipsis,
//            ),
//          ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: (currentSong == 0)
                      ? null
                      : () async {
                          if (!processando) {
                            processando = true;
                            currentSong--;
                            await _stop();
                            _initAudioPlayer();
                            setState(() {});
                          }
                        },
                  iconSize: 40,
                  icon: Icon(Icons.skip_previous),
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (!_isPlaying)
                  ClipOval(
                      child: Material(
                    color: Theme.of(context).colorScheme.secondary, // button color
                    child: IconButton(
                      key: Key("play_button"),
                      onPressed: _isPlaying ? null : () => _play(),
                      iconSize: 100,
                      icon: Icon(Icons.play_arrow),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )),
                if (_isPlaying)
                  ClipOval(
                      child: Material(
                    color: Theme.of(context).colorScheme.secondary, // button color
                    child: IconButton(
                      key: Key("pause_button"),
                      onPressed: _isPlaying ? () => _pause() : null,
                      iconSize: 100,
                      icon: Icon(Icons.pause),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )),
                IconButton(
                  onPressed: (currentSong == globals.listaGlobal.length - 1)
                      ? null
                      : () async {
                          if (!processando) {
                            processando = true;
                            currentSong++;
                            await _stop();
                            _initAudioPlayer();
                            setState(() {});
                          }
                        },
                  iconSize: 40,
                  icon: Icon(Icons.skip_next),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Stack(
                children: [
                  Slider(
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Colors.grey,
                    onChanged: (v) {
                      if (v < 1) {
                        final position = v * _duration.inMilliseconds;
                        _audioPlayer.seek(Duration(milliseconds: position.round()));
                      }
                    },
                    value: (_position != null &&
                            _duration != null &&
                            _position.inMilliseconds > 0 &&
                            _position.inMilliseconds < _duration.inMilliseconds)
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                  ),
                  if (_position != null)
                    Positioned(
                      top: 0,
                      left: 15,
                      child: Container(
                        height: 15,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _position != null ? "${_positionText ?? ""}" : "",
                              style: TextStyle(fontSize: 12.0),
                            )),
                      ),
                    ),
                  if (_duration != null)
                    Positioned(
                      bottom: 0,
                      right: 15,
                      child: Container(
                        height: 15,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _duration != null ? _durationText : "",
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                onPressed: globals.listaGlobal.length < 3
                    ? null
                    : () {
                        shuffle = !shuffle;
                        if (!shuffle) {
                          globals.listaGlobal = [];
                          globals.listaGlobal.addAll(listaLocal);
                        } else {
                          var cantoAtual = globals.listaGlobal.firstWhere((e) => e.playing);
                          currentSong = 0;
                          List<Canto> listaTemp = [];
                          listaTemp.addAll(listaLocal);
                          listaTemp.shuffle();
                          listaTemp.removeWhere((element) => element.id == cantoAtual.id);
                          globals.listaGlobal = [];
                          globals.listaGlobal.add(cantoAtual);
                          globals.listaGlobal.addAll(listaTemp);
                          shuffleNotifi = true;
                          Timer(
                              Duration(seconds: 2),
                              () => setState(() {
                                    shuffleNotifi = false;
                                  }));
                        }
                        setState(() {});
                        itemScrollController.jumpTo(index: globals.listaGlobal.indexWhere((e) => e.playing));
                      },
                icon: (shuffle) ? Icon(MdiIcons.shuffleVariant, size: 20) : Icon(MdiIcons.shuffleDisabled, size: 25),
                color: (shuffle) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onBackground,
              ),
              AnimatedOpacity(
                opacity: shuffleNotifi ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Text('Modo Aleatório'),
              ),
              AnimatedOpacity(
                opacity: repeatNotifi ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Text('Repetir Lista'),
              ),
              IconButton(
                onPressed: () {
                  repeat = !repeat;
                  if (repeat) {
                    repeatNotifi = true;
                    Timer(
                        Duration(seconds: 2),
                        () => setState(() {
                              repeatNotifi = false;
                            }));
                    setState(() {});
                  }
                },
                icon: (repeat) ? Icon(MdiIcons.repeat) : Icon(MdiIcons.repeatOff),
                color: (repeat) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onBackground,
              ),
            ]),
            Expanded(
              child: Container(
                child: ScrollablePositionedList.separated(
                    itemScrollController: itemScrollController,
                    separatorBuilder: (context, index) => Divider(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                    itemCount: globals.listaGlobal.length,
                    itemBuilder: (context, index) {
                      var listInd = globals.listaGlobal.length;
                      var _songTitle = globals.listaGlobal[index].titulo;
                      return InkWell(
                        onTap: () async {
                          if (!processando && (songTitle != _songTitle)) {
                            processando = true;
                            currentSong = index;
                            await _stop();
                            _initAudioPlayer();
                            setState(() {});
                          }
                        },
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(15, (index == 0) ? 15 : 5, 8, (index == listInd - 1) ? 15 : 5),
                            child: Text(
                              _songTitle,
                              style: (songTitle == _songTitle)
                                  ? TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                                  : null,
                            )),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initAudioPlayer() {
    globals.listaGlobal.forEach((e) {
      e.playing = (e.id == globals.listaGlobal[currentSong].id) ? true : false;
    });
    songTitle = globals.listaGlobal.firstWhere((e) => e.playing).titulo;
    _audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
          _position = p;
        }));

    _playerCompleteSubscription = _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {});
    });

    _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (!mounted) return;
    });
    _play();
    processando = false;
  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result =
        await _audioPlayer.play(globals.listaGlobal.firstWhere((e) => e.playing).filePath, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
    _audioPlayer.setPlaybackRate(playbackRate: 1.0);
    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration();
      });
    }
    return result;
  }

  void _onComplete() {
    _position = Duration();
    setState(() => _playerState = PlayerState.stopped);
    if (currentSong < globals.listaGlobal.length) currentSong++;
    if (currentSong == globals.listaGlobal.length && repeat) currentSong = 0;
    _initAudioPlayer();
    setState(() {});
  }
}
