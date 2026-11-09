import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'home_page.dart';

class RouteDetailPage extends StatelessWidget {
  final String routeName;
  final String distance;
  final String duration;
  final String avgSpeed;
  final String maxSpeed;
  final String movingTime;
  final String stoppedTime;
  final String? fuelLiters;
  final List<Map<String, dynamic>> points;
  final bool offlineSaved;

  const RouteDetailPage({
    super.key,
    required this.routeName,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.movingTime,
    required this.stoppedTime,
    this.fuelLiters,
    this.points = const [],
    this.offlineSaved = false,
  });

  List<LatLng> get _path => points
      .map((point) {
        final latitude = (point['latitude'] as num?)?.toDouble();
        final longitude = (point['longitude'] as num?)?.toDouble();
        if (latitude == null ||
            longitude == null ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          return null;
        }
        return LatLng(latitude, longitude);
      })
      .whereType<LatLng>()
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Scaffold(
      appBar: AppBar(
        title: Text(routeName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Container(
            height: 280,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
            ),
            child: path.length < 2
                ? _mapUnavailable()
                : offlineSaved
                ? _offlineMap(path)
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: path.first,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.stravamotos.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: path,
                            strokeWidth: 5,
                            color: HomePage.laranja,
                          ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('© OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Resumo da viagem',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  context,
                  Icons.route_rounded,
                  'Distância',
                  distance,
                  prominent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(context, Icons.timer_outlined, 'Duração', duration),
              ),
            ],
          ),
          if (fuelLiters != null) ...[
            const SizedBox(height: 10),
            _statTile(
              context,
              Icons.local_gas_station_rounded,
              'Combustível estimado',
              fuelLiters!,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(context, Icons.speed_rounded, 'Média', avgSpeed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(context, Icons.bolt_rounded, 'Máxima', maxSpeed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  context,
                  Icons.play_circle_outline,
                  'Em movimento',
                  movingTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  context,
                  Icons.pause_circle_outline,
                  'Parado',
                  stoppedTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapUnavailable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.map_outlined, size: 44, color: HomePage.laranja),
        const SizedBox(height: 10),
        Text(
          points.isEmpty
              ? 'Esta viagem não tem pontos GPS salvos.'
              : 'Não há pontos suficientes para desenhar o trajeto.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF625B57),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (points.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text(
            'Viagens antigas podem não ter o caminho registrado.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _offlineMap(List<LatLng> path) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _OfflinePathPainter(path)),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_pin_rounded,
                  color: HomePage.laranja,
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'TRAJETO OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 12,
          bottom: 10,
          child: Text(
            'Traçado GPS salvo neste aparelho · sem mapa de ruas',
            style: TextStyle(color: Color(0xFF625B57), fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool prominent = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: prominent
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: HomePage.laranja),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF827B77)),
          ),
        ],
      ),
    );
  }
}

class _OfflinePathPainter extends CustomPainter {
  const _OfflinePathPainter(this.points);

  final List<LatLng> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2EEEB),
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFDCD5D0)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLon = points
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLon = points
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);
    final latSpan = maxLat - minLat;
    final lonSpan = maxLon - minLon;
    final span = latSpan > lonSpan ? latSpan : lonSpan;
    final safeSpan = span == 0 ? 0.00001 : span;
    const inset = 28.0;
    final side =
        ((size.width < size.height ? size.width : size.height) - inset * 2)
            .clamp(1.0, double.infinity)
            .toDouble();
    final originX = (size.width - side) / 2;
    final originY = (size.height - side) / 2;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = originX + ((point.longitude - minLon) / safeSpan) * side;
      final y = originY + side - ((point.latitude - minLat) / safeSpan) * side;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = HomePage.laranja
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    void marker(LatLng point, Color color) {
      final x = originX + ((point.longitude - minLon) / safeSpan) * side;
      final y = originY + side - ((point.latitude - minLat) / safeSpan) * side;
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
    }

    marker(points.first, const Color(0xFF3F9D59));
    marker(points.last, HomePage.preto);
  }

  @override
  bool shouldRepaint(covariant _OfflinePathPainter oldDelegate) =>
      oldDelegate.points != points;
}
