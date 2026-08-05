import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../models/book_content.dart';
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
  BookContent? _content;
  bool _contentLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
    _loadContent();
  }

  Future<void> _loadContent() async {
    final content = await context.read<LibraryProvider>().readBookContent(
      widget.bookId,
    );
    if (!mounted) return;
    setState(() {
      _content = content;
      _contentLoading = false;
    });
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
    final metadata = context.watch<LibraryProvider>().bookById(widget.bookId);

    if (metadata == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('阅读')),
        body: Center(
          child: Text('书籍不存在或已删除', style: TextStyle(color: palette.fgDark)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          metadata.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(palette)),
          _ReaderProgress(progress: _progress),
        ],
      ),
    );
  }

  Widget _buildBody(TokyoPalette palette) {
    if (_contentLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final content = _content;
    if (content == null) {
      return Center(
        child: Text('书籍内容读取失败', style: TextStyle(color: palette.fgDark)),
      );
    }
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SelectableText(
              key: const ValueKey('reader_content'),
              content.text,
              style: TextStyle(fontSize: 17, height: 1.9, color: palette.fg),
            ),
          ),
        ),
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
              key: const ValueKey('reader_progress'),
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
