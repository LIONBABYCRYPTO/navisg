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
