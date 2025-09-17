import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';
import 'osm_search_field.dart';
import 'osm_map_view.dart';
import 'wide_button.dart';

/// Version modulaire du widget OpenStreetMapSearchAndPick
/// Utilise les nouveaux composants séparés pour plus de flexibilité
class OpenStreetMapSearchAndPickModular extends StatefulWidget {
  final void Function(PickedData pickedData) onPicked;
  final IconData zoomInIcon;
  final IconData zoomOutIcon;
  final IconData currentLocationIcon;
  final IconData locationPinIcon;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color locationPinIconColor;
  final String locationPinText;
  final TextStyle locationPinTextStyle;
  final String buttonText;
  final String hintText;
  final double buttonHeight;
  final double buttonWidth;
  final TextStyle buttonTextStyle;
  final String baseUri;
  final bool showSearchField;
  final bool showMapControls;
  final bool showLocationPin;
  final bool showPickButton;

  const OpenStreetMapSearchAndPickModular({
    Key? key,
    required this.onPicked,
    this.zoomOutIcon = Icons.zoom_out_map,
    this.zoomInIcon = Icons.zoom_in_map,
    this.currentLocationIcon = Icons.my_location,
    this.buttonColor = Colors.blue,
    this.locationPinIconColor = Colors.blue,
    this.locationPinText = 'Location',
    this.locationPinTextStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
    this.hintText = 'Search Location',
    this.buttonTextStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    this.buttonTextColor = Colors.white,
    this.buttonText = 'Set Current Location',
    this.buttonHeight = 50,
    this.buttonWidth = 200,
    this.baseUri = 'https://nominatim.openstreetmap.org',
    this.locationPinIcon = Icons.location_on,
    this.showSearchField = true,
    this.showMapControls = true,
    this.showLocationPin = true,
    this.showPickButton = true,
  }) : super(key: key);

  @override
  State<OpenStreetMapSearchAndPickModular> createState() =>
      _OpenStreetMapSearchAndPickModularState();
}

class _OpenStreetMapSearchAndPickModularState
    extends State<OpenStreetMapSearchAndPickModular> {
  late OSMController _osmController;
  late Future<Position?> _locationFuture;

  @override
  void initState() {
    super.initState();
    _osmController = OSMController();
    _osmController.baseUri = widget.baseUri;
    _locationFuture = _getCurrentPosition();
  }

  @override
  void dispose() {
    _osmController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }
      
      Position position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      return null;
    }
  }

  void _onCurrentLocationPressed() async {
    try {
      Position? position = await _getCurrentPosition();
      if (position != null) {
        LatLng location = LatLng(position.latitude, position.longitude);
        _osmController.moveToPosition(location);
      }
    } catch (e) {
      // Gérer l'erreur silencieusement ou afficher un message
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        LatLng? initialCenter;
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          initialCenter = LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
        }

        // Initialiser le contrôleur avec la position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _osmController.initialize(initialPosition: initialCenter);
        });

        return SafeArea(
          child: Stack(
            children: [
              // Carte
              Positioned.fill(
                child: OSMMapView(
                  controller: _osmController,
                  initialCenter: initialCenter,
                  showZoomControls: widget.showMapControls,
                  showCurrentLocationButton: widget.showMapControls,
                  showLocationPin: widget.showLocationPin,
                  locationPinText: widget.locationPinText,
                  locationPinTextStyle: widget.locationPinTextStyle,
                  locationPinIcon: widget.locationPinIcon,
                  locationPinIconColor: widget.locationPinIconColor,
                  zoomInIcon: widget.zoomInIcon,
                  zoomOutIcon: widget.zoomOutIcon,
                  currentLocationIcon: widget.currentLocationIcon,
                  buttonColor: widget.buttonColor,
                  buttonTextColor: widget.buttonTextColor,
                  onCurrentLocationPressed: _onCurrentLocationPressed,
                ),
              ),
              
              // Champ de recherche
              if (widget.showSearchField)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OSMSearchField(
                    controller: _osmController,
                    hintText: widget.hintText,
                    borderColor: widget.buttonColor,
                  ),
                ),
              
              // Bouton de sélection
              if (widget.showPickButton)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WideButton(
                        widget.buttonText,
                        textStyle: widget.buttonTextStyle,
                        height: widget.buttonHeight,
                        width: widget.buttonWidth,
                        onPressed: () async {
                          final pickedData = await _osmController.getCurrentPickedData();
                          widget.onPicked(pickedData);
                        },
                        backgroundColor: widget.buttonColor,
                        foregroundColor: widget.buttonTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget combiné simple avec contrôleur exposé
class OSMSearchAndMapWidget extends StatefulWidget {
  final OSMController? controller;
  final LatLng? initialCenter;
  final double initialZoom;
  final String hintText;
  final Color primaryColor;
  final bool showSearchField;
  final bool showMapControls;
  final bool showLocationPin;
  final VoidCallback? onCurrentLocationPressed;
  final void Function(PickedData)? onLocationPicked;

  const OSMSearchAndMapWidget({
    Key? key,
    this.controller,
    this.initialCenter,
    this.initialZoom = 15.0,
    this.hintText = 'Rechercher une adresse...',
    this.primaryColor = Colors.blue,
    this.showSearchField = true,
    this.showMapControls = true,
    this.showLocationPin = true,
    this.onCurrentLocationPressed,
    this.onLocationPicked,
  }) : super(key: key);

  @override
  State<OSMSearchAndMapWidget> createState() => _OSMSearchAndMapWidgetState();
}

class _OSMSearchAndMapWidgetState extends State<OSMSearchAndMapWidget> {
  late OSMController _controller;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isControllerOwned = false;
    } else {
      _controller = OSMController();
      _isControllerOwned = true;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize(initialPosition: widget.initialCenter);
    });
  }

  @override
  void dispose() {
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearchField)
          OSMSearchField(
            controller: _controller,
            hintText: widget.hintText,
            borderColor: widget.primaryColor,
          ),
        Expanded(
          child: OSMMapView(
            controller: _controller,
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            showZoomControls: widget.showMapControls,
            showCurrentLocationButton: widget.showMapControls,
            showLocationPin: widget.showLocationPin,
            buttonColor: widget.primaryColor,
            locationPinIconColor: widget.primaryColor,
            onCurrentLocationPressed: widget.onCurrentLocationPressed,
          ),
        ),
      ],
    );
  }
}
