import 'package:flutter/material.dart';
import 'package:maps_example/saved_location.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

final locations = <SavedLocation>[];

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
      ),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(
            locations[i].name,
          ),
          subtitle: Text(locations[i].point.props.toString()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = (await Navigator.pushNamed(context, 'map')) as SavedLocation?;
          if (result == null) return;
          locations.add(result);
          setState(() {});
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
