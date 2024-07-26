import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final List<String> videoUrls = [
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ];

  int _currentIndex = 1;
  late VideoPlayerItem _videoPlayerItem;

  @override
  void initState() {
    super.initState();
    _videoPlayerItem = VideoPlayerItem(url: videoUrls[_currentIndex]);
  }

  void _onVideoIndexChanged(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
      _videoPlayerItem = VideoPlayerItem(url: videoUrls[_currentIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        extendBodyBehindAppBar: true,
        drawer: Drawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://static.vecteezy.com/system/resources/previews/002/002/403/non_2x/man-with-beard-avatar-character-isolated-icon-free-vector.jpg",
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: _videoPlayerItem,
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.keyboard_arrow_left),
                            onPressed: _currentIndex > 0
                                ? () {
                                    _onVideoIndexChanged(_currentIndex - 1);
                                  }
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _downloadVideo(videoUrls[_currentIndex]);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.green,
                                ),
                                Text('Download'),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.keyboard_arrow_right),
                            onPressed: _currentIndex < videoUrls.length - 1
                                ? () {
                                    _onVideoIndexChanged(_currentIndex + 1);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadVideo(String url) async {
    Dio dio = Dio();
    try {
      var dir = await getApplicationDocumentsDirectory();
      String fileName = url.split('=').last + '.mp4';
      String filePath = '${dir.path}/$fileName';
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print((received / total * 100).toStringAsFixed(0) + "%");
          }
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download completed")),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed")),
      );
    }
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String url;

  VideoPlayerItem({required this.url});

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();

  void rewind() {
    _VideoPlayerItemState? state = _VideoPlayerItemState();
    state._rewind();
  }

  void fastForward() {
    _VideoPlayerItemState? state = _VideoPlayerItemState();
    state._fastForward();
  }
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  late String _localFilePath;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    var dir = await getApplicationDocumentsDirectory();
    String fileName = widget.url.split('=').last + '.mp4';
    _localFilePath = '${dir.path}/$fileName';
    bool fileExists = await File(_localFilePath).exists();

    if (fileExists) {
      _controller = VideoPlayerController.file(File(_localFilePath));
    } else {
      _controller = VideoPlayerController.network(widget.url);
    }

    _controller.addListener(() {
      if (_controller.value.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Playback error: ${_controller.value.errorDescription}")),
        );
      }
    });

    await _controller.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: false,
      looping: false,
      allowedScreenSleep: false,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  void _rewind() {
    if (_controller.value.isInitialized) {
      final newPosition = _controller.value.position - Duration(seconds: 10);
      _controller
          .seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
    }
  }

  void _fastForward() {
    if (_controller.value.isInitialized) {
      final newPosition = _controller.value.position + Duration(seconds: 10);
      final maxPosition = _controller.value.duration;
      _controller.seekTo(newPosition < maxPosition ? newPosition : maxPosition);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Chewie(controller: _chewieController),
          )
        : Center(child: CircularProgressIndicator());
  }
}
