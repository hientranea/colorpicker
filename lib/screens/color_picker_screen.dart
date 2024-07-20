import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/color_display.dart';
import '../widgets/magnifier_view.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({Key? key}) : super(key: key);

  @override
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with TrayListener {
  Color _pickedColor = Colors.white;
  bool _isPicking = false;
  ui.Image? _magnifiedImage;
  Offset _currentPosition = Offset.zero;
  final MethodChannel _channel =
      MethodChannel('com.example.colorpicker/color_picker');

  @override
  void initState() {
    super.initState();
    _initTray();
    _channel.setMethodCallHandler(_handleMethodCall);
    windowManager.hide();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'colorUpdated':
        if (call.arguments is Map) {
          final Map<dynamic, dynamic> args =
              call.arguments as Map<dynamic, dynamic>;

          if (args.containsKey('color') &&
              args.containsKey('x') &&
              args.containsKey('y')) {
            final List<int> colorList = (args['color'] as List).cast<int>();
            final double x = args['x'] as double;
            final double y = args['y'] as double;

            setState(() {
              _pickedColor =
                  Color.fromRGBO(colorList[2], colorList[1], colorList[0], 1);
              _currentPosition = Offset(x, y);
            });
            await _updateMagnifiedImage(x, y);
          } else {
            print("Missing required keys in arguments");
          }
        } else {
          print("Arguments are not a Map: ${call.arguments.runtimeType}");
        }
        break;
      default:
        print("Unhandled method: ${call.method}");
    }
  }

  Future<void> _updateMagnifiedImage(double x, double y) async {
    final result = await _channel.invokeMethod('getMagnifiedImage', {
      'x': x,
      'y': y,
    });

    if (result != null) {
      final bytes = result as Uint8List;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _magnifiedImage = frame.image;
      });
    }
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      'assets/app_icon.png',
      isTemplate: true,
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_hide',
          label: 'Show/Hide',
        ),
        MenuItem(
          key: 'pick_color',
          label: 'Pick Color',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_hide':
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
        break;
      case 'pick_color':
        _startPickSession();
        break;
      case 'quit':
        await windowManager.close();
        break;
    }
  }

  void _startPickSession() async {
    setState(() {
      _isPicking = true;
    });
    try {
      final result = await _channel.invokeMethod('startColorPicking');
      setState(() {
        _pickedColor = Color.fromRGBO(result[0], result[1], result[2], 1);
        _isPicking = false;
      });
    } catch (e) {
      print('Error picking color: $e');
      setState(() {
        _isPicking = false;
      });
    }
  }

  void _stopPickSession() async {
    if (_isPicking) {
      await _channel.invokeMethod('stopColorPicking');
      setState(() {
        _isPicking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorDisplay(color: _pickedColor),
            Text("X: ${_currentPosition.dx} Y: ${_currentPosition.dy}"),
            const SizedBox(height: 10),
            if (_isPicking && _magnifiedImage != null)
              MagnifierView(image: _magnifiedImage),
            ElevatedButton(
              onPressed: _isPicking ? _stopPickSession : _startPickSession,
              child: Text(_isPicking ? 'Stop Picking' : 'Start Picking'),
            ),
          ],
        ),
      ),
    );
  }
}
