import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';

class ManualMoreColorsPage extends StatelessWidget {
  const ManualMoreColorsPage({super.key, required this.initialColor});

  final String? initialColor;

  static const List<String> palette = <String>[
    '#FFE6EA',
    '#FFD8B8',
    '#FFF4CC',
    '#E5F7EA',
    '#CDEFE9',
    '#E5F1FF',
    '#D3E4FF',
    '#F1E7FF',
    '#EFD9FF',
    '#F5EDE2',
    '#FFDDE5',
    '#D8F6D9',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        title: const Text('更多颜色'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: palette.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (BuildContext context, int index) {
          final String colorHex = palette[index];
          final bool selected = colorHex == initialColor;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(colorHex),
            child: Container(
              decoration: BoxDecoration(
                color: Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: selected ? 2 : 1,
                  color: selected ? const Color(0xFFD89B00) : const Color(0xFFE8DFD2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
