//import 'dart:html';
//import 'package:flutter/material.dart';
//import 'package:google_maps/google_maps.dart';
//import 'dart:ui' as ui;
//
//class StreetMap extends StatelessWidget {
//  final latitudePassed;
//  final longitudePassed;
//   const StreetMap({Key? key})
//      : super(key: key);
//
//
//
//  @override
//  Widget build(BuildContext context) {
//    String htmlId = "8";
//
//    // ignore: undefined_prefixed_name
//    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
//      final myLatlng = LatLng(double.parse(latitudePassed), double.parse(longitudePassed));
//      print("The Latitude is: " + latitudePassed);
//      final mapOptions = MapOptions()
//        ..zoom = 19
//        ..center = myLatlng;
//
//      final elem = DivElement()
//        ..id = htmlId
//        ..style.width = "100%"
//        ..style.height = "100%"
//        ..style.border = 'none';
//
//      final map = GMap(elem, mapOptions);
//
//      final marker = Marker(MarkerOptions()
//        ..position = myLatlng
//        ..map = map
//        ..title = 'caller');
//
//      final infoWindow = InfoWindow(InfoWindowOptions()..content = 'caller');
//      marker.onClick.listen((event) => infoWindow.open(map, marker));
//      return elem;
//    });
//
//    return HtmlElementView(viewType: htmlId);
//  }
//}
