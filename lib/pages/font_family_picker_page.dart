import 'package:flutter/material.dart';

import '../widgets/adwaita_components.dart';

class FontFamilyPickerPage extends StatefulWidget {
  const FontFamilyPickerPage({
    required this.title,
    required this.loadFamilies,
    super.key,
  });

  final String title;
  final Future<List<String>> Function() loadFamilies;

  @override
  State<FontFamilyPickerPage> createState() => _FontFamilyPickerPageState();
}

class _FontFamilyPickerPageState extends State<FontFamilyPickerPage> {
  late final TextEditingController _searchController;
  late final Future<List<String>> _families;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _families = widget.loadFamilies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderBar(title: widget.title, showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const ValueKey('font_family_search'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索字体',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _query = value.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _families,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('字体列表加载失败'));
                }
                final families = snapshot.data ?? const [];
                final filtered = _query.isEmpty
                    ? families
                    : families
                          .where(
                            (family) => family.toLowerCase().contains(_query),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('没有匹配的字体'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final family = filtered[index];
                    return ListTile(
                      title: Text(family),
                      onTap: () => Navigator.of(context).pop(family),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
