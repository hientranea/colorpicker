import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(300, 200),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ColorPickerApp(),
    );
  }
}

class ColorPickerApp extends StatefulWidget {
  @override
  _ColorPickerAppState createState() => _ColorPickerAppState();
}

class _ColorPickerAppState extends State<ColorPickerApp> with TrayListener {
  Color _pickedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initTray();
  }

  @override
  void onTrayIconMouseDown() {
    // do something, for example pop up the menu
    trayManager.popUpContextMenu();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      'assets/app_icon.png',
      isTemplate: true, // This is important for macOS
    );
    Menu menu = Menu(
      items: [
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
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'pick_color') {
      _startPickSession();
    } else if (menuItem.key == 'quit') {
      windowManager.close();
    }
  }

  void _startPickSession() async {
    try {
      final result = await MethodChannel('com.example.colorpicker/color_picker').invokeMethod('pickColor');
      setState(() {
        _pickedColor = Color.fromRGBO(result[0], result[1], result[2], 1);
      });
    } catch (e) {
      print('Error picking color: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              color: _pickedColor,
            ),
            SizedBox(height: 20),
            Text('RGB: ${_pickedColor.red}, ${_pickedColor.green}, ${_pickedColor.blue}'),
            Text('Hex: #${_pickedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}'),
          ],
        ),
      ),
    );
  }
}