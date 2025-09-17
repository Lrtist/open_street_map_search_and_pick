import 'package:flutter/material.dart';
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(15),
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      child: Material(
        elevation: 4,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

    return TextFormField(
      controller: controller.searchController,
      focusNode: controller.focusNode,
      style: textStyle,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            border: inputBorder,
            focusedBorder: inputFocusBorder,
            enabledBorder: inputBorder,
            prefixIcon: Icon(Icons.search, color: borderColor),
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
      onTap: () => controller.selectLocation(suggestion),
    );
  }
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

  const OSMSearchFieldCompact({
    Key? key,
    required this.controller,
    this.hintText = 'Rechercher une adresse...',
    this.decoration,
    this.textStyle,
    this.borderColor = Colors.blue,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.searchController,
      focusNode: controller.focusNode,
      style: textStyle,
      readOnly: readOnly,
      onTap: onTap,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.search, color: borderColor),
          ),
      onChanged: readOnly ? null : (value) => controller.searchLocation(value),
    );
  }
}
