import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';

/// Widget de champ de recherche indépendant pour OpenStreetMap
class OSMSearchField extends StatelessWidget {
  final OSMController controller;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final int maxSuggestions;
  final Widget Function(BuildContext context, OSMdata suggestion, VoidCallback onTap)? suggestionBuilder;
  final bool showSuggestions;
  final double? maxHeight;
  final Color backgroundColor;
  final IconData prefixIcon;
  final bool requiredField;
  final String requiredMessage;
  final String? allowedCountryCode; // ex: 'FR'
  final String? allowedCountryName; // ex: 'France' (fallback si code non fourni)
  final String wrongCountryMessage; // message si pas dans le bon pays
  final AutovalidateMode autovalidateMode;
  final FormFieldValidator<String>? validator;
  final Color? hintTextColor;
  final void Function(OSMdata address)? onAddressSelected;
  final void Function(LatLng center, Map<String, dynamic>? address)? onLocationChanged;

  const OSMSearchField({
    Key? key,
    required this.controller,
    this.hintText = 'Rechercher une adresse...',
    this.decoration,
    this.textStyle,
    this.borderColor = Colors.blue,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.margin,
    this.padding,
    this.maxSuggestions = 5,
    this.suggestionBuilder,
    this.showSuggestions = true,
    this.maxHeight,
    this.backgroundColor = Colors.white,
    this.prefixIcon = Icons.gps_fixed,
    this.requiredField = false,
    this.requiredMessage = 'Ce champ est requis',
    this.allowedCountryCode,
    this.allowedCountryName,
    this.wrongCountryMessage = "L'adresse n'est pas dans le pays requis",
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.validator,
    this.hintTextColor,
    this.onAddressSelected,
    this.onLocationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(15),
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      child: Material(
        elevation: 0,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OSMFieldListeners(controller: controller, onLocationChanged: onLocationChanged),
              _buildSearchField(),
              if (showSuggestions) _buildSuggestionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    OutlineInputBorder inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: borderWidth),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
    
    OutlineInputBorder inputFocusBorder = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: borderWidth + 1),
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );

    // AnimatedBuilder pour rafraîchir la validation lorsque la carte bouge
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return TextFormField(
          controller: controller.searchController,
          focusNode: controller.focusNode,
          style: textStyle,
          autovalidateMode: autovalidateMode,
          validator: validator ?? (value) {
            final text = value?.trim() ?? '';
            if (requiredField && text.isEmpty) {
              return requiredMessage;
            }
            // Validation du pays si demandé
            final cc = controller.lastCountryCode;
            final cn = controller.lastCountryName;
            if (allowedCountryCode != null && (cc == null || cc.toUpperCase() != allowedCountryCode!.toUpperCase())) {
              // Si un nom est fourni, le montrer dans le message
              final expected = allowedCountryName ?? allowedCountryCode;
              return "$wrongCountryMessage (${expected})";
            }
            if (allowedCountryCode == null && allowedCountryName != null) {
              if (cn == null || cn.toLowerCase() != allowedCountryName!.toLowerCase()) {
                return "$wrongCountryMessage (${allowedCountryName})";
              }
            }
            return null;
          },
          decoration: decoration ??
              InputDecoration(
                hintText: hintText,
                hintStyle: hintTextColor != null ? TextStyle(color: hintTextColor) : null,
                border: inputBorder,
                focusedBorder: inputFocusBorder,
                enabledBorder: inputBorder,
                prefixIcon: Icon(prefixIcon, color: borderColor),
                suffixIcon: AnimatedBuilder(
                  animation: controller.searchController,
                  builder: (context, child) {
                    return controller.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: borderColor),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.searchLocation('');
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
          onChanged: (value) {
            controller.searchLocation(value);
          },
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.searchOptions.isEmpty) {
          return const SizedBox.shrink();
        }

        final suggestions = controller.searchOptions.take(maxSuggestions).toList();

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              
              if (suggestionBuilder != null) {
                return suggestionBuilder!(
                  context,
                  suggestion,
                  () => controller.selectLocation(suggestion),
                );
              }

              return _buildDefaultSuggestionTile(suggestion);
            },
          ),
        );
      },
    );
  }

  Widget _buildDefaultSuggestionTile(OSMdata suggestion) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.location_on, color: borderColor, size: 20),
      title: Text(
        suggestion.displayname,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${suggestion.lat.toStringAsFixed(4)}, ${suggestion.lon.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: () {
        controller.selectLocation(suggestion);
        if (onAddressSelected != null) {
          onAddressSelected!(suggestion);
        }
      },
    );
  }
}

/// Petit widget interne pour relayer les changements de position du contrôleur
class _OSMFieldListeners extends StatefulWidget {
  final OSMController controller;
  final void Function(LatLng center, Map<String, dynamic>? address)? onLocationChanged;
  const _OSMFieldListeners({Key? key, required this.controller, this.onLocationChanged}) : super(key: key);

  @override
  State<_OSMFieldListeners> createState() => _OSMFieldListenersState();
}

class _OSMFieldListenersState extends State<_OSMFieldListeners> {
  void _handler(LatLng c, Map<String, dynamic>? a) {
    widget.onLocationChanged?.call(c, a);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addLocationChangedListener(_handler);
  }

  @override
  void didUpdateWidget(covariant _OSMFieldListeners oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeLocationChangedListener(_handler);
      widget.controller.addLocationChangedListener(_handler);
    }
  }

  @override
  void dispose() {
    widget.controller.removeLocationChangedListener(_handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Version compacte du champ de recherche sans suggestions
class OSMSearchFieldCompact extends StatelessWidget {
  final OSMController controller;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool readOnly;
  final Color backgroundColor;
  final IconData prefixIcon;
  final bool requiredField;
  final String requiredMessage;
  final String? allowedCountryCode;
  final String? allowedCountryName;
  final String wrongCountryMessage;
  final AutovalidateMode autovalidateMode;
  final FormFieldValidator<String>? validator;

  const OSMSearchFieldCompact({
    Key? key,
    required this.controller,
    this.hintText = 'Rechercher une adresse...',
    this.decoration,
    this.textStyle,
    this.borderColor = Colors.blue,
    this.onTap,
    this.readOnly = false,
    this.backgroundColor = Colors.white,
    this.prefixIcon = Icons.gps_fixed,
    this.requiredField = false,
    this.requiredMessage = 'Ce champ est requis',
    this.allowedCountryCode,
    this.allowedCountryName,
    this.wrongCountryMessage = "L'adresse n'est pas dans le pays requis",
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return TextFormField(
          controller: controller.searchController,
          focusNode: controller.focusNode,
          style: textStyle,
          readOnly: readOnly,
          onTap: onTap,
          autovalidateMode: autovalidateMode,
          validator: validator ?? (value) {
            final text = value?.trim() ?? '';
            if (requiredField && text.isEmpty) {
              return requiredMessage;
            }
            final cc = controller.lastCountryCode;
            final cn = controller.lastCountryName;
            if (allowedCountryCode != null && (cc == null || cc.toUpperCase() != allowedCountryCode!.toUpperCase())) {
              final expected = allowedCountryName ?? allowedCountryCode;
              return "$wrongCountryMessage (${expected})";
            }
            if (allowedCountryCode == null && allowedCountryName != null) {
              if (cn == null || cn.toLowerCase() != allowedCountryName!.toLowerCase()) {
                return "$wrongCountryMessage (${allowedCountryName})";
              }
            }
            return null;
          },
          decoration: decoration ??
              InputDecoration(
                fillColor: backgroundColor,
                filled: true,
                hintText: hintText,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(prefixIcon, color: borderColor),
              ),
          onChanged: readOnly ? null : (value) => controller.searchLocation(value),
        );
      },
    );
  }
}
