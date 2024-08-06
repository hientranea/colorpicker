import 'package:flutter/material.dart';

class FooterGuide extends StatelessWidget {
  const FooterGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.keyboard_command_key, size: 16),
          Text('+'),
          Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Text('to save current color'),
        ],
      ),
    );
  }
}