import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Contrôleur pour gérer la communication entre le champ de recherche et la carte
class OSMController extends ChangeNotifier {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<OSMdata> _searchOptions = <OSMdata>[];
  Timer? _debounce;
  final http.Client _client = http.Client();
  String _baseUri = 'https://nominatim.openstreetmap.org';
  
  // Dernières informations obtenues par reverse geocoding
  Map<String, dynamic>? _lastAddress;
  String? _lastCountryCode;
  String? _lastCountryName;
  
  // Getters
  MapController get mapController => _mapController;
  TextEditingController get searchController => _searchController;
  FocusNode get focusNode => _focusNode;
  List<OSMdata> get searchOptions => _searchOptions;
  String get baseUri => _baseUri;
  Map<String, dynamic>? get lastAddress => _lastAddress;
  String? get lastCountryCode => _lastCountryCode;
  String? get lastCountryName => _lastCountryName;
  
  // Setters
  set baseUri(String uri) {
    _baseUri = uri;
  }
  
  /// Initialise le contrôleur avec une position initiale
  void initialize({LatLng? initialPosition}) {
    if (initialPosition != null) {
      _mapController.move(initialPosition, 15.0);
      _updateSearchTextFromCoordinates(initialPosition.latitude, initialPosition.longitude);
    }
    
    // Écouter les mouvements de la carte
    _mapController.mapEventStream.listen((event) async {
      if (event is MapEventMoveEnd) {
        await _updateSearchTextFromCoordinates(
          event.camera.center.latitude,
          event.camera.center.longitude,
        );
      }
    });
  }
  
  /// Met à jour le texte de recherche basé sur les coordonnées
  Future<void> _updateSearchTextFromCoordinates(double latitude, double longitude) async {
    try {
      String url = '$_baseUri/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';
      var response = await _client.get(Uri.parse(url));
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;
      
      _searchController.text = decodedResponse['display_name'] ?? "Position actuelle";
      // Stocker les infos d'adresse et pays
      final address = (decodedResponse['address'] as Map?)?.cast<String, dynamic>();
      _lastAddress = address;
      _lastCountryCode = address != null ? (address['country_code'] as String?)?.toUpperCase() : null;
      _lastCountryName = address != null ? address['country'] as String? : null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de l\'adresse: $e');
      }
    }
  }
  
  /// Effectue une recherche basée sur le texte
  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      _searchOptions.clear();
      notifyListeners();
      return;
    }
    
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      try {
        String url = '$_baseUri/search?q=$query&format=json&polygon_geojson=1&addressdetails=1';
        var response = await _client.get(Uri.parse(url));
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        
        _searchOptions = decodedResponse
            .map((e) => OSMdata(
                  displayname: e['display_name'],
                  lat: double.parse(e['lat']),
                  lon: double.parse(e['lon']),
                ))
            .toList();
        
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors de la recherche: $e');
        }
        _searchOptions.clear();
        notifyListeners();
      }
    });
  }
  
  /// Sélectionne une location depuis les résultats de recherche
  void selectLocation(OSMdata location) {
    _mapController.move(LatLng(location.lat, location.lon), 15.0);
    _searchController.text = location.displayname;
    _focusNode.unfocus();
    _searchOptions.clear();
    // Déclencher un reverse geocoding pour mettre à jour lastAddress/pays
    _updateSearchTextFromCoordinates(location.lat, location.lon);
    notifyListeners();
  }
  
  /// Déplace la carte vers une position spécifique
  void moveToPosition(LatLng position, {double? zoom}) {
    _mapController.move(position, zoom ?? _mapController.zoom);
  }
  
  /// Zoom avant
  void zoomIn() {
    _mapController.move(_mapController.center, _mapController.zoom + 1);
  }
  
  /// Zoom arrière
  void zoomOut() {
    _mapController.move(_mapController.center, _mapController.zoom - 1);
  }
  
  /// Récupère les données de la position actuelle
  Future<PickedData> getCurrentPickedData() async {
    LatLong center = LatLong(_mapController.center.latitude, _mapController.center.longitude);
    
    try {
      String url = '$_baseUri/reverse?format=json&lat=${_mapController.center.latitude}&lon=${_mapController.center.longitude}&zoom=18&addressdetails=1';
      var response = await _client.get(Uri.parse(url));
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;
      
      String displayName = decodedResponse['display_name'] ?? 'Position inconnue';
      Map<String, dynamic> address = (decodedResponse['address'] as Map?)?.cast<String, dynamic>() ?? {};
      // Mettre à jour le cache
      _lastAddress = address;
      _lastCountryCode = (address['country_code'] as String?)?.toUpperCase();
      _lastCountryName = address['country'] as String?;
      
      return PickedData(center, displayName, address);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des données: $e');
      }
      return PickedData(center, 'Position inconnue', {});
    }
  }
  
  /// Nettoie les ressources
  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _client.close();
    super.dispose();
  }
}

/// Classe pour les données OSM
class OSMdata {
  final String displayname;
  final double lat;
  final double lon;
  
  OSMdata({required this.displayname, required this.lat, required this.lon});
  
  @override
  String toString() {
    return '$displayname, $lat, $lon';
  }
  
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OSMdata && other.displayname == displayname;
  }
  
  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

/// Classe pour les coordonnées
class LatLong {
  final double latitude;
  final double longitude;
  const LatLong(this.latitude, this.longitude);
}

/// Classe pour les données sélectionnées
class PickedData {
  final LatLong latLong;
  final String addressName;
  final Map<String, dynamic> address;
  
  PickedData(this.latLong, this.addressName, this.address);
}
