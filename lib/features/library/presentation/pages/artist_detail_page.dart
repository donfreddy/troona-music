import 'package:flutter/material.dart';

class ArtistDetailPage extends StatefulWidget {
  const ArtistDetailPage({super.key});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Artist Detail Page')));
  }
}
