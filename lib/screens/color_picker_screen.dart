import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/color_utils.dart';
import '../utils/hotkey_provider.dart';
import '../widgets/footer_guide.dart';
import '../widgets/magnifier_view.dart';
import 'settings_screen.dart';

class ColorPickerScreen extends StatefulWidget  with TrayListener {
  const ColorPickerScreen({Key? key}) : super(key: key);

  @override
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with TrayListener {
  final MethodChannel _channel =
      MethodChannel('com.example.colorpicker/color_picker');
  final ScrollController _scrollController = ScrollController();

  Color _pickedColor = Colors.white;
  bool _isPicking = false;
  ui.Image? _magnifiedImage;
  Offset _currentPosition = Offset.zero;
  List<Color> _savedColors = [];

  @override
  void initState() {
    super.initState();
    _initTray();
    _channel.setMethodCallHandler(_handleMethodCall);
    windowManager.hide();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/app_icon.png', isTemplate: true);
    await trayManager.setContextMenu(_buildTrayMenu());
    trayManager.addListener(this);
  }

  Menu _buildTrayMenu() {
    return Menu(
      items: [
        MenuItem(key: 'show_hide', label: 'Show/Hide'),
        MenuItem(key: 'pick_color', label: 'Pick Color'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'colorUpdated':
        _handleColorUpdated(call.arguments);
        break;
      case 'colorSaved':
        _handleColorSaved(call.arguments);
        setState(() {
          _isPicking = false;
        });
        break;
      case 'log':
        _handleLog(call.arguments);
        break;
      default:
        print("Unhandled method: ${call.method}");
    }
  }

  void _handleColorUpdated(dynamic arguments) {
    if (arguments is Map) {
      final colorList = (arguments['color'] as List).cast<int>();
      final x = arguments['x'] as double;
      final y = arguments['y'] as double;

      setState(() {
        _pickedColor =
            Color.fromRGBO(colorList[2], colorList[1], colorList[0], 1);
        _currentPosition = Offset(x, y);
      });
      _updateMagnifiedImage(x, y);
    }
  }

  void _handleColorSaved(dynamic arguments) {
    if (arguments is Map) {
      final colorList = (arguments['color'] as List).cast<int>();
      setState(() {
        _savedColors
            .add(Color.fromRGBO(colorList[2], colorList[1], colorList[0], 1));
      });
    }
  }

  void _handleLog(dynamic arguments) {
    if (arguments is Map && arguments.containsKey('log')) {
      print("IOS log: ${arguments['log']}");
    }
  }

  Future<void> _updateMagnifiedImage(double x, double y) async {
    final result =
        await _channel.invokeMethod('getMagnifiedImage', {'x': x, 'y': y});
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
    await _toggleWindowVisibility();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_hide':
        await _toggleWindowVisibility();
        break;
      case 'pick_color':
        _startPickSession();
        break;
      case 'quit':
        await windowManager.close();
        break;
    }
  }

  Future<void> _toggleWindowVisibility() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  Future<void> _startPickSession() async {
    setState(() {
      _isPicking = true;
    });
    try {
      await _channel.invokeMethod('startColorPicking');
    } catch (e) {
      print('Error picking color: $e');
      setState(() {
        _isPicking = false;
      });
    }
  }

  Future<void> _stopPickSession() async {
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
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildColorDisplay()),
          Consumer<HotkeyProvider>(
            builder: (context, hotkeyProvider, child) {
              return FooterGuide(hotkey: hotkeyProvider.hotkey);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
      child: Row(
        children: [
          _buildPickButton(),
          const SizedBox(width: 10),
          Expanded(child: _buildColorList()),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildPickButton() {
    return ElevatedButton.icon(
      onPressed: _isPicking ? _stopPickSession : _startPickSession,
      label: Text(_isPicking ? 'Stop' : 'Pick'),
      icon: const Icon(Icons.colorize_rounded),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        primary: Colors.blue,
        onPrimary: Colors.white,
      ),
    );
  }

  Widget _buildColorList() {
    return SizedBox(
      height: 60,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          _scrollController.position
              .moveTo(_scrollController.offset - details.delta.dx);
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
            itemBuilder: (context, index) =>
                _buildColorItem(_savedColors[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildColorItem(Color color) {
    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SettingsScreen()));
      },
    );
  }

  Widget _buildColorDisplay() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildColorPreview(),
          const SizedBox(width: 20),
          Expanded(child: _buildColorInfo()),
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildColorInfo() {
    return Column(
      children: [
        _buildColorFormatDisplay('HEX', ColorUtils.hexString(_pickedColor)),
        _buildColorFormatDisplay('RGB', ColorUtils.rgbString(_pickedColor)),
        _buildColorFormatDisplay('HSL', ColorUtils.hslString(_pickedColor)),
        _buildColorFormatDisplay('HSV', ColorUtils.hsvString(_pickedColor)),
      ],
    );
  }

  Widget _buildColorFormatDisplay(String format, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 30,
              child: Text(format, style: TextStyle(color: Colors.grey))),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(format, value),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String format, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$format value copied to clipboard')),
    );
  }

  void _selectColor(Color color) {
    setState(() {
      _pickedColor = color;
    });
  }
}
