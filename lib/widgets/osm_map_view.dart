import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';

/// Widget de carte indépendant pour OpenStreetMap
class OSMMapView extends StatefulWidget {
  final OSMController controller;
  final double? width;
  final double? height;
  final LatLng? initialCenter;
  final String? initialCountry; // ISO2, ex: 'FR'
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
  final void Function(LatLng center, Map<String, dynamic>? address)? onLocationChanged;
  final void Function(OSMdata address)? onAddressSelected;

  const OSMMapView({
    Key? key,
    required this.controller,
    this.width,
    this.height,
    this.initialCenter,
    this.initialCountry,
    this.initialZoom = 15.0,
    this.maxZoom = 18.0,
    this.minZoom = 2.0,
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
    this.tileLayerUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    // OSM recommendation: avoid subdomains
    this.tileLayerSubdomains = const [],
    this.controlsMargin,
    this.controlsAlignment,
    this.onCurrentLocationPressed,
    this.onLocationChanged,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  State<OSMMapView> createState() => _OSMMapViewState();
}

class _OSMMapViewState extends State<OSMMapView> {
  void _onControllerLocationChanged(LatLng c, Map<String, dynamic>? a) {
    widget.onLocationChanged?.call(c, a);
  }

  void _onControllerAddressSelected(OSMdata d) {
    widget.onAddressSelected?.call(d);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.ensureMapListener();
    widget.controller.addLocationChangedListener(_onControllerLocationChanged);
    widget.controller.addAddressSelectedListener(_onControllerAddressSelected);
    // Si un pays initial est fourni, ajuste la carte après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCountry != null && widget.initialCountry!.trim().isNotEmpty) {
        widget.controller.moveToCountry(widget.initialCountry!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant OSMMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeLocationChangedListener(_onControllerLocationChanged);
      oldWidget.controller.removeAddressSelectedListener(_onControllerAddressSelected);
      widget.controller.ensureMapListener();
      widget.controller.addLocationChangedListener(_onControllerLocationChanged);
      widget.controller.addAddressSelectedListener(_onControllerAddressSelected);
    }
    if (oldWidget.initialCountry != widget.initialCountry &&
        widget.initialCountry != null && widget.initialCountry!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.moveToCountry(widget.initialCountry!);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeLocationChangedListener(_onControllerLocationChanged);
    widget.controller.removeAddressSelectedListener(_onControllerAddressSelected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // S'assurer que les mouvements de la carte mettront à jour l'adresse
    widget.controller.ensureMapListener();
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          _buildMap(),
          if (widget.showLocationPin) _buildLocationPin(),
          if (widget.showZoomControls || widget.showCurrentLocationButton) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: widget.controller.mapController,
      options: MapOptions(
        center: widget.initialCenter,
        zoom: widget.initialZoom,
        maxZoom: widget.maxZoom,
        minZoom: widget.minZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: widget.tileLayerUrl,
          subdomains: widget.tileLayerSubdomains,
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
                widget.locationPinText,
                style: widget.locationPinTextStyle,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Icon(
                  widget.locationPinIcon,
                  size: 50,
                  color: widget.locationPinIconColor,
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
          if (widget.showZoomControls) ...[
            _buildControlButton(
              icon: widget.zoomInIcon,
              onPressed: () => widget.controller.zoomIn(),
              heroTag: 'zoom_in',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: widget.zoomOutIcon,
              onPressed: () => widget.controller.zoomOut(),
              heroTag: 'zoom_out',
            ),
            const SizedBox(height: 8),
          ],
          if (widget.showCurrentLocationButton)
            _buildControlButton(
              icon: widget.currentLocationIcon,
              onPressed: widget.onCurrentLocationPressed ?? () {},
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
      backgroundColor: widget.buttonColor,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: widget.buttonTextColor,
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
                minZoom: 2.0,
              ),
          children: mapLayers ??
              [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const [],
        ),
      ],
    );
  }
}
