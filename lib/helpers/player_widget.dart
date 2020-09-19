import "dart:async";

import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:ressuscitou/helpers/global.dart";
import 'package:ressuscitou/model/canto.dart';

enum PlayerState { stopped, playing, paused }
enum PlayingRouteState { speakers, earpiece }

class PlayerWidget extends StatefulWidget {
  final String url;
  final Canto canto;
  final PlayerMode mode;

  PlayerWidget({Key key, @required this.url, this.canto, this.mode = PlayerMode.MEDIA_PLAYER}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PlayerWidgetState(url, mode);
  }
}

class PlayerWidgetState extends State<PlayerWidget> {
  String url;
  PlayerMode mode;

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

  get _isPaused => _playerState == PlayerState.paused;

  get _durationText => _duration?.toString()?.split(".")?.first ?? "";

  get _positionText => _position?.toString()?.split(".")?.first ?? "";

  PlayerWidgetState(this.url, this.mode);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
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
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (!_isPlaying)
              IconButton(
                key: Key("play_button"),
                onPressed: _isPlaying ? null : () => _play(),
                iconSize: 40,
                icon: Icon(Icons.play_arrow),
                color: globals.darkRed,
              ),
            if (_isPlaying)
              IconButton(
                key: Key("pause_button"),
                onPressed: _isPlaying ? () => _pause() : null,
                iconSize: 40,
                icon: Icon(Icons.pause),
                color: globals.darkRed,
              ),
            //if (_isPlaying || _isPaused)
            Expanded(
              child: Stack(
                children: <Widget>[
                  Slider(
                    activeColor: globals.darkRed,
                    inactiveColor: Colors.grey,
                    onChanged: (v) {
                      if (v < 1) {
                        final position = v * _duration.inMilliseconds;
                        _audioPlayer.seek(Duration(milliseconds: position.round()));
                      }
//                      else
//                        _audioPlayer.seek(Duration(milliseconds: _duration.inMilliseconds));
                    },
                    value: (_position != null &&
                            _duration != null &&
                            _position.inMilliseconds > 0 &&
                            _position.inMilliseconds < _duration.inMilliseconds)
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                  ),
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

            IconButton(
              key: Key("stop_button"),
              onPressed: _isPlaying || _isPaused ? () => _stop() : null,
              iconSize: 40,
              icon: Icon(Icons.stop),
              color: globals.darkRed,
            ),
          ],
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);

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
      setState(() {
      });
    });

    _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (!mounted) return;
    });

  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result = await _audioPlayer.play(url, position: playPosition);
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
  }
}
