import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:video_player/video_player.dart';

import 'package:discuzq/models/threadVideoModel.dart';
import 'package:discuzq/widgets/player/discuzPlayerAppbar.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/states/appState.dart';
import 'package:discuzq/states/scopedState.dart';
import 'package:discuzq/widgets/threads/payments/threadRequiredPayments.dart';
import 'package:discuzq/widgets/common/discuzCachedNetworkImage.dart';
import 'package:discuzq/widgets/common/discuzIndicater.dart';
import 'package:discuzq/widgets/common/discuzNetworkError.dart';
import 'package:discuzq/api/videoAPI.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/common/discuzText.dart';


class DiscuzPlayer extends StatefulWidget {
  ///
  /// 关联的视频模型
  final ThreadVideoModel video;

  final ThreadModel thread;

  const DiscuzPlayer({@required this.video, @required this.thread});

  @override
  _DiscuzPlayerState createState() => _DiscuzPlayerState();
}

class _DiscuzPlayerState extends State<DiscuzPlayer> {
  /// states
  ///
  VideoPlayerController _controller;

  ///
  /// 是否正在加载视频信息
  bool _loading = true;

  ///
  /// 云点播视频信息
  ///
  dynamic _playerInfo;

  ///
  /// 是否需要支付才能播放
  bool get _requiredPaymentToPlay => widget.thread.attributes.paid ||
          double.tryParse(widget.thread.attributes.price) == 0
      ? false
      : true;

  /// 转码后的Uri
  String get _transcodeUrl => _playerInfo['videoInfo'] == null
      ? null
      : _playerInfo['videoInfo']['transcodeList'].length > 0
          ? _playerInfo['videoInfo']['transcodeList'][0]['url']
          : null;

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 1000)).then((_) => _init());
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ScopedStateModelDescendant<AppState>(
        rebuildOnChange: false,
        builder: (context, child, state) => Material(
              color: Colors.black,
              child: Stack(
                children: <Widget>[
                  ///
                  /// 是否需要支付才能查看
                  _requiredPaymentToPlay
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              height: 200,
                              child: ThreadRequiredPayments(
                                thread: widget.thread,
                              ),
                            ),
                          ),
                        )
                      : _buildPlayer(),

                  DiscuzPlayerAppbar(
                    onClose: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ));
  }

  ///
  /// 初始化播放
  ///
  Future<void> _init() async {
    try {
      ///
      /// 加载视频源信息
      final bool result = await _getPlayInfo();
      if (!result) {
        setState(() {
          _loading = false;
        });
        return;
      }

      if (_transcodeUrl == null) {
        return;
      }

      if(!mounted){
        return;
      }

      _controller = VideoPlayerController.network(_transcodeUrl)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {
            _loading = false;
          });
          _controller.play();
          _controller.setLooping(true);
        });
    } catch (e) {
      throw e;
    }
  }

  ///
  /// 获取播放视频信息
  ///
  Future<bool> _getPlayInfo() async {
    try {
      final AppState state =
          ScopedStateModel.of<AppState>(context, rebuildOnChange: false);

      final dynamic playInfo = await VideoAPI(context: context).getPlayInfo(
          qcloud: state.forum.attributes.qcloud, video: widget.video);

      if (playInfo == null) {
        return Future.value(false);
      }

      _playerInfo = playInfo;

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  }

  ///
  /// 创建播放器
  /// 处理视频加载中等过程
  Widget _buildPlayer() {
    if (!_loading && _playerInfo == null) {
      return Center(
        child: DiscuzNetworkError(
          label: '加载失败，请重试',
          onRequestRefresh: () {
            setState(() {
              _loading = true;
            });
            _init();
          },
        ),
      );
    }

    if (!_loading && _playerInfo != null && _transcodeUrl == null) {
      return Center(
        child: const DiscuzText('转码中，请稍后观看'),
      );
    }

    if (_loading || _controller == null) {
      return Stack(
        children: <Widget>[
          Center(
            child: DiscuzCachedNetworkImage(
              imageUrl: widget.video.attributes.coverUrl,
            ),
          ),
          const Center(
            child: const DiscuzIndicator(
              brightness: Brightness.dark,
              scale: 3,
            ),
          ),
        ],
      );
    }

    return _controller.value.initialized
        ? Stack(alignment: Alignment.bottomCenter, children: <Widget>[
            Center(
                child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller))),
            Stack(
              children: <Widget>[
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 50),
                  reverseDuration: Duration(milliseconds: 200),
                  child: _controller.value.isPlaying
                      ? const SizedBox()
                      : Container(
                          color: Colors.black26,
                          child: Center(
                            child: const DiscuzIcon(
                              SFSymbols.play_fill,
                              color: Colors.white,
                              size: 60.0,
                            ),
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  },
                ),
              ],
            ),
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                  backgroundColor: Colors.black12,
                  playedColor: DiscuzApp.themeOf(context).primaryColor),
              padding: const EdgeInsets.all(0),
            )
          ])
        : Center(
            child: DiscuzCachedNetworkImage(
              imageUrl: widget.video.attributes.coverUrl,
            ),
          );
  }
}
