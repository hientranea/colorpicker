import 'package:flutter/material.dart';

class FooterGuide extends StatelessWidget {
  final String hotkey;

  const FooterGuide({Key? key, required this.hotkey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...hotkey.split('+').map((key) => Text(key.trim())).expand(
                (widget) => [widget, const Text('+')],
          ).toList()
            ..removeLast(),
          const SizedBox(width: 8),
          const Text('to save current color'),
        ],
      ),
    );
  }
}