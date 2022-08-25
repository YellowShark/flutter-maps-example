import 'package:flutter/material.dart';
import 'package:maps_example/list_page.dart';
import 'package:maps_example/yandex_map_page.dart';

import 'google_map_page.dart';

const googleApiKey = "AIzaSyBLR3iEOULZSNtuNNhhGLIpTASvwxvVLg4";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        'list': (_) => const ListPage(),
        'map': (_) => const YandexMapPage(),
      },
      initialRoute: 'list',
      //home: const YandexMapPage(),
    );
  }
}
