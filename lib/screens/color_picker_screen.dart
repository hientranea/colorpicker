import 'dart:ui' as ui;

import 'package:colorpicker/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/color_utils.dart';
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
  List<Color> _savedColors = [];
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
      case 'colorSaved':
        if (call.arguments is Map) {
          final Map<dynamic, dynamic> args =
              call.arguments as Map<dynamic, dynamic>;
          if (args.containsKey('color')) {
            final List<int> colorList = (args['color'] as List).cast<int>();
            print("Add new color: ${colorList}");
            setState(() {
              _savedColors.add(
                  Color.fromRGBO(colorList[2], colorList[1], colorList[0], 1));
            });
          }
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
      body: Container(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildColorDisplay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    ScrollController _scrollController = ScrollController();

    return Container(
      color: AppColors.backgroundGrey,
      padding: const EdgeInsets.only(top: 18.0, left: 8, right: 8, bottom: 10),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _isPicking ? _stopPickSession : _startPickSession,
            label: Text(_isPicking ? 'Stop' : 'Pick'),
            icon: const Icon(Icons.colorize_rounded),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 60,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _scrollController.position.moveTo(
                    _scrollController.offset - details.delta.dx,
                  );
                },
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6.0,
                  radius: const Radius.circular(10),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedColors.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _selectColor(_savedColors[index]),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _savedColors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorDisplay() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _pickedColor,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            if (_isPicking && _magnifiedImage != null)
              MagnifierView(image: _magnifiedImage),
            const SizedBox(height: 10),
            Text("X: ${_currentPosition.dx.toInt()}"),
            Text("Y: ${_currentPosition.dy.toInt()}")
          ]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(children: [
              _buildColorFormatDisplay(
                  'HEX', ColorUtils.hexString(_pickedColor)),
              _buildColorFormatDisplay(
                  'RGB', ColorUtils.rgbString(_pickedColor)),
              _buildColorFormatDisplay(
                  'HSL', ColorUtils.hslString(_pickedColor)),
              _buildColorFormatDisplay(
                  'HSV', ColorUtils.hsvString(_pickedColor)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildColorFormatDisplay(String format, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGrey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 30,
              child: Text(format,
                  style: const TextStyle(color: AppColors.textGrey))),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$format value copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _selectColor(Color color) {
    setState(() {
      _pickedColor = color;
    });
  }
}
