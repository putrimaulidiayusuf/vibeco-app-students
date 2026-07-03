import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaskotBanggaVideoPlayer extends StatefulWidget {
  final double size;
  const MaskotBanggaVideoPlayer({super.key, this.size = 90});

  @override
  State<MaskotBanggaVideoPlayer> createState() => _MaskotBanggaVideoPlayerState();
}

class _MaskotBanggaVideoPlayerState extends State<MaskotBanggaVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/maskot_bangga_video.mp4',
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
          _controller.setVolume(0.0);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: _initialized
            ? FittedBox(
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.4),
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : Container(color: Colors.transparent),
      ),
    );
  }
}
