import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_in_flutter/permissions_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'locations.dart' as locations;

Future main() async {
  bool isGranted = false;

  while (!isGranted) {
    isGranted = await PermissionsService().requestLocationPermission();
  }

  if (isGranted) {
    await runApp(MyApp());
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> _markers = {};
  Future<void> _onMapCreated(GoogleMapController controller) async {
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Google Office Locations'),
            backgroundColor: Colors.green[700],
          ),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: const LatLng(0, 0),
              zoom: 2,
            ),
            markers: _markers.values.toSet(),
          ),
        ),
      );
}

void getPermission() async {
  try {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location);
    if (permission.value != 3) {
      //PermissionStatus.granted
      ServiceStatus serviceStatus = await PermissionHandler()
          .checkServiceStatus(PermissionGroup.location);
      if (serviceStatus.value != 4) {
        //ServiceStatus.enabled
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.location]);

        var values = permissions.values;
        if (values != null && values.isNotEmpty) {
          for (var value in values) {
            if (value == PermissionStatus.granted) {
              await runApp(MyApp());
              break;
            } else {
              await debugPrint("No permission granted!");
            }
          }
        }
        await debugPrint("permissions: $permissions");
      }
    }
  } catch (e, s) {
    debugPrint("Error: $e, StackTrace: $s");
  }
}
