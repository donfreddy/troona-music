import 'package:flutter/material.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String id;

  const PlaylistDetailPage({super.key, required this.id});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text('Playlist ID: ${widget.id}')),
    );
  }
}
