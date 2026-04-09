import 'package:flutter/material.dart';

class ArtistDetailPage extends StatefulWidget {
  final String id;

  const ArtistDetailPage({super.key, required this.id});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text('Artist ID: ${widget.id}')),
    );
  }
}
