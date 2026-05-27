import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus_stop.dart';

/// Card widget showing bus arrival times for a saved bus stop.
/// Supports drag-to-reorder when in reorder mode.
class BusTimingCard extends StatelessWidget {
  final BusStop stop;
  final List<BusService> services;
  final VoidCallback onRemove;
  final VoidCallback onRefresh;
  final bool isDragging;

  const BusTimingCard({
    super.key,
    required this.stop,
    required this.services,
    required this.onRemove,
    required this.onRefresh,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isDragging ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDragging
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stop.stopCode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.onPrimaryContainer,
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
                // Share QR button
                IconButton(
                  icon: const Icon(Icons.qr_code, size: 18),
                  onPressed: () => _showQrDialog(context),
                  tooltip: 'Share stop code',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove stop',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),

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
              ...services.map((service) => _BusServiceRow(
                    service: service,
                    onTap: () => _showServiceInfo(context, service),
                  )),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.directions_bus, size: 20),
            const SizedBox(width: 8),
            Text(stop.stopCode),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, size: 120, color: Colors.black),
            const SizedBox(height: 16),
            Text(stop.description,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Bus Stop ${stop.stopCode}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Stop Code'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: stop.stopCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stop code copied!')),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showServiceInfo(BuildContext context, BusService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bus ${service.serviceNo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Operator: ${service.operator}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('At stop: ${stop.stopCode} - ${stop.description}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Tap Search to find this bus route on the map.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BusServiceRow extends StatelessWidget {
  final BusService service;
  final VoidCallback onTap;

  const _BusServiceRow({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Service number badge (tappable)
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
