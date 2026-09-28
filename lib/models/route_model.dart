class RouteModel {
  final String id;
  final String title;
  final String distance;
  final String duration;
  final String avgSpeed;
  final String maxSpeed;
  final String movingTime;
  final String stoppedTime;
  final String date;
  final String bike;
  final bool isSavedOffline;

  RouteModel({
    required this.id,
    required this.title,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.movingTime,
    required this.stoppedTime,
    required this.date,
    required this.bike,
    this.isSavedOffline = false,
  });
}