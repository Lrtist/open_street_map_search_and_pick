import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';
import '../models/osm_formatted_address.dart';

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
  // Nouveaux callbacks avec adresse formatée
  final void Function(OSMdata address, OSMFormattedAddress? formatted)? onAddressSelectedFormatted;
  final void Function(LatLng center, Map<String, dynamic>? address, OSMFormattedAddress? formatted)? onLocationChangedFormatted;
  
  /// Fonction de validation personnalisée appelée à chaque changement d'adresse
  /// Retourne null si valide, sinon retourne le message d'erreur
  final String? Function(LatLng center, Map<String, dynamic>? address, OSMFormattedAddress? formatted)? validateOnChange;

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
    this.onAddressSelectedFormatted,
    this.onLocationChangedFormatted,
    this.validateOnChange,
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
              _OSMFieldListeners(
                controller: controller,
                onLocationChanged: onLocationChanged,
                onLocationChangedFormatted: onLocationChangedFormatted,
                onAddressSelectedFormatted: onAddressSelectedFormatted,
              ),
              _buildSearchField(),
              if (showSuggestions) _buildSuggestionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: controller.searchController,
      focusNode: controller.focusNode,
      style: textStyle,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintTextColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: borderWidth * 1.5),
            ),
            prefixIcon: Icon(prefixIcon, color: borderColor),
            filled: true,
            fillColor: backgroundColor,
          ),
      onChanged: (value) {
        if (!controller.focusNode.hasFocus) {
          controller.focusNode.requestFocus();
        }
        controller.searchLocation(value);
      },
      validator: (value) {
        final center = controller.lastCenter;
        final address = controller.lastAddress;
        final formatted = controller.lastFormattedAddress;
        return _validateAddress(center, address, formatted);
      },
      autovalidateMode: autovalidateMode,
    );
  }

  String? _validateAddress(LatLng? center, Map<String, dynamic>? address, OSMFormattedAddress? formatted) {
    if (requiredField && (center == null || address == null)) {
      return requiredMessage;
    }
    
    if (allowedCountryCode != null && address != null) {
      final countryCode = address['address']?['country_code'];
      final countryName = address['address']?['country'];
      
      if (countryCode != allowedCountryCode && 
          (allowedCountryName == null || countryName != allowedCountryName)) {
        return wrongCountryMessage;
      }
    }
    
    // Validation personnalisée via validateOnChange
    if (center != null && validateOnChange != null) {
      final validationResult = validateOnChange!(center, address, formatted);
      if (validationResult != null) {
        return validationResult;
      }
    }
    
    if (validator != null) {
      return validator!(address?['display_name'] ?? '');
    }
    
    return null;
  }
}
