import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';
import 'osm_search_field.dart';
import 'osm_map_view.dart';
import 'wide_button.dart';

/// Emplacement du champ de recherche
enum SearchFieldPlacement { overlay, top }

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
  // Options du champ de recherche
  final Color searchFieldBackgroundColor;
  final IconData searchFieldPrefixIcon;
  // Validation
  final bool requiredField;
  final String requiredMessage;
  final String? allowedCountryCode;
  final String? allowedCountryName;
  final String wrongCountryMessage;
  final AutovalidateMode autovalidateMode;
  // Placement du champ
  final SearchFieldPlacement searchFieldPlacement;
  final double topSpacing;
  // Apparence avancée du champ
  final Color searchBorderColor;
  final double searchBorderWidth;
  final BorderRadius? searchBorderRadius;
  final TextStyle? searchTextStyle;
  final InputDecoration? searchDecoration;
  final EdgeInsetsGeometry? searchMargin;
  final EdgeInsetsGeometry? searchPadding;
  final Color? searchHintTextColor;
  // Callbacks
  final void Function(OSMdata address)? onAddressSelected;
  final void Function(LatLng center, Map<String, dynamic>? address)? onLocationChanged;

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
    this.searchFieldBackgroundColor = Colors.white,
    this.searchFieldPrefixIcon = Icons.gps_fixed,
    this.requiredField = false,
    this.requiredMessage = 'Ce champ est requis',
    this.allowedCountryCode,
    this.allowedCountryName,
    this.wrongCountryMessage = "L'adresse n'est pas dans le pays requis",
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.searchFieldPlacement = SearchFieldPlacement.overlay,
    this.topSpacing = 12.0,
    this.searchBorderColor = Colors.blue,
    this.searchBorderWidth = 1.0,
    this.searchBorderRadius,
    this.searchTextStyle,
    this.searchDecoration,
    this.searchMargin,
    this.searchPadding,
    this.searchHintTextColor,
    this.onAddressSelected,
    this.onLocationChanged,
  }) : super(key: key);

  @override
  State<OpenStreetMapSearchAndPickModular> createState() =>
      _OpenStreetMapSearchAndPickModularState();
}

class _OpenStreetMapSearchAndPickModularState
    extends State<OpenStreetMapSearchAndPickModular> {
  late OSMController _osmController;
  late Future<Position?> _locationFuture;
  final _formKey = GlobalKey<FormState>();

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
          child: widget.searchFieldPlacement == SearchFieldPlacement.overlay
              ? Stack(
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
                        onLocationChanged: widget.onLocationChanged,
                        onAddressSelected: widget.onAddressSelected,
                      ),
                    ),
                    // Champ en overlay
                    if (widget.showSearchField)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Form(
                          key: _formKey,
                          child: OSMSearchField(
                            controller: _osmController,
                            hintText: widget.hintText,
                            borderColor: widget.searchBorderColor,
                            borderWidth: widget.searchBorderWidth,
                            borderRadius: widget.searchBorderRadius,
                            textStyle: widget.searchTextStyle,
                            decoration: widget.searchDecoration,
                            margin: widget.searchMargin,
                            padding: widget.searchPadding,
                            backgroundColor: widget.searchFieldBackgroundColor,
                            prefixIcon: widget.searchFieldPrefixIcon,
                            requiredField: widget.requiredField,
                            requiredMessage: widget.requiredMessage,
                            allowedCountryCode: widget.allowedCountryCode,
                            allowedCountryName: widget.allowedCountryName,
                            wrongCountryMessage: widget.wrongCountryMessage,
                            autovalidateMode: widget.autovalidateMode,
                            hintTextColor: widget.searchHintTextColor,
                            onAddressSelected: widget.onAddressSelected,
                            onLocationChanged: widget.onLocationChanged,
                          ),
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
                                if (!widget.showSearchField || _formKey.currentState?.validate() == true) {
                                  final pickedData = await _osmController.getCurrentPickedData();
                                  widget.onPicked(pickedData);
                                }
                              },
                              backgroundColor: widget.buttonColor,
                              foregroundColor: widget.buttonTextColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    if (widget.showSearchField) ...[
                      Padding(
                        padding: EdgeInsets.only(top: widget.topSpacing, left: 12, right: 12),
                        child: Form(
                          key: _formKey,
                          child: OSMSearchField(
                            controller: _osmController,
                            hintText: widget.hintText,
                            borderColor: widget.searchBorderColor,
                            borderWidth: widget.searchBorderWidth,
                            borderRadius: widget.searchBorderRadius,
                            textStyle: widget.searchTextStyle,
                            decoration: widget.searchDecoration,
                            margin: widget.searchMargin,
                            padding: widget.searchPadding,
                            backgroundColor: widget.searchFieldBackgroundColor,
                            prefixIcon: widget.searchFieldPrefixIcon,
                            requiredField: widget.requiredField,
                            requiredMessage: widget.requiredMessage,
                            allowedCountryCode: widget.allowedCountryCode,
                            allowedCountryName: widget.allowedCountryName,
                            wrongCountryMessage: widget.wrongCountryMessage,
                            autovalidateMode: widget.autovalidateMode,
                            hintTextColor: widget.searchHintTextColor,
                            onAddressSelected: widget.onAddressSelected,
                            onLocationChanged: widget.onLocationChanged,
                          ),
                        ),
                      ),
                      SizedBox(height: widget.topSpacing),
                    ],
                    // Carte
                    Expanded(
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
                        onLocationChanged: widget.onLocationChanged,
                        onAddressSelected: widget.onAddressSelected,
                      ),
                    ),
                    if (widget.showPickButton)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: WideButton(
                          widget.buttonText,
                          textStyle: widget.buttonTextStyle,
                          height: widget.buttonHeight,
                          width: widget.buttonWidth,
                          onPressed: () async {
                            if (!widget.showSearchField || _formKey.currentState?.validate() == true) {
                              final pickedData = await _osmController.getCurrentPickedData();
                              widget.onPicked(pickedData);
                            }
                          },
                          backgroundColor: widget.buttonColor,
                          foregroundColor: widget.buttonTextColor,
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
