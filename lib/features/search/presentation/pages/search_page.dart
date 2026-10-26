import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/search/presentation/bloc/search_bloc.dart';
import 'package:troona/features/search/presentation/widgets/search_results_view.dart';
import 'package:troona/features/search/presentation/widgets/search_suggestions.dart';
import 'package:troona/shared/widgets/error_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClear() {
    AppHaptics.lightImpact();
    _controller.clear();
    context.read<SearchBloc>().add(SearchClearRequested());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Search Bar Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textInputAction: TextInputAction.search,
                  cursorColor: colors.accent,
                  decoration: InputDecoration(
                    hintText: 'Artistes, albums, morceaux...',
                    hintStyle: TextStyle(
                      color: colors.labelTertiary,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: _controller.text.isNotEmpty
                          ? colors.accent
                          : colors.labelSecondary,
                      size: 20,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onClear,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Icon(
                                LucideIcons.circleX,
                                color: colors.labelTertiary,
                                size: 18,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: .08),
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: .08),
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colors.accent.withValues(alpha: .4),
                        width: 1.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onChanged: (val) {
                    context.read<SearchBloc>().add(SearchTextChanged(val));
                    setState(() {});
                  },
                ),
              ),
            ),

            // ── Search Content / States ───────────────────────────────────
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.accent,
                        ),
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (state is SearchLoaded) {
                    return SearchResultsView(
                      result: state.result,
                      query: state.query,
                    );
                  }

                  if (state is SearchError) {
                    return Center(
                      child: ErrorView(
                        message: state.message,
                        onRetry: () {
                          if (_controller.text.isNotEmpty) {
                            context.read<SearchBloc>().add(
                              SearchTextChanged(_controller.text),
                            );
                          }
                        },
                      ),
                    );
                  }

                  // SearchInitial / Query empty
                  return SearchSuggestions(
                    onQuerySelected: (query) {
                      _controller.text = query;
                      context.read<SearchBloc>().add(SearchTextChanged(query));
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
