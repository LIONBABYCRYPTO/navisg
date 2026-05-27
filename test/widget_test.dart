import 'package:flutter_test/flutter_test.dart';
import 'package:navisg/models/bus_stop.dart';

void main() {
  test('BusStop parses from JSON correctly', () {
    final json = {
      'BusStopCode': '83139',
      'Description': 'Opp Orchard Stn/Tang Plaza',
      'Latitude': 1.3015,
      'Longitude': 103.8390,
    };

    final stop = BusStop.fromJson(json);
    expect(stop.stopCode, '83139');
    expect(stop.description, 'Opp Orchard Stn/Tang Plaza');
    expect(stop.latitude, 1.3015);
    expect(stop.longitude, 103.8390);
  });

  test('BusArrivalInfo calculates minutes correctly', () {
    final future = DateTime.now().add(const Duration(minutes: 5));
    final info = BusArrivalInfo(
      estimatedArrivalEpoch: future.millisecondsSinceEpoch,
      monitored: 1,
      load: 'SEA',
      feature: 'WAB',
      type: 'SD',
    );

    expect(info.minutesUntilArrival, 5);
    expect(info.isWheelchairAccessible, true);
    expect(info.loadDescription, 'Seats Available');
  });

  test('BusArrivalInfo handles unmonitored bus', () {
    final info = BusArrivalInfo(
      monitored: 0,
      load: '',
      feature: '',
      type: '',
    );

    expect(info.minutesUntilArrival, null);
  });
}
