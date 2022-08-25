import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:maps_example/saved_location.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

final colors = [
  Colors.green,
  Colors.orange,
  Colors.yellowAccent,
  Colors.red,
  Colors.blueAccent,
  Colors.pink,
  Colors.purple,
];

class YandexMapPage extends StatefulWidget {
  const YandexMapPage({Key? key}) : super(key: key);

  @override
  State<YandexMapPage> createState() => _YandexMapPageState();
}

class _YandexMapPageState extends State<YandexMapPage> {
  final _location = Location();
  final List<MapObject> _mapObjects = [];
  final _selectedPoints = <Point>[];
  late YandexMapController _controller;
  final MapObjectId _startMapObjectId = const MapObjectId('start_placemark');
  final MapObjectId _endMapObjectId = const MapObjectId('end_placemark');
  final MapObjectId _polylineMapObjectId = const MapObjectId('polyline');
  late final Uint8List _placemarkIcon;
  Point? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yandex Map page"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              // Виджет для отрисовки Яндекс карты
              child: YandexMap(
                mapObjects: _mapObjects, // объекты, которые будут на карте
                onMapCreated: _onMapCreated, // метод, который вызывает при создании. через него мы получаем контроллер
                onMapTap: _onMarkerChanged, // обработчик нажатия на карту
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FloatingActionButton(
              onPressed: () async {
                if (selectedPoint == null) return;
                var resultWithSession = await YandexSearch.searchByPoint(
                  point: selectedPoint!,
                  searchOptions: const SearchOptions(),
                ).result;
                final savedLocation = SavedLocation(resultWithSession.items?.first.name ?? '', selectedPoint!);
                Navigator.pop(context, savedLocation);
              },
              child: const Text("Save"),
            ),
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _mapObjects.clear();
                _selectedPoints.clear();
              });
            },
            child: const Text("Сброс"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMapCreated(YandexMapController controller) {
    _controller = controller;
    _checkLocationPermission();
  }

  _checkLocationPermission() async {
    bool locationServiceEnabled = await _location.serviceEnabled();
    if (!locationServiceEnabled) {
      locationServiceEnabled = await _location.requestService();
      if (!locationServiceEnabled) {
        return;
      }
    }

    PermissionStatus locationForAppStatus = await _location.hasPermission();
    if (locationForAppStatus == PermissionStatus.denied) {
      await _location.requestPermission();
      locationForAppStatus = await _location.hasPermission();
      if (locationForAppStatus != PermissionStatus.granted) {
        return;
      }
    }
    // Получаем текущую локацию
    LocationData locationData = await _location.getLocation();
    // Рисуем точку для отметки на карте
    _placemarkIcon = await _rawPlacemarkImage();
    // Определяем точку с текущей позицией
    final point = Point(latitude: locationData.latitude!, longitude: locationData.longitude!);
    selectedPoint = point;

    final result = await YandexSuggest.getSuggestions(
      text: 'Cafe',
      boundingBox: BoundingBox(
        northEast: point,
        southWest: Point(
          latitude: point.latitude - 5,
          longitude: point.longitude - 5,
        ),
      ),
      suggestOptions: const SuggestOptions(suggestType: SuggestType.geo),
    ).result;

    result.items?.forEach((element) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            element.props.toString(),
          ),
        ),
      );
    });


    // Добавляем маркер
    await _addMarker(point);
  }

  Future _addMarker(Point point) async {
    // Если нет ни одной отметки, то просто ставим отметку на карте
    if (_selectedPoints.isEmpty) {
      _mapObjects.add(
        // PlacemarkMapObject означает отметку на карте в виде обычной точки
        PlacemarkMapObject(
          mapId: _startMapObjectId,
          point: point,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_placemarkIcon),
            ),
          ),
        ),
      );
    } else {
      // Если хотя бы 2 отметки на карте, то стороим между ними маршрут

      // Сначала отметим на карте конечную точку
      _mapObjects.add(
        PlacemarkMapObject(
          mapId: _endMapObjectId,
          point: point,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_placemarkIcon),
            ),
          ),
        ),
      );

      // Теперь рассчитаем путь
      /// Объект `YandexDriving` предназначен для построения маршрута. В его метод `requestRoutes()`
      /// мы передаем точки, которые преобразуем в точки для построения маршрута, где в `requestPointType` мы указываем,
      /// что это точки нашего пути. `DrivingOptions` оставляем по умолчанию. В результате нам приходит список
      /// с несколькими путями, но из него мы выбираем самый первый и наносим точку на карту.
      ///
      final result = await YandexBicycle.requestRoutes(
        points: [_selectedPoints.first, point]
            .map(
              (p) => RequestPoint(
                point: p,
                requestPointType: RequestPointType.wayPoint,
              ),
            )
            .toList(),
        bicycleVehicleType: BicycleVehicleType.scooter,
      ).result;

      var i = 0;
      result.routes?.forEach((route) {
        final id = MapObjectId('polyline$i');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              route.weight.time.text,
            ),
          ),
        );
        _mapObjects.add(
          // PolylineMapObject означает отметку на карте в виде кривой со множеством точек
          PolylineMapObject(
            mapId: id,
            polyline: Polyline(
              points: route.geometry,
            ),
            strokeColor: colors[i % 7],
            strokeWidth: 7.5,
            outlineColor: Colors.yellow[200]!,
            outlineWidth: 2.0,
          ),
        );
        i++;
      });

      // // Добавим на карту кривую с полным путём
      // _mapObjects.add(
      //   // PolylineMapObject означает отметку на карте в виде кривой со множеством точек
      //   PolylineMapObject(
      //     mapId: _polylineMapObjectId,
      //     polyline: Polyline(
      //       points: result.routes?.first.geometry ?? [],
      //     ),
      //     strokeColor: Colors.orange[700]!,
      //     strokeWidth: 7.5,
      //     outlineColor: Colors.yellow[200]!,
      //     outlineWidth: 2.0,
      //   ),
      // );
    }

    // Обновляем экран
    setState(() {
      _selectedPoints.add(point);
    });

    // Двигаем карту к точке
    await _controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point),
        ),
        // Плавные переход к точке
        animation: const MapAnimation(
          duration: 1,
        ));
  }

  Future<Uint8List> _rawPlacemarkImage() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(50, 50);
    final fillPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const radius = 20.0;

    final circleOffset = Offset(size.height / 2, size.width / 2);

    canvas.drawCircle(circleOffset, radius, fillPaint);
    canvas.drawCircle(circleOffset, radius, strokePaint);

    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  void _onMarkerChanged(Point point) async {
    selectedPoint = point;
    setState(() {
      _mapObjects.add(
        // PlacemarkMapObject означает отметку на карте в виде обычной точки
        PlacemarkMapObject(
          mapId: _startMapObjectId,
          point: point,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_placemarkIcon),
            ),
          ),
        ),
      );
    });
    await _controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point),
        ),
        // Плавные переход к точке
        animation: const MapAnimation(
          duration: 1,
        ));
  }
}
