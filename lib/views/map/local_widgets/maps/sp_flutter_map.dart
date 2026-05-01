import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/views/map/local_widgets/maps/map_types.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_map_controller.dart';
import 'package:storypad/widgets/sp_icons.dart';

typedef SpFlutterMapMarkerBuilder<T> = Widget Function(BuildContext context, SpMapMarker<T> marker);
typedef SpFlutterMapClusterMarkerBuilder<T> = Widget Function(BuildContext context, List<SpMapMarker<T>> markers);

class SpFlutterMap<T> extends StatefulWidget {
  const SpFlutterMap({
    super.key,
    required this.mapController,
    required this.initialCamera,
    required this.mapStyle,
    required this.markers,
    this.onMapTap,
    this.onMarkerTap,
    this.markerBuilder,
    this.clusterMarkerBuilder,
    this.onViewportChanged,
    this.showCurrentLocation = true,
  });

  final SpMapController mapController;
  final SpMapCamera initialCamera;
  final SpMapStyle mapStyle;
  final List<SpMapMarker<T>> markers;
  final ValueChanged<SpLatLng>? onMapTap;
  final ValueChanged<SpMapMarker<T>>? onMarkerTap;
  final SpFlutterMapMarkerBuilder<T>? markerBuilder;
  final SpFlutterMapClusterMarkerBuilder<T>? clusterMarkerBuilder;
  final SpMapViewportChanged? onViewportChanged;
  final bool showCurrentLocation;

  @override
  State<SpFlutterMap<T>> createState() => _SpFlutterMapState<T>();
}

class _SpFlutterMapState<T> extends State<SpFlutterMap<T>> with DebounchedCallback {
  static const double _clusterRadiusPx = 72.0;
  static const double _tileSize = 256.0;
  static const double _minZoom = 3.0;
  static const double _maxZoom = 19.0;

  final MapController _flutterMapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  latlong.LatLng? _currentLocation;
  late double _currentZoom;
  double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialCamera.zoom;
    _attachMapController();
    if (widget.showCurrentLocation) {
      unawaited(_startCurrentLocationTracking());
    }
  }

  @override
  void didUpdateWidget(SpFlutterMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mapController != widget.mapController) {
      oldWidget.mapController.detach();
      _attachMapController();
    }

    if (!oldWidget.showCurrentLocation && widget.showCurrentLocation) {
      unawaited(_startCurrentLocationTracking());
    } else if (oldWidget.showCurrentLocation && !widget.showCurrentLocation) {
      unawaited(_positionSubscription?.cancel());
      _positionSubscription = null;
      _currentLocation = null;
    }
  }

  @override
  void dispose() {
    widget.mapController.detach();
    unawaited(_positionSubscription?.cancel());
    _flutterMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_MapCluster<T>> clusters = _buildClusters();

    return FlutterMap(
      mapController: _flutterMapController,
      options: MapOptions(
        initialCenter: _toLatLng(widget.initialCamera.target),
        initialZoom: widget.initialCamera.zoom,
        onMapReady: () => _notifyViewportChanged(_flutterMapController.camera),
        onTap: widget.onMapTap == null
            ? null
            : (tapPosition, point) {
                widget.onMapTap!(SpLatLng(point.latitude, point.longitude));
              },
        onPositionChanged: (MapCamera camera, bool hasGesture) {
          final double previousZoom = _currentZoom;

          if (camera.zoom.isFinite) {
            _currentZoom = camera.zoom;
          }

          if (camera.rotation.isFinite) {
            _currentRotation = camera.rotation;
          }

          final bool shouldRebuildClusters = (previousZoom - _currentZoom).abs() > 0.0001;
          if (shouldRebuildClusters && mounted) setState(() {});

          if (!mounted) return;

          debouncedCallback(() {
            _notifyViewportChanged(camera);
          }, duration: const Duration(milliseconds: 50));
        },
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: widget.mapStyle.mapTilerUrlTemplate,
          userAgentPackageName: kPackageInfo.packageName,
        ),
        if (_currentLocation != null)
          CircleLayer(
            circles: <CircleMarker<Object>>[
              CircleMarker<Object>(
                point: _currentLocation!,
                radius: 16.0,
                color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
              ),
            ],
          ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _currentLocation!,
                width: 20.0,
                height: 20.0,
                child: const _FlutterMapCurrentLocationMarker(),
              ),
            ],
          ),
        MarkerLayer(markers: clusters.map(_buildMarker).toList()),
      ],
    );
  }

  Future<void> _startCurrentLocationTracking() async {
    if (_positionSubscription != null) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (mounted && lastKnown != null) {
        final latlong.LatLng? lastKnownLatLng = _safeLatLng(lastKnown.latitude, lastKnown.longitude);
        if (lastKnownLatLng == null) return;
        setState(() {
          _currentLocation = lastKnownLatLng;
        });
      }

      final Position currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        final latlong.LatLng? currentLatLng = _safeLatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        if (currentLatLng == null) return;
        setState(() {
          _currentLocation = currentLatLng;
        });
      }

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (Position position) {
              if (!mounted) return;
              final latlong.LatLng? nextLatLng = _safeLatLng(position.latitude, position.longitude);
              if (nextLatLng == null) return;
              setState(() {
                _currentLocation = nextLatLng;
              });
            },
            onError: (_) {},
          );
    } catch (_) {}
  }

  Marker _buildMarker(_MapCluster<T> cluster) {
    if (cluster.markers.length > 1) {
      return Marker(
        point: cluster.position,
        width: 52.0,
        height: 52.0,
        rotate: true,
        child: GestureDetector(
          onTap: () {
            if (!_isFiniteLatLng(cluster.position)) return;

            final double nextZoom = (_safeZoom(_currentZoom) + 2.0).clamp(_minZoom, _maxZoom).toDouble();
            _flutterMapController.moveAndRotate(cluster.position, nextZoom, _safeRotation(_currentRotation));
          },
          child:
              widget.clusterMarkerBuilder?.call(context, cluster.markers) ??
              _FlutterMapClusterMarker(count: cluster.markers.length),
        ),
      );
    }

    final SpMapMarker<T> marker = cluster.markers.single;
    return Marker(
      point: _toLatLng(marker.point),
      width: marker.size.width,
      height: marker.size.height,
      alignment: marker.alignment,
      child: GestureDetector(
        onTap: () => widget.onMarkerTap?.call(marker),
        child: widget.markerBuilder?.call(context, marker) ?? const _FlutterMapDefaultMarker(),
      ),
    );
  }

  List<_MapCluster<T>> _buildClusters() {
    final List<_MapCluster<T>> fixedClusters = widget.markers
        .where((marker) => !marker.clusterable)
        .map((marker) => _MapCluster<T>(markers: <SpMapMarker<T>>[marker], position: _toLatLng(marker.point)))
        .toList();
    final List<SpMapMarker<T>> clusterableMarkers = widget.markers.where((marker) => marker.clusterable).toList();

    final double zoom = _safeZoom(_currentZoom);
    if (zoom >= 18.0) {
      return <_MapCluster<T>>[
        ...fixedClusters,
        ...clusterableMarkers.map(
          (marker) => _MapCluster<T>(markers: <SpMapMarker<T>>[marker], position: _toLatLng(marker.point)),
        ),
      ];
    }

    final List<_MapClusterPoint<T>> points =
        clusterableMarkers
            .map(
              (marker) => _MapClusterPoint<T>(marker: marker, projected: _project(_toLatLng(marker.point), zoom)),
            )
            .toList()
          ..sort((a, b) {
            final int xCompare = a.projected.x.compareTo(b.projected.x);
            if (xCompare != 0) return xCompare;
            return a.projected.y.compareTo(b.projected.y);
          });

    final List<_ClusterAccumulator<T>> accumulators = <_ClusterAccumulator<T>>[];
    for (final _MapClusterPoint<T> point in points) {
      _ClusterAccumulator<T>? best;
      double bestDistanceSquared = _clusterRadiusPx * _clusterRadiusPx;

      for (final _ClusterAccumulator<T> accumulator in accumulators) {
        final double distanceSquared = accumulator.distanceSquaredTo(point.projected);
        if (distanceSquared <= bestDistanceSquared) {
          best = accumulator;
          bestDistanceSquared = distanceSquared;
        }
      }

      if (best == null) {
        accumulators.add(_ClusterAccumulator<T>(marker: point.marker, projected: point.projected));
      } else {
        best.add(point.marker, point.projected);
      }
    }

    return <_MapCluster<T>>[
      ...fixedClusters,
      ...accumulators.map(
        (accumulator) => _MapCluster<T>(
          markers: accumulator.markers,
          position: _unproject(accumulator.centroid, zoom),
        ),
      ),
    ];
  }

  void _attachMapController() {
    widget.mapController.attach(
      zoomBy: _zoomBy,
      animateTo: _animateTo,
      resetRotation: _resetRotation,
    );
  }

  void _notifyViewportChanged(MapCamera camera) {
    final SpMapViewportChanged? onViewportChanged = widget.onViewportChanged;
    if (onViewportChanged == null) return;

    final bounds = camera.visibleBounds;
    onViewportChanged(
      SpMapViewport(
        bounds: SpLatLngBounds(
          south: bounds.south,
          west: bounds.west,
          north: bounds.north,
          east: bounds.east,
        ),
        center: SpLatLng(
          camera.center.latitude,
          camera.center.longitude,
        ),
        zoom: camera.zoom,
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final latlong.LatLng center = _flutterMapController.camera.center;
    if (!_isFiniteLatLng(center)) return;

    final double nextZoom = (_safeZoom(_currentZoom) + delta).clamp(_minZoom, _maxZoom).toDouble();
    _flutterMapController.moveAndRotate(center, nextZoom, _safeRotation(_currentRotation));
  }

  Future<void> _animateTo(
    double latitude,
    double longitude, {
    double? zoom,
    double? bearing,
  }) async {
    final latlong.LatLng? position = _safeLatLng(latitude, longitude);
    if (position == null) return;

    _flutterMapController.moveAndRotate(
      position,
      _safeZoom(zoom ?? _currentZoom),
      _safeRotation(bearing ?? _currentRotation),
    );
  }

  Future<void> _resetRotation() async {
    _flutterMapController.rotate(0.0);
  }

  latlong.LatLng _toLatLng(SpLatLng point) {
    return latlong.LatLng(point.latitude, point.longitude);
  }

  latlong.LatLng? _safeLatLng(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return null;
    if (latitude < -90.0 || latitude > 90.0) return null;
    if (longitude < -180.0 || longitude > 180.0) return null;
    return latlong.LatLng(latitude, longitude);
  }

  bool _isFiniteLatLng(latlong.LatLng point) {
    return point.latitude.isFinite && point.longitude.isFinite;
  }

  double _safeZoom(double zoom) {
    final double fallback = widget.initialCamera.zoom;
    final double base = zoom.isFinite ? zoom : fallback;
    return base.clamp(_minZoom, _maxZoom).toDouble();
  }

  double _safeRotation(double rotation) {
    return rotation.isFinite ? rotation : 0.0;
  }

  _ScreenPoint _project(latlong.LatLng latLng, double zoom) {
    final double safeZoom = _safeZoom(zoom);
    final double latitudeRadians = latLng.latitude * math.pi / 180.0;
    final double sinLatitude = math.sin(latitudeRadians).clamp(-0.9999, 0.9999);
    final double worldSize = _tileSize * math.pow(2.0, safeZoom);
    final double x = (latLng.longitude + 180.0) / 360.0 * worldSize;
    final double y = (0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) * worldSize;
    return _ScreenPoint(x, y);
  }

  latlong.LatLng _unproject(_ScreenPoint point, double zoom) {
    final double safeZoom = _safeZoom(zoom);
    final double worldSize = _tileSize * math.pow(2.0, safeZoom);
    final double longitude = point.x / worldSize * 360.0 - 180.0;
    final double n = math.pi - 2.0 * math.pi * point.y / worldSize;
    final double latitude = math.atan(_sinh(n)) * 180.0 / math.pi;
    return _safeLatLng(latitude, longitude) ?? _toLatLng(widget.initialCamera.target);
  }

  double _sinh(double value) {
    return (math.exp(value) - math.exp(-value)) / 2.0;
  }
}

class _MapCluster<T> {
  const _MapCluster({
    required this.markers,
    required this.position,
  });

  final List<SpMapMarker<T>> markers;
  final latlong.LatLng position;
}

class _MapClusterPoint<T> {
  const _MapClusterPoint({
    required this.marker,
    required this.projected,
  });

  final SpMapMarker<T> marker;
  final _ScreenPoint projected;
}

class _ClusterAccumulator<T> {
  _ClusterAccumulator({
    required SpMapMarker<T> marker,
    required _ScreenPoint projected,
  }) : markers = <SpMapMarker<T>>[marker],
       centroid = projected;

  final List<SpMapMarker<T>> markers;
  _ScreenPoint centroid;

  void add(SpMapMarker<T> marker, _ScreenPoint projected) {
    final int currentLength = markers.length;
    centroid = _ScreenPoint(
      (centroid.x * currentLength + projected.x) / (currentLength + 1),
      (centroid.y * currentLength + projected.y) / (currentLength + 1),
    );
    markers.add(marker);
  }

  double distanceSquaredTo(_ScreenPoint projected) {
    final double dx = centroid.x - projected.x;
    final double dy = centroid.y - projected.y;
    return dx * dx + dy * dy;
  }
}

class _ScreenPoint {
  const _ScreenPoint(this.x, this.y);

  final double x;
  final double y;
}

class _FlutterMapClusterMarker extends StatelessWidget {
  const _FlutterMapClusterMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 3.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14.0,
            offset: const Offset(0.0, 6.0),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 15.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FlutterMapDefaultMarker extends StatelessWidget {
  const _FlutterMapDefaultMarker();

  @override
  Widget build(BuildContext context) {
    return Icon(
      SpIcons.myLocation,
      color: Theme.of(context).colorScheme.primary,
      size: 40.0,
    );
  }
}

class _FlutterMapCurrentLocationMarker extends StatelessWidget {
  const _FlutterMapCurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
    );
  }
}
