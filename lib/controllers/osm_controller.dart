import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;

/// Contrôleur pour gérer la communication entre le champ de recherche et la carte
class OSMController extends ChangeNotifier {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<OSMdata> _searchOptions = <OSMdata>[];
  Timer? _debounce;
  final http.Client _client = http.Client();
  String _baseUri = 'https://nominatim.openstreetmap.org';
  
  // Nominatim usage policy
  String? _userAgent; // Recommandé: NomApp/Version (contact@email)
  String? _email; // recommandé par Nominatim
  Duration _minReverseInterval = const Duration(milliseconds: 1500);
  double _minReverseMoveMeters = 25.0;
  DateTime? _lastReverseAt;
  LatLng? _lastReverseLatLng;
  bool _mapListenerAttached = false;
  
  // Dernières informations obtenues par reverse geocoding
  Map<String, dynamic>? _lastAddress;
  String? _lastCountryCode;
  String? _lastCountryName;
  LatLng? _lastCenter;

  // Listeners
  final List<void Function(LatLng center, Map<String, dynamic>? address)> _locationChangedListeners = [];
  final List<void Function(OSMdata location)> _addressSelectedListeners = [];
  
  // Getters
  MapController get mapController => _mapController;
  TextEditingController get searchController => _searchController;
  FocusNode get focusNode => _focusNode;
  List<OSMdata> get searchOptions => _searchOptions;
  String get baseUri => _baseUri;
  Map<String, dynamic>? get lastAddress => _lastAddress;
  String? get lastCountryCode => _lastCountryCode;
  String? get lastCountryName => _lastCountryName;
  String? get userAgent => _userAgent;
  String? get email => _email;
  Duration get minReverseInterval => _minReverseInterval;
  double get minReverseMoveMeters => _minReverseMoveMeters;
  LatLng? get lastCenter => _lastCenter;
  
  // Setters
  set baseUri(String uri) {
    _baseUri = uri;
  }

  // API listeners
  void addLocationChangedListener(void Function(LatLng center, Map<String, dynamic>? address) listener) {
    _locationChangedListeners.add(listener);
  }

  void removeLocationChangedListener(void Function(LatLng center, Map<String, dynamic>? address) listener) {
    _locationChangedListeners.remove(listener);
  }

  void addAddressSelectedListener(void Function(OSMdata location) listener) {
    _addressSelectedListeners.add(listener);
  }

  void removeAddressSelectedListener(void Function(OSMdata location) listener) {
    _addressSelectedListeners.remove(listener);
  }
  set userAgent(String? ua) => _userAgent = ua;
  set email(String? em) => _email = em;
  set minReverseInterval(Duration d) => _minReverseInterval = d;
  set minReverseMoveMeters(double m) => _minReverseMoveMeters = m;
  
  /// Initialise le contrôleur avec une position initiale
  void initialize({LatLng? initialPosition}) {
    if (initialPosition != null) {
      _mapController.move(initialPosition, 15.0);
      _updateSearchTextFromCoordinates(initialPosition.latitude, initialPosition.longitude, force: true);
    }
    _attachMapMoveListener();
  }

  void _attachMapMoveListener() {
    if (_mapListenerAttached) return;
    _mapListenerAttached = true;
    _mapController.mapEventStream.listen((event) async {
      if (event is MapEventMoveEnd) {
        await _updateSearchTextFromCoordinates(
          event.camera.center.latitude,
          event.camera.center.longitude,
        );
      }
    });
  }

  /// Rendre public l'attachement du listener carte, idempotent
  void ensureMapListener() {
    _attachMapMoveListener();
  }
  
  /// Met à jour le texte de recherche basé sur les coordonnées
  Future<void> _updateSearchTextFromCoordinates(double latitude, double longitude, {bool force = false}) async {
    try {
      // Throttle + distance filter
      final now = DateTime.now();
      final current = LatLng(latitude, longitude);
      if (!force) {
        if (_lastReverseAt != null && now.difference(_lastReverseAt!) < _minReverseInterval) {
          return; // trop fréquent
        }
        if (_lastReverseLatLng != null) {
          final dist = const Distance().as(LengthUnit.Meter, _lastReverseLatLng!, current);
          if (dist < _minReverseMoveMeters) {
            return; // mouvement trop petit
          }
        }
      }

      _lastReverseAt = now;
      _lastReverseLatLng = current;
      _lastCenter = current;

      String url = '$_baseUri/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';
      if (_email != null && _email!.isNotEmpty) {
        url = '$url&email=${Uri.encodeComponent(_email!)}';
      }
      var response = await _client.get(
        Uri.parse(url),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 429) {
        // Simple backoff
        await Future.delayed(const Duration(seconds: 2));
        response = await _client.get(Uri.parse(url), headers: _buildHeaders());
      }
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;
      
      _searchController.text = decodedResponse['display_name'] ?? "Position actuelle";
      // Stocker les infos d'adresse et pays
      final address = (decodedResponse['address'] as Map?)?.cast<String, dynamic>();
      _lastAddress = address;
      _lastCountryCode = address != null ? (address['country_code'] as String?)?.toUpperCase() : null;
      _lastCountryName = address != null ? address['country'] as String? : null;
      notifyListeners();
      // Notifier listeners de changement de position
      for (final l in _locationChangedListeners) {
        try { l(current, address); } catch (_) {}
      }
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
        String url = '$_baseUri/search?q=$query&format=json&polygon_geojson=1&addressdetails=1&limit=10';
        if (_email != null && _email!.isNotEmpty) {
          url = '$url&email=${Uri.encodeComponent(_email!)}';
        }
        var response = await _client.get(Uri.parse(url), headers: _buildHeaders());
        if (response.statusCode == 429) {
          await Future.delayed(const Duration(seconds: 2));
          response = await _client.get(Uri.parse(url), headers: _buildHeaders());
        }
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
    _updateSearchTextFromCoordinates(location.lat, location.lon, force: true);
    notifyListeners();
    // Notifier écouteurs d'adresse choisie
    for (final l in _addressSelectedListeners) {
      try { l(location); } catch (_) {}
    }
  }
  
  /// Déplace la carte vers une position spécifique
  void moveToPosition(LatLng position, {double? zoom}) {
    _mapController.move(position, zoom ?? _mapController.zoom);
  }

  /// Déplace et ajuste la carte pour afficher entièrement un pays donné par son code ISO2 (ex: 'FR')
  Future<void> moveToCountry(String iso2, {EdgeInsets padding = const EdgeInsets.all(16)}) async {
    if (iso2.trim().isEmpty) return;
    final code = iso2.trim().toLowerCase();
    try {
      // Requête Nominatim pour récupérer la bounding box du pays
      // Ajoute un terme de recherche pour stabiliser le résultat et filtre par pays
      // countrycodes restreint aux codes ISO2, limit=5 pour choisir le meilleur résultat
      String url = '$_baseUri/search?format=json&limit=5&addressdetails=0&polygon_geojson=0&countrycodes=$code&q=$code';
      if (_email != null && _email!.isNotEmpty) {
        url = '$url&email=${Uri.encodeComponent(_email!)}';
      }
      var response = await _client.get(Uri.parse(url), headers: _buildHeaders());
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        response = await _client.get(Uri.parse(url), headers: _buildHeaders());
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List && decoded.isNotEmpty) {
        // Choisir un résultat correspondant à la frontière administrative (pays) si possible
        Map first = decoded.first as Map;
        Map? best;
        for (final e in decoded) {
          if (e is Map) {
            final cls = e['class'];
            final type = e['type'];
            if (cls == 'boundary' && type == 'administrative') {
              best = e;
              break;
            }
          }
        }
        final result = best ?? first;
        final bbox = (result['boundingbox'] as List?)?.cast<String>();
        if (bbox != null && bbox.length == 4) {
          // Nominatim renvoie [south, north, west, east]
          final south = double.tryParse(bbox[0]);
          final north = double.tryParse(bbox[1]);
          final west = double.tryParse(bbox[2]);
          final east = double.tryParse(bbox[3]);
          if (south != null && north != null && west != null && east != null) {
            final bounds = LatLngBounds(LatLng(south, west), LatLng(north, east));
            _fitBounds(bounds, padding: padding);
            return;
          }
        }
        // Fallback: centrer sur le point si fourni
        final lat = double.tryParse(result['lat']?.toString() ?? '');
        final lon = double.tryParse(result['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          _mapController.move(LatLng(lat, lon), 6.0);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur moveToCountry($iso2): $e');
      }
    }
  }

  /// Ajuste la caméra pour faire rentrer les bounds visibles avec padding
  void _fitBounds(LatLngBounds bounds, {EdgeInsets padding = const EdgeInsets.all(16)}) {
    try {
      // flutter_map v4+ API
      _mapController.fitCamera(
        fm.CameraFit.bounds(
          bounds: bounds,
          padding: padding,
        ),
      );
    } catch (_) {
      // Fallback si fitCamera indisponible: se centrer approximativement
      final center = LatLng(
        (bounds.north + bounds.south) / 2,
        (bounds.east + bounds.west) / 2,
      );
      _mapController.move(center, 5.0);
    }
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
      if (_email != null && _email!.isNotEmpty) {
        url = '$url&email=${Uri.encodeComponent(_email!)}';
      }
      var response = await _client.get(Uri.parse(url), headers: _buildHeaders());
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        response = await _client.get(Uri.parse(url), headers: _buildHeaders());
      }
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

Map<String, String> _defaultHeaders(String? userAgent) {
  return {
    if (userAgent != null && userAgent.isNotEmpty) 'User-Agent': userAgent,
  };
}

extension on OSMController {
  Map<String, String> _buildHeaders() {
    return _defaultHeaders(_userAgent);
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
