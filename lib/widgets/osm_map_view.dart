import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';

/// Widget de carte indépendant pour OpenStreetMap
class OSMMapView extends StatelessWidget {
  final OSMController controller;
  final double? width;
  final double? height;
  final LatLng? initialCenter;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;
  final bool showZoomControls;
  final bool showCurrentLocationButton;
  final bool showLocationPin;
  final String locationPinText;
  final TextStyle locationPinTextStyle;
  final IconData locationPinIcon;
  final Color locationPinIconColor;
  final IconData zoomInIcon;
  final IconData zoomOutIcon;
  final IconData currentLocationIcon;
  final Color buttonColor;
  final Color buttonTextColor;
  final String tileLayerUrl;
  final List<String> tileLayerSubdomains;
  final EdgeInsetsGeometry? controlsMargin;
  final AlignmentGeometry? controlsAlignment;
  final VoidCallback? onCurrentLocationPressed;

  const OSMMapView({
    Key? key,
    required this.controller,
    this.width,
    this.height,
    this.initialCenter,
    this.initialZoom = 15.0,
    this.maxZoom = 18.0,
    this.minZoom = 6.0,
    this.showZoomControls = true,
    this.showCurrentLocationButton = true,
    this.showLocationPin = true,
    this.locationPinText = 'Location',
    this.locationPinTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
    this.locationPinIcon = Icons.location_on,
    this.locationPinIconColor = Colors.blue,
    this.zoomInIcon = Icons.zoom_in_map,
    this.zoomOutIcon = Icons.zoom_out_map,
    this.currentLocationIcon = Icons.my_location,
    this.buttonColor = Colors.blue,
    this.buttonTextColor = Colors.white,
    this.tileLayerUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    this.tileLayerSubdomains = const ['a', 'b', 'c'],
    this.controlsMargin,
    this.controlsAlignment,
    this.onCurrentLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // S'assurer que les mouvements de la carte mettront à jour l'adresse
    controller.ensureMapListener();
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          _buildMap(),
          if (showLocationPin) _buildLocationPin(),
          if (showZoomControls || showCurrentLocationButton) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        center: initialCenter,
        zoom: initialZoom,
        maxZoom: maxZoom,
        minZoom: minZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: tileLayerUrl,
          subdomains: tileLayerSubdomains,
        ),
      ],
    );
  }

  Widget _buildLocationPin() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locationPinText,
                style: locationPinTextStyle,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Icon(
                  locationPinIcon,
                  size: 50,
                  color: locationPinIconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showZoomControls) ...[
            _buildControlButton(
              icon: zoomInIcon,
              onPressed: () => controller.zoomIn(),
              heroTag: 'zoom_in',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: zoomOutIcon,
              onPressed: () => controller.zoomOut(),
              heroTag: 'zoom_out',
            ),
            const SizedBox(height: 8),
          ],
          if (showCurrentLocationButton)
            _buildControlButton(
              icon: currentLocationIcon,
              onPressed: onCurrentLocationPressed ?? () {},
              heroTag: 'current_location',
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: buttonColor,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: buttonTextColor,
        size: 20,
      ),
    );
  }
}

/// Version personnalisable de la carte avec plus d'options
class OSMMapViewCustom extends StatelessWidget {
  final OSMController controller;
  final Widget? customLocationPin;
  final List<Widget>? customControls;
  final List<Widget>? mapLayers;
  final MapOptions? mapOptions;
  final Widget Function(BuildContext context, OSMController controller)? overlayBuilder;

  const OSMMapViewCustom({
    Key? key,
    required this.controller,
    this.customLocationPin,
    this.customControls,
    this.mapLayers,
    this.mapOptions,
    this.overlayBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: controller.mapController,
          options: mapOptions ??
              MapOptions(
                center: const LatLng(48.8566, 2.3522), // Paris par défaut
                zoom: 15.0,
                maxZoom: 18.0,
                minZoom: 6.0,
              ),
          children: mapLayers ??
              [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
              ],
        ),
        if (customLocationPin != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(child: customLocationPin!),
            ),
          ),
        if (customControls != null) ...customControls!,
        if (overlayBuilder != null) overlayBuilder!(context, controller),
      ],
    );
  }
}

/// Widget simple pour afficher juste la carte sans contrôles
class OSMMapViewSimple extends StatelessWidget {
  final OSMController controller;
  final LatLng? center;
  final double zoom;
  final bool interactive;

  const OSMMapViewSimple({
    Key? key,
    required this.controller,
    this.center,
    this.zoom = 15.0,
    this.interactive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        center: center,
        zoom: zoom,
        interactiveFlags: interactive
            ? InteractiveFlag.all
            : InteractiveFlag.none,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
      ],
    );
  }
}
