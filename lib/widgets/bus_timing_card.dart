import 'package:flutter/material.dart';
import '../models/bus_stop.dart';

/// Card widget showing bus arrival times for a saved bus stop
class BusTimingCard extends StatelessWidget {
  final BusStop stop;
  final List<BusService> services;
  final VoidCallback onRemove;
  final VoidCallback onRefresh;

  const BusTimingCard({
    super.key,
    required this.stop,
    required this.services,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stop.stopCode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stop.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove stop',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bus services
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('Loading...',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              ...services.map((service) => _BusServiceRow(service: service)),
          ],
        ),
      ),
    );
  }
}

class _BusServiceRow extends StatelessWidget {
  final BusService service;

  const _BusServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Service number badge
          Container(
            width: 42,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _operatorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              service.serviceNo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _operatorColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bus arrival times
          Expanded(child: _ArrivalColumn(label: 'Next', info: service.nextBus)),
          Expanded(child: _ArrivalColumn(label: '2nd', info: service.nextBus2)),
          Expanded(child: _ArrivalColumn(label: '3rd', info: service.nextBus3)),

          // Wheelchair icon
          if (service.nextBus?.isWheelchairAccessible == true ||
              service.nextBus2?.isWheelchairAccessible == true ||
              service.nextBus3?.isWheelchairAccessible == true)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.accessible, size: 18, color: Colors.blue),
            ),
        ],
      ),
    );
  }

  Color get _operatorColor {
    switch (service.operator) {
      case 'SBST':
        return Colors.red;
      case 'SMRT':
        return Colors.deepPurple;
      case 'TTS':
        return Colors.orange;
      case 'GAS':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _ArrivalColumn extends StatelessWidget {
  final String label;
  final BusArrivalInfo? info;

  const _ArrivalColumn({required this.label, required this.info});

  @override
  Widget build(BuildContext context) {
    final mins = info?.minutesUntilArrival;

    String display;
    Color color;

    if (info == null || info!.monitored == 0) {
      display = '-';
      color = Colors.grey;
    } else if (mins == null || mins < 0) {
      display = '-';
      color = Colors.grey;
    } else if (mins == 0) {
      display = 'Arr';
      color = Colors.green;
    } else if (mins <= 3) {
      display = '${mins}m';
      color = Colors.orange.shade700;
    } else {
      display = '${mins}m';
      color = Colors.black87;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          display,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}
