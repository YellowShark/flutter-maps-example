import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

const googleApiKey = "YOUR_GOOGLE_API_KEY";

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({Key? key}) : super(key: key);

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  Location location = Location();
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  void _onMapCreated(GoogleMapController mapController) {
    _controller.complete(mapController);
    _mapController = mapController;
  }

  _checkLocationPermission() async {
    bool locationServiceEnabled = await location.serviceEnabled();
    if (!locationServiceEnabled) {
      locationServiceEnabled = await location.requestService();
      if (!locationServiceEnabled) {
        return;
      }
    }

    PermissionStatus locationForAppStatus = await location.hasPermission();
    if (locationForAppStatus == PermissionStatus.denied) {
      await location.requestPermission();
      locationForAppStatus = await location.hasPermission();
      if (locationForAppStatus != PermissionStatus.granted) {
        return;
      }
    }
    LocationData locationData = await location.getLocation();
    _mapController.moveCamera(CameraUpdate.newLatLng(LatLng(locationData.latitude!, locationData.longitude!)));
  }

  void _addMarker(LatLng position) async {
    if (markers.isEmpty) {
      markers.add(Marker(markerId: const MarkerId("start"), infoWindow: const InfoWindow(title: "Start"), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), position: position));
    } else {
      markers.add(Marker(markerId: const MarkerId("finish"), infoWindow: const InfoWindow(title: "Finish"), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), position: position));
      final points = PolylinePoints();
      final start = PointLatLng(markers.first.position.latitude, markers.first.position.longitude);
      final finish = PointLatLng(markers.last.position.latitude, markers.last.position.longitude);
      final result = await points.getRouteBetweenCoordinates(googleApiKey, start, finish, optimizeWaypoints: true);
      polylineCoordinates.clear();
      if (result.points.isNotEmpty) {
        result.points.forEach((point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      }
      _addPolyLine();
    }
    setState(() {});
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  @override
  initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map page"),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(50.45, 30.52),
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: _onMapCreated,
        markers: markers,
        polylines: Set.of(polylines.values),
        onTap: _addMarker,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            markers.clear();
            polylines.clear();
          });
        },
        child: const Text("Сброс"),
      ),
    );
  }
}