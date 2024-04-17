import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/watering_plants/plant_image.dart';

import '../../test_app.dart';
import '../../utils/images.dart';

void main() {
  testWidgets('shows the provided image', (tester) async {
    final ImageProvider img = MemoryImage(Images.heartEyesEmojiBytes);
    await pumpInTestApp(
      tester,
      PlantImage.large(img),
    );

    expect(find.image(img), findsOneWidget);
  });

  testWidgets('shows the default image when no image is given', (tester) async {
    await pumpInTestApp(tester, const PlantImage.large(null));
    expect(find.image(PlantImage.defaultImage), findsOneWidget);
  });
}
