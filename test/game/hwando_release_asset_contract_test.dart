import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const specs = <String, ui.Size>{
    'assets/images/vfx/hwando/hwando_windup_128.png': ui.Size(512, 128),
    'assets/images/vfx/hwando/hwando_strike_128.png': ui.Size(768, 128),
    'assets/images/vfx/hwando/hwando_recovery_128.png': ui.Size(512, 128),
    'assets/images/vfx/hwando/hwando_contact_128.png': ui.Size(768, 128),
  };

  for (final entry in specs.entries) {
    test('${entry.key} is an RGBA sheet with transparent corners', () async {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: 'Missing authored Hwando art');

      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final image = (await codec.getNextFrame()).image;
      expect(
        ui.Size(image.width.toDouble(), image.height.toDouble()),
        entry.value,
      );

      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      final bytes = data!.buffer.asUint8List();
      final topLeftAlpha = bytes[3];
      final topRightAlpha = bytes[(image.width - 1) * 4 + 3];
      final bottomLeftAlpha = bytes[(image.height - 1) * image.width * 4 + 3];
      final bottomRightAlpha = bytes.last;
      expect(
        [topLeftAlpha, topRightAlpha, bottomLeftAlpha, bottomRightAlpha],
        everyElement(0),
      );
    });
  }
}
