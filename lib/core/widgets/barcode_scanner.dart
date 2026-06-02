import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_mobile_vision_2/flutter_mobile_vision_2.dart';

extension BarcodeScanners on BuildContext {
  Future<void> scanBarcode({required Function(String) barcode}) async {
    try {
      final scanResult = await BarcodeScanner.scan(
        options: const ScanOptions(
          // autoEnableFlash: true,
          strings: {'cancel': 'Done'},
          android: AndroidOptions(useAutoFocus: true),
        ),
      );
      if (scanResult.rawContent.isNotEmpty) {
        var res = scanResult.rawContent;
        barcode.call(res);
      }
    } catch (e) {
      showAlertOverlay('Failed to scan barcode', bgColor: errorColor);
    }
  }
}

/// Barcode Scanner with Form TextField [BarcodeScannerWithTextField]
class BarcodeScannerWithTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged? onChanged;

  const BarcodeScannerWithTextField({
    super.key,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final deviceOS = context.deviceOSType;
    return deviceOS.android || deviceOS.ios
        ? _textFieldWithBarcodeScanner(context)
        : const SizedBox.shrink();
  }

  _textFieldWithBarcodeScanner(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomTextField(
            label: 'Barcode',
            controller: controller,
            onChanged: onChanged,
            textInputType: TextInputType.text,
            validator: (value) => null,
          ),
        ),
        const SizedBox(width: 10.0),
        context.elevatedIconBtn(
          const Icon(Icons.qr_code_scanner),
          onPressed: () {
            context.scanBarcode(
              barcode: (s) {
                if (s.isNotEmpty) {
                  controller?.text = s;
                  onChanged?.call(s);
                }
              },
            );
          },
          label: const Text('Scan'),
        ),
      ],
    );

    /*return BarcodeScanner(
      childWidget: (void Function()? scanFunction, List<Barcode> barcodes) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (barcodes.isNotEmpty && barcodes.first.displayValue.isNotEmpty) {
            controller?.text = barcodes.first.displayValue;
            onChanged?.call(barcodes.first.displayValue);
            debugPrint('steve-barcode ${barcodes.first.rawValue}');
          }
        });
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomTextField(
                labelText: 'Barcode',
                controller: controller,
                onChanged: onChanged,
                inputType: TextInputType.text,
                validator: (value) => null,
              ),
            ),
            const SizedBox(width: 10.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: scanFunction,
              label: const Text('Scan'),
            ),
          ],
        );
      },
    );*/
  }

  /*class BarcodeScanner extends StatefulWidget {
  final Widget Function(void Function()? scanFunction, List<Barcode> barcodes)
      childWidget;

  const BarcodeScanner({super.key, required this.childWidget});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  int? cameraBarcode = FlutterMobileVision.CAMERA_BACK;
  int? onlyFormatBarcode = Barcode.ALL_FORMATS;
  bool autoFocusBarcode = true;
  bool torchBarcode = false;
  bool multipleBarcode = false;
  bool waitTapBarcode = false;
  bool showTextBarcode = false;
  Size? _previewBarcode;
  List<Barcode> _barcodes = [];

  int? cameraOcr = FlutterMobileVision.CAMERA_BACK;
  Size? _previewOcr;

  Future<Null> _scan() async {
    List<Barcode> barcodes = [];
    Size scanPreViewOcr = _previewOcr ?? FlutterMobileVision.PREVIEW;
    try {
      barcodes = await FlutterMobileVision.scan(
        flash: torchBarcode,
        autoFocus: autoFocusBarcode,
        formats: onlyFormatBarcode ?? Barcode.ALL_FORMATS,
        multiple: multipleBarcode,
        waitTap: waitTapBarcode,
        //OPTIONAL: close camera after tap, even if there are no detection.
        //Camera would usually stay on, until there is a valid detection
        forceCloseCameraOnTap: true,
        //OPTIONAL: path to save image to. leave empty if you do not want to save the image
        imagePath: '',
        //'path/to/file.jpg'
        showText: showTextBarcode,
        preview: _previewBarcode ?? FlutterMobileVision.PREVIEW,
        scanArea: Size(scanPreViewOcr.width - 20, scanPreViewOcr.height - 20),
        camera: cameraBarcode ?? FlutterMobileVision.CAMERA_BACK,
        fps: 15.0,
      );
    } on Exception {
      barcodes.add(Barcode('Failed to get barcode.'));
    }

    if (!mounted) return;

    // Schedule a callback for the next frame to avoid updating the UI during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _barcodes = barcodes);
    });
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    FlutterMobileVision.start().then((previewSizes) => setState(() {
          if (previewSizes[cameraBarcode] == null) {
            return;
          }
          _previewBarcode = previewSizes[cameraBarcode]!.first;
          _previewOcr = previewSizes[cameraOcr]!.first;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return widget.childWidget(() async => await _scan(), _barcodes);
  }
}*/

  /*BarcodeScanner _barcodeScanner() {
    return BarcodeScanner(
      childWidget: (void Function()? scanFunction, List<Barcode> barcodes) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              barcodes.isNotEmpty &&
              barcodes.first.displayValue.isNotEmpty) {
            setState(
                () => _barcodeController.text = barcodes.first.displayValue);
          }
        });
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: BarcodeTextField(
                controller: _barcodeController,
                onChanged: (t) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10.0),
            ProductScanButton(onPressed: scanFunction),
          ],
        );
      },
    );
  }*/
}

/*extension BuildContextEntension<T> on BuildContext {
  Future<void> openSetting() => openBottomSheet(
        isExpand: false,
        child: const ScannerSetting(),
      );
}

class ScannerSetting extends StatefulWidget {
  const ScannerSetting({super.key});

  @override
  State<ScannerSetting> createState() => _ScannerSettingState();
}

class _ScannerSettingState extends State<ScannerSetting>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // double get _appBarHeight => AppBar().preferredSize.height;

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      padding: EdgeInsets.only(
        bottom: context.bottomInsetPadding,
      ),
      initialChildSize: 0.90,
      maxChildSize: 0.90,
      header: _buildHeader(context),
      child: DefaultTabController(
        length: 3,
        child: _buildBody(context),
      ),
    );

    /*
      Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                indicatorColor: Colors.black54,
                tabs: [
                  Tab(text: 'Barcode'),
                  Tab(text: 'OCR'),
                  Tab(text: 'Face')
                ],
              ),
              title: const Text('SETTINGS'),
            ),
            body: const TabBarView(children: [
              BarcodeScreen(),
              OCRScreen(),
              FaceScreen(),
            ]),
          ),
        ),
      ],
    ),)*/
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TabBar(
          controller: _tabController,
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'BarCode'),
            Tab(text: 'OCR'),
            Tab(text: 'Face'),
          ],
        ),
        SizedBox(
          height: context.screenHeight * 0.7,
          child: TabBarView(
            controller: _tabController,
            children: const [
              BarcodeScreen(),
              OCRScreen(),
              FaceScreen(),
            ],
          ),
        ),
      ],
    );
  }

  TopHeaderRow _buildHeader(BuildContext context) {
    return TopHeaderRow(
      title: Text(
        'SETTINGS',
        semanticsLabel: 'Settings',
        style:
            context.textTheme.titleLarge?.copyWith(color: kGrayColor),
      ),
      btnText: 'Close',
      onPress: () => Navigator.pop(context),
    );
  }
}

/// barcode Screen
class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  /*String _platformVersion = 'No Data';

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await FlutterMobileVision.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }*/

  int? _cameraBarcode = FlutterMobileVision.CAMERA_BACK;
  int? _onlyFormatBarcode = Barcode.ALL_FORMATS;
  bool _autoFocusBarcode = true;
  bool _torchBarcode = false;
  bool _multipleBarcode = false;
  bool _waitTapBarcode = false;
  bool _showTextBarcode = false;
  Size? _previewBarcode;
  List<Barcode> _barcodes = [];

  int? cameraOcr = FlutterMobileVision.CAMERA_BACK;
  Size? _previewOcr;

  ///
  ///
  ///
  @override
  void initState() {
    super.initState();
    // initPlatformState();
    FlutterMobileVision.start().then((previewSizes) => setState(() {
          if (previewSizes[_cameraBarcode] == null) {
            return;
          }
          _previewBarcode = previewSizes[_cameraBarcode]!.first;
          _previewOcr = previewSizes[cameraOcr]!.first;
        }));
  }

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return _getBarcodeScreen(context);
  }

  ///
  /// Scan formats
  ///
  List<DropdownMenuItem<int>> _getFormats() {
    List<DropdownMenuItem<int>> formatItems = [];

    Barcode.mapFormat.forEach((key, value) {
      formatItems.add(
        DropdownMenuItem(
          value: key,
          child: Text(value),
        ),
      );
    });

    return formatItems;
  }

  ///
  /// Camera list
  ///
  List<DropdownMenuItem<int>> _getCameras() {
    List<DropdownMenuItem<int>> cameraItems = [];

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_BACK,
      child: Text('BACK'),
    ));

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_FRONT,
      child: Text('FRONT'),
    ));

    return cameraItems;
  }

  ///
  /// Preview sizes list
  ///
  List<DropdownMenuItem<Size>> _getPreviewSizes(int facing) {
    List<DropdownMenuItem<Size>> previewItems = [];

    List<Size>? sizes = FlutterMobileVision.getPreviewSizes(facing);

    if (sizes != null) {
      for (var size in sizes) {
        previewItems.add(
          DropdownMenuItem(
            value: size,
            child: Text(size.toString()),
          ),
        );
      }
    } else {
      previewItems.add(
        const DropdownMenuItem(
          value: null,
          child: Text('Empty'),
        ),
      );
    }

    return previewItems;
  }

  ///
  /// Barcode Screen
  ///
  Widget _getBarcodeScreen(BuildContext context) {
    List<Widget> items = [];

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Camera:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<int>(
        items: _getCameras(),
        onChanged: (value) {
          _previewBarcode = null;
          setState(() => _cameraBarcode = value);
        },
        value: _cameraBarcode,
      ),
    ));

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Preview size:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<Size>(
        items: _getPreviewSizes(_cameraBarcode ?? 0),
        onChanged: (value) {
          setState(() => _previewBarcode = value);
        },
        value: _previewBarcode,
      ),
    ));

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Scan format only:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<int>(
        items: _getFormats(),
        onChanged: (value) => setState(
          () => _onlyFormatBarcode = value,
        ),
        value: _onlyFormatBarcode,
      ),
    ));

    items.add(SwitchListTile(
      title: const Text('Auto focus:'),
      value: _autoFocusBarcode,
      onChanged: (value) => setState(() => _autoFocusBarcode = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Torch:'),
      value: _torchBarcode,
      onChanged: (value) => setState(() => _torchBarcode = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Multiple Scan:'),
      value: _multipleBarcode,
      onChanged: (value) => setState(() {
        _multipleBarcode = value;
        if (value) _waitTapBarcode = true;
      }),
    ));

    items.add(SwitchListTile(
      title: const Text('Wait a tap to capture:'),
      value: _waitTapBarcode,
      onChanged: (value) => setState(() {
        _waitTapBarcode = value;
        if (!value) _multipleBarcode = false;
      }),
    ));

    items.add(SwitchListTile(
      title: const Text('Show text:'),
      value: _showTextBarcode,
      onChanged: (value) => setState(() => _showTextBarcode = value),
    ));

    items.add(
      Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18.0,
          bottom: 12.0,
        ),
        child: ElevatedButton(
          onPressed: _scan,
          child: const Text('TRY SCAN!'),
        ),
      ),
    );

    items.addAll(
      ListTile.divideTiles(
        context: context,
        tiles: _barcodes
            .map(
              (barcode) => BarcodeWidget(barcode),
            )
            .toList(),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(
        top: 12.0,
      ),
      children: items,
    );
  }

  ///
  /// Barcode Method
  ///
  Future<Null> _scan() async {
    List<Barcode> barcodes = [];
    Size scanPreViewOcr = _previewOcr ?? FlutterMobileVision.PREVIEW;
    try {
      barcodes = await FlutterMobileVision.scan(
        flash: _torchBarcode,
        autoFocus: _autoFocusBarcode,
        formats: _onlyFormatBarcode ?? Barcode.ALL_FORMATS,
        multiple: _multipleBarcode,
        waitTap: _waitTapBarcode,
        //OPTIONAL: close camera after tap, even if there are no detection.
        //Camera would usually stay on, until there is a valid detection
        forceCloseCameraOnTap: true,
        //OPTIONAL: path to save image to. leave empty if you do not want to save the image
        imagePath: '',
        //'path/to/file.jpg'
        showText: _showTextBarcode,
        preview: _previewBarcode ?? FlutterMobileVision.PREVIEW,
        scanArea: Size(scanPreViewOcr.width - 20, scanPreViewOcr.height - 20),
        camera: _cameraBarcode ?? FlutterMobileVision.CAMERA_BACK,
        fps: 15.0,
      );
    } on Exception {
      barcodes.add(Barcode('Failed to get barcode.'));
    }

    if (!mounted) return;

    setState(() => _barcodes = barcodes);
  }
}

///
/// BarcodeWidget
///
class BarcodeWidget extends StatelessWidget {
  final Barcode barcode;

  const BarcodeWidget(this.barcode, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.star),
      title: Text(barcode.displayValue),
      subtitle: Text('${barcode.getFormatString()} (${barcode.format}) - '
          '${barcode.getValueFormatString()} (${barcode.valueFormat})'),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BarcodeDetail(barcode: barcode),
        ),
      ),
    );
  }
}

class BarcodeDetail extends StatefulWidget {
  final Barcode barcode;

  const BarcodeDetail({super.key, required this.barcode});

  @override
  State<BarcodeDetail> createState() => _BarcodeDetailState();
}

class _BarcodeDetailState extends State<BarcodeDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Details'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(widget.barcode.displayValue),
            subtitle: const Text('Display Value'),
          ),
          ListTile(
            title: Text(widget.barcode.rawValue),
            subtitle: const Text('Raw Value'),
          ),
          ListTile(
            title: Text('${widget.barcode.getFormatString()} '
                '(${widget.barcode.format})'),
            subtitle: const Text('Format'),
          ),
          ListTile(
            title: Text('${widget.barcode.getValueFormatString()} '
                '(${widget.barcode.valueFormat})'),
            subtitle: const Text('Value Format'),
          ),
          ListTile(
            title: Text(widget.barcode.top.toString()),
            subtitle: const Text('Top'),
          ),
          ListTile(
            title: Text(widget.barcode.bottom.toString()),
            subtitle: const Text('Bottom'),
          ),
          ListTile(
            title: Text(widget.barcode.left.toString()),
            subtitle: const Text('Left'),
          ),
          ListTile(
            title: Text(widget.barcode.right.toString()),
            subtitle: const Text('Right'),
          ),
        ],
      ),
    );
  }
}

///
/// OCR Screen
class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  /*String _platformVersion = 'No Data';

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await FlutterMobileVision.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }*/

  int? cameraBarcode = FlutterMobileVision.CAMERA_BACK;

  int? _cameraOcr = FlutterMobileVision.CAMERA_BACK;
  bool _autoFocusOcr = true;
  bool _torchOcr = false;
  bool _multipleOcr = false;
  bool _waitTapOcr = false;
  bool _showTextOcr = true;
  Size? _previewOcr;
  List<OcrText> _textsOcr = [];

  ///
  ///
  ///
  @override
  void initState() {
    super.initState();
    // initPlatformState();
    FlutterMobileVision.start().then((previewSizes) => setState(() {
          if (previewSizes[cameraBarcode] == null) {
            return;
          }
          _previewOcr = previewSizes[_cameraOcr]!.first;
        }));
  }

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return _getOcrScreen(context);
  }

  ///
  /// Camera list
  ///
  List<DropdownMenuItem<int>> _getCameras() {
    List<DropdownMenuItem<int>> cameraItems = [];

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_BACK,
      child: Text('BACK'),
    ));

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_FRONT,
      child: Text('FRONT'),
    ));

    return cameraItems;
  }

  ///
  /// Preview sizes list
  ///
  List<DropdownMenuItem<Size>> _getPreviewSizes(int facing) {
    List<DropdownMenuItem<Size>> previewItems = [];

    List<Size>? sizes = FlutterMobileVision.getPreviewSizes(facing);

    if (sizes != null) {
      for (var size in sizes) {
        previewItems.add(
          DropdownMenuItem(
            value: size,
            child: Text(size.toString()),
          ),
        );
      }
    } else {
      previewItems.add(
        const DropdownMenuItem(
          value: null,
          child: Text('Empty'),
        ),
      );
    }

    return previewItems;
  }

  ///
  /// OCR Screen
  ///
  Widget _getOcrScreen(BuildContext context) {
    List<Widget> items = [];

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Camera:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<int>(
        items: _getCameras(),
        onChanged: (value) {
          _previewOcr = null;
          setState(() => _cameraOcr = value);
        },
        value: _cameraOcr,
      ),
    ));

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Preview size:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<Size>(
        items: _getPreviewSizes(_cameraOcr ?? 0),
        onChanged: (value) {
          setState(() => _previewOcr = value);
        },
        value: _previewOcr,
      ),
    ));

    items.add(SwitchListTile(
      title: const Text('Auto focus:'),
      value: _autoFocusOcr,
      onChanged: (value) => setState(() => _autoFocusOcr = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Torch:'),
      value: _torchOcr,
      onChanged: (value) => setState(() => _torchOcr = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Return all texts:'),
      value: _multipleOcr,
      onChanged: (value) => setState(() => _multipleOcr = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Capture when tap screen:'),
      value: _waitTapOcr,
      onChanged: (value) => setState(() => _waitTapOcr = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Show text:'),
      value: _showTextOcr,
      onChanged: (value) => setState(() => _showTextOcr = value),
    ));

    items.add(
      Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18.0,
          bottom: 12.0,
        ),
        child: ElevatedButton(
          onPressed: _read,
          child: const Text('TRY READ!'),
        ),
      ),
    );

    items.addAll(
      ListTile.divideTiles(
        context: context,
        tiles: _textsOcr
            .map(
              (ocrText) => OcrTextWidget(ocrText),
            )
            .toList(),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(
        top: 12.0,
      ),
      children: items,
    );
  }

  ///
  /// OCR Method
  ///
  Future<Null> _read() async {
    List<OcrText> texts = [];
    Size scanPreviewOcr = _previewOcr ?? FlutterMobileVision.PREVIEW;
    try {
      texts = await FlutterMobileVision.read(
        flash: _torchOcr,
        autoFocus: _autoFocusOcr,
        multiple: _multipleOcr,
        waitTap: _waitTapOcr,
        //OPTIONAL: close camera after tap, even if there are no detection.
        //Camera would usually stay on, until there is a valid detection
        forceCloseCameraOnTap: true,
        //OPTIONAL: path to save image to. leave empty if you do not want to save the image
        imagePath: '',
        //'path/to/file.jpg'
        showText: _showTextOcr,
        preview: _previewOcr ?? FlutterMobileVision.PREVIEW,
        scanArea: Size(scanPreviewOcr.width - 20, scanPreviewOcr.height - 20),
        camera: _cameraOcr ?? FlutterMobileVision.CAMERA_BACK,
        fps: 2.0,
      );
    } on Exception {
      texts.add(OcrText('Failed to recognize text.'));
    }

    if (!mounted) return;

    setState(() => _textsOcr = texts);
  }
}

///
/// OcrTextWidget
///
class OcrTextWidget extends StatelessWidget {
  final OcrText ocrText;

  const OcrTextWidget(this.ocrText, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.title),
      title: Text(ocrText.value),
      subtitle: Text(ocrText.language),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OcrTextDetail(ocrText: ocrText),
        ),
      ),
    );
  }
}

class OcrTextDetail extends StatefulWidget {
  final OcrText ocrText;

  const OcrTextDetail({super.key, required this.ocrText});

  @override
  State<OcrTextDetail> createState() => _OcrTextDetailState();
}

class _OcrTextDetailState extends State<OcrTextDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Details'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(widget.ocrText.value),
            subtitle: const Text('Value'),
          ),
          ListTile(
            title: Text(widget.ocrText.language),
            subtitle: const Text('Language'),
          ),
          ListTile(
            title: Text(widget.ocrText.top.toString()),
            subtitle: const Text('Top'),
          ),
          ListTile(
            title: Text(widget.ocrText.bottom.toString()),
            subtitle: const Text('Bottom'),
          ),
          ListTile(
            title: Text(widget.ocrText.left.toString()),
            subtitle: const Text('Left'),
          ),
          ListTile(
            title: Text(widget.ocrText.right.toString()),
            subtitle: const Text('Right'),
          ),
        ],
      ),
    );
  }
}

///
/// face Screen
class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  /*String _platformVersion = 'Unknown';

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await FlutterMobileVision.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }*/

  int? cameraBarcode = FlutterMobileVision.CAMERA_BACK;

  int? cameraOcr = FlutterMobileVision.CAMERA_BACK;
  Size? _previewOcr;

  int? _cameraFace = FlutterMobileVision.CAMERA_FRONT;
  bool _autoFocusFace = true;
  bool _torchFace = false;
  bool _multipleFace = true;
  bool _showTextFace = true;
  Size? _previewFace;
  List<Face> _faces = [];

  ///
  ///
  ///
  @override
  void initState() {
    super.initState();
    // initPlatformState();
    FlutterMobileVision.start().then((previewSizes) => setState(() {
          if (previewSizes[cameraBarcode] == null) {
            return;
          }
          _previewOcr = previewSizes[cameraOcr]!.first;
          _previewFace = previewSizes[_cameraFace]!.first;
        }));
  }

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return _getFaceScreen(context);
  }

  ///
  /// Camera list
  ///
  List<DropdownMenuItem<int>> _getCameras() {
    List<DropdownMenuItem<int>> cameraItems = [];

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_BACK,
      child: Text('BACK'),
    ));

    cameraItems.add(const DropdownMenuItem(
      value: FlutterMobileVision.CAMERA_FRONT,
      child: Text('FRONT'),
    ));

    return cameraItems;
  }

  ///
  /// Preview sizes list
  ///
  List<DropdownMenuItem<Size>> _getPreviewSizes(int facing) {
    List<DropdownMenuItem<Size>> previewItems = [];

    List<Size>? sizes = FlutterMobileVision.getPreviewSizes(facing);

    if (sizes != null) {
      for (var size in sizes) {
        previewItems.add(
          DropdownMenuItem(
            value: size,
            child: Text(size.toString()),
          ),
        );
      }
    } else {
      previewItems.add(
        const DropdownMenuItem(
          value: null,
          child: Text('Empty'),
        ),
      );
    }

    return previewItems;
  }

  ///
  /// Face Screen
  ///
  Widget _getFaceScreen(BuildContext context) {
    List<Widget> items = [];

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Camera:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<int>(
        items: _getCameras(),
        onChanged: (value) {
          _previewFace = null;
          setState(() => _cameraFace = value);
        },
        value: _cameraFace,
      ),
    ));

    items.add(const Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 18.0,
        right: 18.0,
      ),
      child: Text('Preview size:'),
    ));

    items.add(Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 18.0,
      ),
      child: DropdownButton<Size>(
        items: _getPreviewSizes(_cameraFace ?? 0),
        onChanged: (value) {
          setState(() => _previewFace = value);
        },
        value: _previewFace,
      ),
    ));

    items.add(SwitchListTile(
      title: const Text('Auto focus:'),
      value: _autoFocusFace,
      onChanged: (value) => setState(() => _autoFocusFace = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Torch:'),
      value: _torchFace,
      onChanged: (value) => setState(() => _torchFace = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Multiple:'),
      value: _multipleFace,
      onChanged: (value) => setState(() => _multipleFace = value),
    ));

    items.add(SwitchListTile(
      title: const Text('Show text:'),
      value: _showTextFace,
      onChanged: (value) => setState(() => _showTextFace = value),
    ));

    items.add(
      Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18.0,
          bottom: 12.0,
        ),
        child: ElevatedButton(
          onPressed: _face,
          child: const Text('TRY DETECT!'),
        ),
      ),
    );

    items.addAll(
      ListTile.divideTiles(
        context: context,
        tiles: _faces.map((face) => FaceWidget(face: face)).toList(),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(top: 12.0),
      children: items,
    );
  }

  ///
  /// Face Method
  ///
  Future<Null> _face() async {
    Size scanPreviewOcr = _previewOcr ?? FlutterMobileVision.PREVIEW;
    List<Face> faces = [];
    try {
      faces = await FlutterMobileVision.face(
        flash: _torchFace,
        autoFocus: _autoFocusFace,
        multiple: _multipleFace,
        showText: _showTextFace,
        //OPTIONAL: close camera after tap, even if there are no detection.
        //Camera would usually stay on, until there is a valid detection
        forceCloseCameraOnTap: true,
        //OPTIONAL: path to save image to. leave empty if you do not want to save the image
        imagePath: '',
        //'path/to/file.jpg'
        preview: _previewFace ?? FlutterMobileVision.PREVIEW,
        scanArea: Size(scanPreviewOcr.width - 20, scanPreviewOcr.height - 20),
        camera: _cameraFace ?? FlutterMobileVision.CAMERA_BACK,
        fps: 15.0,
      );
    } on Exception {
      faces.add(Face(-1));
    }

    if (!mounted) return;

    setState(() => _faces = faces);
  }
}

///
/// FaceWidget
///
class FaceWidget extends StatelessWidget {
  final Face face;

  const FaceWidget({super.key, required this.face});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.face),
      title: Text(face.id.toString()),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FaceDetail(face: face),
        ),
      ),
    );
  }
}

class FaceDetail extends StatefulWidget {
  final Face face;

  const FaceDetail({super.key, required this.face});

  @override
  State<FaceDetail> createState() => _FaceDetailState();
}

class _FaceDetailState extends State<FaceDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Details'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(widget.face.id.toString()),
            subtitle: const Text('Id'),
          ),
          ListTile(
            title: Text(widget.face.eulerY.toString()),
            subtitle: const Text('Euler Y'),
          ),
          ListTile(
            title: Text(widget.face.eulerZ.toString()),
            subtitle: const Text('Euler Z'),
          ),
          ListTile(
            title: Text(widget.face.leftEyeOpenProbability.toString()),
            subtitle: const Text('Left Eye Open Probability'),
          ),
          ListTile(
            title: Text(widget.face.rightEyeOpenProbability.toString()),
            subtitle: const Text('Right Eye Open Probability'),
          ),
          ListTile(
            title: Text(widget.face.smilingProbability.toString()),
            subtitle: const Text('Smiling Probability'),
          ),
          ListTile(
            title: Text(widget.face.top.toString()),
            subtitle: const Text('Top'),
          ),
          ListTile(
            title: Text(widget.face.bottom.toString()),
            subtitle: const Text('Bottom'),
          ),
          ListTile(
            title: Text(widget.face.left.toString()),
            subtitle: const Text('Left'),
          ),
          ListTile(
            title: Text(widget.face.right.toString()),
            subtitle: const Text('Right'),
          ),
        ],
      ),
    );
  }
}*/
