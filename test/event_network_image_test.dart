import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/presentation/widgets/event_network_image.dart';

void main() {
  test('normalizes valid production artwork URLs', () {
    expect(
      EventNetworkImage.normalize(' https://cdn.example.test/event.jpg '),
      'https://cdn.example.test/event.jpg',
    );
  });

  test('rejects empty, relative, and unsafe artwork URLs', () {
    expect(EventNetworkImage.normalize(''), isNull);
    expect(EventNetworkImage.normalize('/events/image.jpg'), isNull);
    expect(EventNetworkImage.normalize('javascript:alert(1)'), isNull);
  });
}
