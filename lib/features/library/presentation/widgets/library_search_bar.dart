import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/utils/debouncer.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/shared/widgets/glass_card.dart';

class LibrarySearchBar extends StatefulWidget {
  const LibrarySearchBar({super.key});

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      config: GlassTheme.card(context),
      child: TextField(
        controller: _controller,
        onChanged: (query) {
          _debouncer.run(() {
            context.read<LibraryBloc>().add(LibrarySearchChanged(query));
          });
        },
        decoration: InputDecoration(
          hintText: 'Titres, artistes, albums…',
          prefixIcon: const Icon(CupertinoIcons.search),
          suffixIcon: BlocBuilder<LibraryBloc, LibraryState>(
            // Ne rebuild que si on passe de vide à non-vide
            buildWhen: (prev, curr) =>
                (prev is LibraryLoaded ? prev.searchQuery.isNotEmpty : false) !=
                (curr is LibraryLoaded ? curr.searchQuery.isNotEmpty : false),
            builder: (_, state) {
              final hasQuery =
                  state is LibraryLoaded && state.searchQuery.isNotEmpty;
              if (!hasQuery) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill),
                onPressed: () {
                  _controller.clear();
                  context.read<LibraryBloc>().add(
                    const LibrarySearchChanged(''),
                  );
                },
              );
            },
          ),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
