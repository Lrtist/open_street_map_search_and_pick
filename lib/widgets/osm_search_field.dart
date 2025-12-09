import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/osm_controller.dart';
import '../models/osm_formatted_address.dart';

/// Widget de champ de recherche indépendant pour OpenStreetMap
class OSMSearchField extends StatefulWidget {
  final OSMController controller;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? errorStyle;
  final Color borderColor;
  final Color errorBorderColor;
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
    this.errorStyle,
    this.errorBorderColor = Colors.red,
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
  State<OSMSearchField> createState() => _OSMSearchFieldState();

}

class _OSMSearchFieldState extends State<OSMSearchField> {
  // Key pour forcer la revalidation à chaque changement via contrôleur/carte
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(15),
      constraints: widget.maxHeight != null ? BoxConstraints(maxHeight: widget.maxHeight!) : null,
      child: Material(
        elevation: 0,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          padding: widget.padding ?? const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OSMFieldListeners(
                controller: widget.controller,
                fieldKey: _fieldKey,
                onLocationChanged: widget.onLocationChanged,
                onLocationChangedFormatted: widget.onLocationChangedFormatted,
                onAddressSelectedFormatted: widget.onAddressSelectedFormatted,
              ),
              _buildSearchField(),
              if (widget.showSuggestions)
                AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) => _buildSuggestionsList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller.searchController,
      builder: (context, value, child) {
        final hasText = value.text.isNotEmpty;
        final baseDecoration = (widget.decoration ?? InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: widget.hintTextColor),
          border: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.borderColor, width: widget.borderWidth),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.borderColor, width: widget.borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.borderColor, width: widget.borderWidth * 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderSide:
                BorderSide(width: 1, color: widget.errorBorderColor), 
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          prefixIcon: Icon(widget.prefixIcon, color: widget.borderColor),
          filled: true,
          fillColor: widget.backgroundColor,
        )).copyWith(errorStyle: widget.errorStyle);

        return TextFormField(
          key: _fieldKey,
          controller: widget.controller.searchController,
          focusNode: widget.controller.focusNode,
          style: widget.textStyle,
          decoration: baseDecoration.copyWith(
            // Bouton effacer quand il y a du texte
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.clear),
                    color: widget.borderColor,
                    onPressed: () {
                      widget.controller.searchController.clear();
                      widget.controller.clearSearchOptions();
                      // garder le focus dans le champ
                      widget.controller.focusNode.requestFocus();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (!widget.controller.focusNode.hasFocus) {
              widget.controller.focusNode.requestFocus();
            }
            widget.controller.searchLocation(value);
          },
          validator: (value) {
            final center = widget.controller.lastCenter;
            final address = widget.controller.lastAddress;
            final formatted = widget.controller.lastFormattedAddress;
            return _validateAddress(center, address, formatted);
          },
          autovalidateMode: widget.autovalidateMode,
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (widget.controller.searchOptions.isEmpty) return const SizedBox.shrink();
    final items = widget.controller.searchOptions.take(widget.maxSuggestions).toList();
    return FocusTraversalGroup(
      // Empêche le panneau de suggestions de capter le focus clavier
      descendantsAreFocusable: false,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          // Border radius dédié aux suggestions: ne pas réutiliser le paramètre du champ
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.borderColor, width: widget.borderWidth),
        ),
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = items[index];
            final onTap = () {
              widget.onAddressSelected?.call(suggestion);
              widget.controller.selectLocation(suggestion);
            };
            if (widget.suggestionBuilder != null) {
              return Focus(
                canRequestFocus: false,
                descendantsAreFocusable: false,
                child: widget.suggestionBuilder!(context, suggestion, onTap),
              );
            }
            return Focus(
              canRequestFocus: false,
              descendantsAreFocusable: false,
              child: ListTile(
                title: Text(
                  suggestion.displayname,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: onTap,
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateAddress(LatLng? center, Map<String, dynamic>? address, OSMFormattedAddress? formatted) {
    if (widget.requiredField && (center == null || address == null)) {
      return widget.requiredMessage;
    }

    // Validation personnalisée d'abord (après le check requis)
    if (center != null && widget.validateOnChange != null) {
      final validationResult = widget.validateOnChange!(center, address, formatted);
      if (validationResult != null) {
        return validationResult;
      }
    }

    // Validation de pays (insensible à la casse)
    if (widget.allowedCountryCode != null && address != null) {
      // lastAddress correspond déjà à l'objet 'address' de Nominatim
      final countryCode = (address['country_code'] as String?)?.toUpperCase();
      final countryName = (address['country'] as String?)?.toLowerCase();
      final expectedCode = widget.allowedCountryCode!.toUpperCase();
      final expectedName = widget.allowedCountryName?.toLowerCase();

      if (countryCode != expectedCode && (expectedName == null || countryName != expectedName)) {
        return widget.wrongCountryMessage;
      }
    }

    if (widget.validator != null) {
      // Passer le texte courant du champ au validator utilisateur
      return widget.validator!(widget.controller.searchController.text);
    }

    return null;
  }
}

/// Petit widget interne pour relayer les changements de position du contrôleur
class _OSMFieldListeners extends StatefulWidget {
  final OSMController controller;
  final GlobalKey<FormFieldState> fieldKey;
  final void Function(LatLng center, Map<String, dynamic>? address)? onLocationChanged;
  final void Function(LatLng center, Map<String, dynamic>? address, OSMFormattedAddress? formatted)? onLocationChangedFormatted;
  final void Function(OSMdata address, OSMFormattedAddress? formatted)? onAddressSelectedFormatted;

  const _OSMFieldListeners({
    Key? key,
    required this.controller,
    required this.fieldKey,
    this.onLocationChanged,
    this.onLocationChangedFormatted,
    this.onAddressSelectedFormatted,
  }) : super(key: key);

  @override
  State<_OSMFieldListeners> createState() => _OSMFieldListenersState();
}

class _OSMFieldListenersState extends State<_OSMFieldListeners> {
  void _handler(LatLng c, Map<String, dynamic>? a) {
    // Revalider le champ dès que l'adresse change
    widget.fieldKey.currentState?.validate();
    widget.onLocationChanged?.call(c, a);
  }

  void _handlerEx(LatLng c, Map<String, dynamic>? a, OSMFormattedAddress? f) {
    widget.fieldKey.currentState?.validate();
    widget.onLocationChangedFormatted?.call(c, a, f);
  }

  void _addressSelectedEx(OSMdata d, OSMFormattedAddress? f) {
    widget.fieldKey.currentState?.validate();
    widget.onAddressSelectedFormatted?.call(d, f);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addLocationChangedListener(_handler);
    widget.controller.addLocationChangedExListener(_handlerEx);
    widget.controller.addAddressSelectedExListener(_addressSelectedEx);
    // Assurer que les événements carte sont attachés
    widget.controller.ensureMapListener();
  }

  @override
  void didUpdateWidget(covariant _OSMFieldListeners oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeLocationChangedListener(_handler);
      oldWidget.controller.removeLocationChangedExListener(_handlerEx);
      oldWidget.controller.removeAddressSelectedExListener(_addressSelectedEx);
      widget.controller.addLocationChangedListener(_handler);
      widget.controller.addLocationChangedExListener(_handlerEx);
      widget.controller.addAddressSelectedExListener(_addressSelectedEx);
      widget.controller.ensureMapListener();
    }
  }

  @override
  void dispose() {
    widget.controller.removeLocationChangedListener(_handler);
    widget.controller.removeLocationChangedExListener(_handlerEx);
    widget.controller.removeAddressSelectedExListener(_addressSelectedEx);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
