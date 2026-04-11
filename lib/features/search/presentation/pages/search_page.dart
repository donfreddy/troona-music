import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/search/presentation/bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Titres, artistes, albums...',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.white30),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white30),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchBloc>().add(SearchClearRequested());
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: .05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: (val) {
            context.read<SearchBloc>().add(SearchTextChanged(val));
            setState(() {});
          },
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchLoaded) {
            final result = state.result;
            if (result.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(color: Colors.white30),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (result.artists.isNotEmpty) ...[
                  const _SearchSectionHeader(title: 'Artistes'),
                  ...result.artists.map(
                    (a) => ListTile(
                      onTap: () => context.pushNamed(
                        AppRoute.artistDetail,
                        pathParameters: {'id': a.id.toString()},
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: const Icon(LucideIcons.user, size: 20),
                      ),
                      title: Text(a.name),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (result.albums.isNotEmpty) ...[
                  const _SearchSectionHeader(title: 'Albums'),
                  ...result.albums.map(
                    (a) => ListTile(
                      onTap: () => context.pushNamed(
                        AppRoute.albumDetail,
                        pathParameters: {'id': a.id.toString()},
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(LucideIcons.disc, size: 20),
                      ),
                      title: Text(a.name),
                      subtitle: Text(
                        a.artist,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (result.tracks.isNotEmpty) ...[
                  const _SearchSectionHeader(title: 'Morceaux'),
                  ...result.tracks.map(
                    (t) => ListTile(
                      onTap: () {
                        //context.read<PlayerBloc>().add(PlayerPlaylistRequested(playlist: [t], initialIndex: 0));
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(LucideIcons.music, size: 20),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        t.artist,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 120),
              ],
            );
          }

          if (state is SearchInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.search, size: 64, color: Colors.white10),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Cherchez vos musiques préférées',
                    style: TextStyle(color: Colors.white24),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  final String title;
  const _SearchSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purpleAccent,
        ),
      ),
    );
  }
}
