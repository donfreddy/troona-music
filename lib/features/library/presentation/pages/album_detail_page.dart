import 'package:flutter/material.dart';

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Album Detail Page'),
      ),
    );
  }
}