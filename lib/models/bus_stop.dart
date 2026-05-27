class BusStop {
  final String stopCode;
  final String description;
  final double latitude;
  final double longitude;

  BusStop({
    required this.stopCode,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      stopCode: json['BusStopCode'] ?? '',
      description: json['Description'] ?? '',
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'BusStopCode': stopCode,
        'Description': description,
        'Latitude': latitude,
        'Longitude': longitude,
      };
}

class BusService {
  final String serviceNo;
  final String operator;
  final BusArrivalInfo? nextBus;
  final BusArrivalInfo? nextBus2;
  final BusArrivalInfo? nextBus3;

  BusService({
    required this.serviceNo,
    required this.operator,
    this.nextBus,
    this.nextBus2,
    this.nextBus3,
  });

  factory BusService.fromJson(Map<String, dynamic> json) {
    return BusService(
      serviceNo: json['ServiceNo'] ?? '',
      operator: json['Operator'] ?? '',
      nextBus: json['NextBus'] != null
          ? BusArrivalInfo.fromJson(json['NextBus'])
          : null,
      nextBus2: json['NextBus2'] != null
          ? BusArrivalInfo.fromJson(json['NextBus2'])
          : null,
      nextBus3: json['NextBus3'] != null
          ? BusArrivalInfo.fromJson(json['NextBus3'])
          : null,
    );
  }
}

class BusArrivalInfo {
  final int? estimatedArrivalEpoch; // Unix timestamp
  final int monitored;
  final double? latitude;
  final double? longitude;
  final String load;
  final String feature;
  final String type;

  BusArrivalInfo({
    this.estimatedArrivalEpoch,
    required this.monitored,
    this.latitude,
    this.longitude,
    required this.load,
    required this.feature,
    required this.type,
  });

  factory BusArrivalInfo.fromJson(Map<String, dynamic> json) {
    return BusArrivalInfo(
      estimatedArrivalEpoch: json['EstimatedArrival'] != null
          ? DateTime.parse(json['EstimatedArrival'] as String)
              .millisecondsSinceEpoch
          : null,
      monitored: json['Monitored'] ?? 0,
      latitude: (json['Latitude'] as num?)?.toDouble(),
      longitude: (json['Longitude'] as num?)?.toDouble(),
      load: json['Load'] ?? '',
      feature: json['Feature'] ?? '',
      type: json['Type'] ?? '',
    );
  }

  /// Returns minutes until bus arrival. Null if not available/monitored.
  int? get minutesUntilArrival {
    if (estimatedArrivalEpoch == null || monitored == 0) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = estimatedArrivalEpoch! - now;
    if (diff < 0) return 0;
    return (diff / 60000).round();
  }

  String get loadDescription {
    switch (load) {
      case 'SEA':
        return 'Seats Available';
      case 'SDA':
        return 'Standing Available';
      case 'LSD':
        return 'Limited Standing';
      default:
        return '';
    }
  }

  bool get isWheelchairAccessible => feature == 'WAB';
}
