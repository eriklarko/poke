import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/watering_plants/plant.dart';

import '../../utils/images.dart';
import '../../utils/test_http_client/test_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns default image when imageUri is null', () {
    final plant = Plant(
      id: '1',
      name: 'foo',
      imageUri: null,
    );

    expect(plant.image, equals(Plant.defaultImage));
  });

  test('returns image when imageUri is set', () {
    const imageUrl = 'https://example.com/foo.png';
    final httpClient = TestHttpClient(endpoints: {
      imageUrl: () => Images.redCircleBytes,
    });

    final plant = Plant(
      id: '1',
      name: 'foo',
      imageUri: Uri.parse(imageUrl),
    );

    httpClient.run(() {
      expect(Images.getNetworkImageSource((plant.image)), equals(imageUrl));
    });
  });

  test('fetches new image when imageUri changes', () {
    const firstImage = 'https://example.com/1';
    const secondImage = 'https://example.com/2';
    final httpClient = TestHttpClient(endpoints: {
      firstImage: () => Images.heartEyesEmojiBytes,
      secondImage: () => Images.redCircleBytes,
    });

    final plant = Plant(
      id: '1',
      name: 'foo',
      imageUri: Uri.parse(firstImage),
    );

    httpClient.run(() {
      // fetch the first image
      fetchImage(plant.image);

      // update the image URI
      plant.imageUri = Uri.parse(secondImage);

      // and make sure the new image is return next time plant.image is called
      expect(
        Images.getNetworkImageSource(plant.image),
        equals(secondImage),
      );
    });
  });
}

void fetchImage(Image i) {
  i.image.resolve(ImageConfiguration.empty);
}
