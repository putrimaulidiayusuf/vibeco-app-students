import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaskotMarahVideoPlayer extends StatefulWidget {
  final double size;
  const MaskotMarahVideoPlayer({super.key, this.size = 200});

  @override
  State<MaskotMarahVideoPlayer> createState() => _MaskotMarahVideoPlayerState();
}

class _MaskotMarahVideoPlayerState extends State<MaskotMarahVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/maskot_marah_video.mp4',
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
          _controller.setVolume(0.0);
        }
      }).catchError((error) {
        debugPrint("Error initializing angry mascot video: $error");
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _initialized
            ? FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : Image.asset(
                'assets/images/maskot_marah.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
