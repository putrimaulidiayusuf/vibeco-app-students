import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AkuPrabaVideoPlayer extends StatefulWidget {
  final double width;
  final double height;
  const AkuPrabaVideoPlayer({super.key, this.width = 280, this.height = 280});

  @override
  State<AkuPrabaVideoPlayer> createState() => _AkuPrabaVideoPlayerState();
}

class _AkuPrabaVideoPlayerState extends State<AkuPrabaVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/aku_praba.mp4',
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
      width: widget.width,
      height: widget.height,
      child: _initialized
          ? FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          : Image.asset(
              'assets/images/maskothello.png',
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
            ),
    );
  }
}
