/// Carpark availability data model
class Carpark {
  final String id;
  final String area;
  final String development;
  final double latitude;
  final double longitude;
  final int availableLots;
  final String lotType; // C = Car, H = Heavy Vehicle, M = Motorcycle
  final String agency;

  Carpark({
    required this.id,
    required this.area,
    required this.development,
    required this.latitude,
    required this.longitude,
    required this.availableLots,
    required this.lotType,
    required this.agency,
  });

  factory Carpark.fromJson(Map<String, dynamic> json) {
    final loc = (json['Location'] as String? ?? '0 0').split(' ');
    return Carpark(
      id: json['CarParkID']?.toString() ?? '',
      area: json['Area'] ?? '',
      development: json['Development'] ?? '',
      latitude: loc.length >= 2 ? double.tryParse(loc[0]) ?? 0.0 : 0.0,
      longitude: loc.length >= 2 ? double.tryParse(loc[1]) ?? 0.0 : 0.0,
      availableLots: json['AvailableLots'] ?? 0,
      lotType: json['LotType'] ?? 'C',
      agency: json['Agency'] ?? '',
    );
  }

  String get lotTypeLabel {
    switch (lotType) {
      case 'C': return 'Car';
      case 'H': return 'Heavy Vehicle';
      case 'M': return 'Motorcycle';
      default: return lotType;
    }
  }

  /// Returns a color based on availability
  String get availabilityStatus {
    if (availableLots > 100) return 'plenty';
    if (availableLots > 20) return 'limited';
    return 'full';
  }
}

/// MRT station crowd density
class StationCrowdDensity {
  final String stationCode;
  final String stationName;
  final String crowdLevel; // 1-4 or descriptive
  final String trainDirection;
  final String platform; // Platform/Near gate info

  StationCrowdDensity({
    required this.stationCode,
    required this.stationName,
    required this.crowdLevel,
    required this.trainDirection,
    required this.platform,
  });

  factory StationCrowdDensity.fromJson(Map<String, dynamic> json) {
    return StationCrowdDensity(
      stationCode: json['StationCode'] ?? json['station_code'] ?? '',
      stationName: json['StationName'] ?? json['station_name'] ?? '',
      crowdLevel: json['CrowdLevel']?.toString() ?? json['crowd_level']?.toString() ?? '0',
      trainDirection: json['Direction'] ?? json['dir'] ?? '',
      platform: json['Platform'] ?? json['platform'] ?? '',
    );
  }

  String get crowdLabel {
    final level = int.tryParse(crowdLevel) ?? 0;
    switch (level) {
      case 0: return 'Unknown';
      case 1: return 'Not Crowded';
      case 2: return 'Moderate';
      case 3: return 'Crowded';
      case 4: return 'Very Crowded';
      default: return 'Level $crowdLevel';
    }
  }
}

/// Traffic incident
class TrafficIncident {
  final String type;
  final String message;
  final double? latitude;
  final double? longitude;

  TrafficIncident({
    required this.type,
    required this.message,
    this.latitude,
    this.longitude,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    final loc = (json['Location'] as String? ?? '').split(' ');
    return TrafficIncident(
      type: json['Type'] ?? json['type'] ?? '',
      message: json['Message'] ?? json['message'] ?? '',
      latitude: loc.length >= 2 ? double.tryParse(loc[0]) : null,
      longitude: loc.length >= 2 ? double.tryParse(loc[1]) : null,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'Accident': return '🚗 Accident';
      case 'Roadwork': return '🚧 Road Work';
      case 'VehicleBreakdown': return '🔧 Breakdown';
      case 'Weather': return '🌧️ Weather';
      case 'Obstacle': return '⚠️ Obstacle';
      case 'Block': return '🚫 Road Block';
      case 'HeavyTraffic': return '🐌 Heavy Traffic';
      default: return type;
    }
  }
}

/// A single stop in a bus route (from BusRoutes API)
class BusRouteStop {
  final String serviceNo;
  final String operator;
  final int direction; // 1=forward, 2=backward
  final int stopSequence;
  final String busStopCode;
  final double latitude;
  final double longitude;
  final String roadName;

  BusRouteStop({
    required this.serviceNo,
    required this.operator,
    required this.direction,
    required this.stopSequence,
    required this.busStopCode,
    required this.latitude,
    required this.longitude,
    required this.roadName,
  });

  factory BusRouteStop.fromJson(Map<String, dynamic> json) {
    return BusRouteStop(
      serviceNo: json['ServiceNo'] ?? '',
      operator: json['Operator'] ?? '',
      direction: json['Direction'] ?? 1,
      stopSequence: json['StopSequence'] ?? 0,
      busStopCode: json['BusStopCode'] ?? '',
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0.0,
      roadName: json['RoadName'] ?? '',
    );
  }
}

/// MRT station with coordinates for map display
class MrtStation {
  final String name;
  final String line;
  final double latitude;
  final double longitude;

  const MrtStation({
    required this.name,
    required this.line,
    required this.latitude,
    required this.longitude,
  });
}

/// Curated list of major Singapore MRT stations with accurate coordinates.
const List<MrtStation> singaporeMrtStations = [
  // North-South Line (NSL)
  MrtStation(name: 'Marina South Pier', line: 'NS', latitude: 1.2713, longitude: 103.8631),
  MrtStation(name: 'Marina Bay', line: 'NS', latitude: 1.2756, longitude: 103.8554),
  MrtStation(name: 'Raffles Place', line: 'NS', latitude: 1.2836, longitude: 103.8512),
  MrtStation(name: 'City Hall', line: 'NS', latitude: 1.2931, longitude: 103.8527),
  MrtStation(name: 'Dhoby Ghaut', line: 'NS', latitude: 1.2985, longitude: 103.8459),
  MrtStation(name: 'Somerset', line: 'NS', latitude: 1.3014, longitude: 103.8401),
  MrtStation(name: 'Orchard', line: 'NS', latitude: 1.3038, longitude: 103.8320),
  MrtStation(name: 'Newton', line: 'NS', latitude: 1.3132, longitude: 103.8384),
  MrtStation(name: 'Novena', line: 'NS', latitude: 1.3204, longitude: 103.8446),
  MrtStation(name: 'Toa Payoh', line: 'NS', latitude: 1.3349, longitude: 103.8504),
  MrtStation(name: 'Bishan', line: 'NS', latitude: 1.3520, longitude: 103.8489),
  MrtStation(name: 'Ang Mo Kio', line: 'NS', latitude: 1.3705, longitude: 103.8495),
  MrtStation(name: 'Khatib', line: 'NS', latitude: 1.4175, longitude: 103.8334),
  MrtStation(name: 'Yishun', line: 'NS', latitude: 1.4293, longitude: 103.8344),
  MrtStation(name: 'Woodlands', line: 'NS', latitude: 1.4370, longitude: 103.7864),
  MrtStation(name: 'Sembawang', line: 'NS', latitude: 1.4496, longitude: 103.8212),

  // East-West Line (EWL)
  MrtStation(name: 'Tanah Merah', line: 'EW', latitude: 1.3274, longitude: 103.9464),
  MrtStation(name: 'Bedok', line: 'EW', latitude: 1.3242, longitude: 103.9291),
  MrtStation(name: 'Eunos', line: 'EW', latitude: 1.3201, longitude: 103.9030),
  MrtStation(name: 'Paya Lebar', line: 'EW', latitude: 1.3176, longitude: 103.8925),
  MrtStation(name: 'Kallang', line: 'EW', latitude: 1.3151, longitude: 103.8720),
  MrtStation(name: 'Bugis', line: 'EW', latitude: 1.3006, longitude: 103.8562),
  MrtStation(name: 'Raffles Place', line: 'EW', latitude: 1.2836, longitude: 103.8512),
  MrtStation(name: 'Tanjong Pagar', line: 'EW', latitude: 1.2779, longitude: 103.8470),
  MrtStation(name: 'Outram Park', line: 'EW', latitude: 1.2804, longitude: 103.8397),
  MrtStation(name: 'Queenstown', line: 'EW', latitude: 1.2949, longitude: 103.8067),
  MrtStation(name: 'Clementi', line: 'EW', latitude: 1.3156, longitude: 103.7650),
  MrtStation(name: 'Jurong East', line: 'EW', latitude: 1.3336, longitude: 103.7420),
  MrtStation(name: 'Boon Lay', line: 'EW', latitude: 1.3390, longitude: 103.7062),
  MrtStation(name: 'Lakeside', line: 'EW', latitude: 1.3449, longitude: 103.7236),

  // Circle Line (CCL)
  MrtStation(name: 'Stadium', line: 'CC', latitude: 1.3068, longitude: 103.8776),
  MrtStation(name: 'Dakota', line: 'CC', latitude: 1.3085, longitude: 103.8900),
  MrtStation(name: 'MacPherson', line: 'CC', latitude: 1.3251, longitude: 103.8917),
  MrtStation(name: 'Tai Seng', line: 'CC', latitude: 1.3358, longitude: 103.8886),
  MrtStation(name: 'Bishan', line: 'CC', latitude: 1.3520, longitude: 103.8489),
  MrtStation(name: 'Caldecott', line: 'CC', latitude: 1.3373, longitude: 103.8406),
  MrtStation(name: 'Botanic Gardens', line: 'CC', latitude: 1.3226, longitude: 103.8156),
  MrtStation(name: 'Holland Village', line: 'CC', latitude: 1.3123, longitude: 103.7971),
  MrtStation(name: 'Kent Ridge', line: 'CC', latitude: 1.2937, longitude: 103.7844),
  MrtStation(name: 'HarbourFront', line: 'CC', latitude: 1.2653, longitude: 103.8063),

  // North East Line (NEL)
  MrtStation(name: 'HarbourFront', line: 'NE', latitude: 1.2653, longitude: 103.8063),
  MrtStation(name: 'Chinatown', line: 'NE', latitude: 1.2838, longitude: 103.8441),
  MrtStation(name: 'Clarke Quay', line: 'NE', latitude: 1.2878, longitude: 103.8466),
  MrtStation(name: 'Little India', line: 'NE', latitude: 1.3044, longitude: 103.8518),
  MrtStation(name: 'Serangoon', line: 'NE', latitude: 1.3503, longitude: 103.8726),
  MrtStation(name: 'Sengkang', line: 'NE', latitude: 1.3923, longitude: 103.8947),
  MrtStation(name: 'Punggol', line: 'NE', latitude: 1.4042, longitude: 103.9022),

  // Downtown Line (DTL)
  MrtStation(name: 'Bukit Panjang', line: 'DT', latitude: 1.3778, longitude: 103.7625),
  MrtStation(name: 'Beauty World', line: 'DT', latitude: 1.3425, longitude: 103.7761),
  MrtStation(name: 'King Albert Park', line: 'DT', latitude: 1.3360, longitude: 103.7842),
  MrtStation(name: 'Botanic Gardens', line: 'DT', latitude: 1.3226, longitude: 103.8156),
  MrtStation(name: 'Promenade', line: 'DT', latitude: 1.3138, longitude: 103.8608),
  MrtStation(name: 'Chinatown', line: 'DT', latitude: 1.2838, longitude: 103.8441),
  MrtStation(name: 'Shenton Way', line: 'DT', latitude: 1.2813, longitude: 103.8540),

  // Thomson-East Coast Line (TEL)
  MrtStation(name: 'Woodlands North', line: 'TE', latitude: 1.4440, longitude: 103.7861),
  MrtStation(name: 'Woodlands South', line: 'TE', latitude: 1.4314, longitude: 103.7881),
  MrtStation(name: 'Upper Thomson', line: 'TE', latitude: 1.3767, longitude: 103.8327),
  MrtStation(name: 'Caldecott', line: 'TE', latitude: 1.3373, longitude: 103.8406),
  MrtStation(name: 'Orchard Boulevard', line: 'TE', latitude: 1.3077, longitude: 103.8274),

  // Changi Branch & LRT
  MrtStation(name: 'Expo', line: 'CG', latitude: 1.3350, longitude: 103.9616),
  MrtStation(name: 'Changi Airport', line: 'CG', latitude: 1.3574, longitude: 103.9887),
  MrtStation(name: 'Sengkang LRT', line: 'LRT', latitude: 1.3923, longitude: 103.8947),
  MrtStation(name: 'Punggol LRT', line: 'LRT', latitude: 1.4042, longitude: 103.9022),
];
