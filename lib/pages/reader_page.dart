import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../providers/library_provider.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.bookId});

  final String bookId;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _scrollController = ScrollController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    final progress = max <= 0 ? 1.0 : (position.pixels / max).clamp(0.0, 1.0);
    if (progress != _progress) {
      setState(() => _progress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    final book = context.watch<LibraryProvider>().bookById(widget.bookId);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('阅读')),
        body: Center(
          child: Text('书籍不存在或已删除', style: TextStyle(color: palette.fgDark)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SelectableText(
                      book.content,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.9,
                        color: palette.fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _ReaderProgress(progress: _progress),
        ],
      ),
    );
  }
}

class _ReaderProgress extends StatelessWidget {
  const _ReaderProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: palette.bgDark,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: palette.bgHighlight,
                color: palette.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              '${(progress * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: palette.fgDark),
            ),
          ),
        ],
      ),
    );
  }
}
