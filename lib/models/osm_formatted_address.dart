import 'dart:convert';

class OSMFormattedAddress {
  final String? placeId;
  final String? displayName;
  final Map<String, dynamic>? address;

  OSMFormattedAddress({
    this.placeId,
    this.displayName,
    this.address,
  });

  factory OSMFormattedAddress.fromJson(Map<String, dynamic> json) {
    return OSMFormattedAddress(
      placeId: json['place_id']?.toString(),
      displayName: json['display_name'],
      address: json['address'] != null
          ? Map<String, dynamic>.from(json['address'])
          : null,
    );
  }

  /// Retourne un display_name nettoyé avec suppression des doublons
  String get fullDisplayName {
    if (displayName == null || displayName!.isEmpty) return '';
    final parts = displayName!.split(',').map((e) => e.trim()).toList();
    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }
    return uniqueParts.join(', ');
  }

  /// Retourne l’adresse simplifiée selon les règles données
  String get simplifiedAddress {
    if (address == null) return '';

    final buffer = StringBuffer();

    // Priorité : numéro + nom de maison + rue
    final houseNumber = address!['house_number'];
    final houseName = address!['house_name'];
    final road = address!['road'];

    if (houseNumber != null) buffer.write('$houseNumber ');
    if (houseName != null) buffer.write('$houseName ');
    if (road != null) buffer.write('$road');

    // Localité principale (city/town/village)
    final city = address!['city'] ?? address!['town'] ?? address!['village'];
    if (city != null) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(city);
      return buffer.toString();
    }

    // Sinon divisions administratives si pas de localité
    final state = address!['state'];
    final county = address!['county'];
    final municipality = address!['municipality'];
    final region = address!['region'];

    final divisions = [municipality, county, state, region]
        .where((element) => element != null)
        .toList();

    if (divisions.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(divisions.join(', '));
      return buffer.toString();
    }

    // Sinon subdivisions plus petites (quartiers, etc.)
    final suburb = address!['suburb'];
    final neighbourhood = address!['neighbourhood'];
    final district = address!['district'];

    final smallDivs = [suburb, neighbourhood, district]
        .where((element) => element != null)
        .toList();

    if (smallDivs.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write(smallDivs.join(', '));
      return buffer.toString();
    }

    return buffer.toString();
  }

  /// Code postal
  String? get postCode => address?['postcode'];

  /// Code pays ISO (ex: "fr")
  String? get isoCountry => address?['country_code'];

  /// Nom du pays
  String? get country => address?['country'];

  /// Meilleure approximation de la ville depuis les champs d'adresse
  /// Ordre de priorité: city, town, village, municipality, hamlet, suburb, county
  String? get town =>
      address?['city'] ??
      address?['town'] ??
      address?['village'] ??
      address?['municipality'] ??
      address?['hamlet'] ??
      address?['suburb'] ??
      address?['county'];

  /// Méthode utilitaire pour parser une liste JSON
  static List<OSMFormattedAddress> fromJsonList(String jsonString) {
    final data = json.decode(jsonString);
    if (data is List) {
      return data.map((e) => OSMFormattedAddress.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (data is Map) {
      return [OSMFormattedAddress.fromJson(Map<String, dynamic>.from(data))];
    }
    return [];
  }
}
