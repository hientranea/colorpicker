import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/hotkey_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentHotkey = Constants.defaultHotKey;
  bool _isRecording = false;
  Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedHotkey();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadSavedHotkey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentHotkey = prefs.getString('hotkey') ?? Constants.defaultHotKey;
    });
  }

  void _saveHotkey(String hotkey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hotkey', hotkey);
    Provider.of<HotkeyProvider>(context, listen: false).updateHotkey(hotkey);
    const platform = MethodChannel('com.example.colorpicker/color_picker');
    await platform.invokeMethod('updateHotkey', hotkey);
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _pressedKeys.clear();
    });
    _focusNode.requestFocus();
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    if (_pressedKeys.isNotEmpty) {
      String newHotkey =
          _pressedKeys.map((key) => _getKeyName(key)).join(' + ');
      setState(() {
        _currentHotkey = newHotkey;
      });
      _saveHotkey(newHotkey);
    }
    _pressedKeys.clear();
    _focusNode.unfocus();
  }

  String _getKeyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) return 'Cmd';
    if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight)
      return 'Option';
    if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) return 'Ctrl';
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) return 'Shift';
    return key.keyLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          print(
              'Key event: ${event.runtimeType}, ${event.logicalKey}'); // Debug print
          if (_isRecording) {
            if (event is KeyDownEvent) {
              setState(() {
                _pressedKeys.add(event.logicalKey);
              });
            }
            // We're not removing keys on KeyUpEvent anymore
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color Picker Hotkey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isRecording
                        ? _pressedKeys
                            .map((key) => _getKeyName(key))
                            .join(' + ')
                        : _currentHotkey),
                    ElevatedButton(
                      onPressed:
                          _isRecording ? _stopRecording : _startRecording,
                      child: Text(_isRecording ? 'Stop' : 'Change'),
                    ),
                  ],
                ),
              ),
              if (_isRecording)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Press the desired key combination...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
