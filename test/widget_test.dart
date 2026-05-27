import 'package:flutter_test/flutter_test.dart';
import 'package:navisg/models/bus_stop.dart';
import 'package:navisg/models/transport_data.dart';

void main() {
  // Phase 1 tests
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

  // Phase 2 tests
  test('Carpark parses from JSON correctly', () {
    final json = {
      'CarParkID': '2',
      'Area': 'Marina',
      'Development': 'Marina Square',
      'Location': '1.29115 103.85728',
      'AvailableLots': 100,
      'LotType': 'C',
      'Agency': 'LTA',
    };
    final cp = Carpark.fromJson(json);
    expect(cp.id, '2');
    expect(cp.development, 'Marina Square');
    expect(cp.availableLots, 100);
    expect(cp.latitude, 1.29115);
    expect(cp.longitude, 103.85728);
    expect(cp.lotTypeLabel, 'Car');
  });

  test('Carpark availability status works', () {
    final full = Carpark(
      id: '1', area: 'Test',
      development: 'Full Lot', latitude: 0, longitude: 0,
      availableLots: 5, lotType: 'C', agency: 'LTA',
    );
    expect(full.availabilityStatus, 'full');

    final limited = Carpark(
      id: '2', area: 'Test',
      development: 'Limited', latitude: 0, longitude: 0,
      availableLots: 50, lotType: 'C', agency: 'LTA',
    );
    expect(limited.availabilityStatus, 'limited');

    final plenty = Carpark(
      id: '3', area: 'Test',
      development: 'Plenty', latitude: 0, longitude: 0,
      availableLots: 200, lotType: 'C', agency: 'LTA',
    );
    expect(plenty.availabilityStatus, 'plenty');
  });

  test('TrafficIncident parses correctly', () {
    final json = {
      'Type': 'Accident',
      'Message': 'Accident at PIE towards Changi',
      'Location': '1.33 103.89',
    };
    final inc = TrafficIncident.fromJson(json);
    expect(inc.type, 'Accident');
    expect(inc.message, 'Accident at PIE towards Changi');
    expect(inc.latitude, 1.33);
    expect(inc.longitude, 103.89);
  });

  test('StationCrowdDensity parses correctly', () {
    final json = {
      'StationCode': 'NS1',
      'StationName': 'Jurong East',
      'CrowdLevel': '2',
      'Direction': 'Towards City',
      'Platform': 'Platform A',
    };
    final s = StationCrowdDensity.fromJson(json);
    expect(s.stationCode, 'NS1');
    expect(s.stationName, 'Jurong East');
    expect(s.crowdLabel, 'Moderate');
  });
}
