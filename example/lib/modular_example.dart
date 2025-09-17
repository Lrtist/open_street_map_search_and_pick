import 'package:flutter/material.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';

/// Exemple d'utilisation des widgets modulaires OSM
class ModularExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM Widgets Modulaires',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ModularExampleHome(),
    );
  }
}

class ModularExampleHome extends StatefulWidget {
  @override
  _ModularExampleHomeState createState() => _ModularExampleHomeState();
}

class _ModularExampleHomeState extends State<ModularExampleHome> {
  int _selectedIndex = 0;
  late OSMController _sharedController;

  @override
  void initState() {
    super.initState();
    _sharedController = OSMController();
  }

  @override
  void dispose() {
    _sharedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exemples OSM Modulaires'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildSeparatedWidgetsExample(),
          _buildCombinedWidgetExample(),
          _buildCustomLayoutExample(),
          _buildSharedControllerExample(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'Séparés',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers),
            label: 'Combiné',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Custom',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Partagé',
          ),
        ],
      ),
    );
  }

  /// Exemple 1: Widgets complètement séparés
  Widget _buildSeparatedWidgetsExample() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Widgets Séparés',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          
          // Champ de recherche indépendant
          OSMSearchField(
            controller: OSMController(),
            hintText: 'Recherche indépendante...',
            borderColor: Colors.green,
            maxHeight: 200,
          ),
          
          SizedBox(height: 16),
          
          // Carte indépendante
          Expanded(
            child: OSMMapView(
              controller: OSMController(),
              showZoomControls: true,
              showCurrentLocationButton: true,
              showLocationPin: true,
              buttonColor: Colors.green,
              locationPinIconColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Exemple 2: Widget combiné simple
  Widget _buildCombinedWidgetExample() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Widget Combiné',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          
          Expanded(
            child: OSMSearchAndMapWidget(
              hintText: 'Rechercher un lieu...',
              primaryColor: Colors.purple,
              onLocationPicked: (pickedData) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lieu sélectionné: ${pickedData.addressName}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Exemple 3: Layout personnalisé
  Widget _buildCustomLayoutExample() {
    final controller = OSMController();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout Personnalisé',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          
          // Champ de recherche compact en haut
          OSMSearchFieldCompact(
            controller: controller,
            hintText: 'Tap pour rechercher...',
            borderColor: Colors.orange,
            readOnly: true,
            onTap: () => _showSearchDialog(context, controller),
          ),
          
          SizedBox(height: 16),
          
          // Carte avec contrôles personnalisés
          Expanded(
            child: Stack(
              children: [
                OSMMapViewSimple(
                  controller: controller,
                  interactive: true,
                ),
                
                // Contrôles personnalisés
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'custom_zoom_in',
                        backgroundColor: Colors.orange,
                        onPressed: () => controller.zoomIn(),
                        child: Icon(Icons.add),
                      ),
                      SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'custom_zoom_out',
                        backgroundColor: Colors.orange,
                        onPressed: () => controller.zoomOut(),
                        child: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de position personnalisé
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Exemple 4: Contrôleur partagé entre plusieurs widgets
  Widget _buildSharedControllerExample() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contrôleur Partagé',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Le champ de recherche et la carte partagent le même contrôleur',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 16),
          
          // Champ de recherche utilisant le contrôleur partagé
          OSMSearchField(
            controller: _sharedController,
            hintText: 'Recherche synchronisée...',
            borderColor: Colors.red,
            maxHeight: 150,
          ),
          
          SizedBox(height: 16),
          
          // Carte utilisant le même contrôleur
          Expanded(
            child: OSMMapView(
              controller: _sharedController,
              showZoomControls: true,
              showCurrentLocationButton: true,
              showLocationPin: true,
              buttonColor: Colors.red,
              locationPinIconColor: Colors.red,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Boutons d'action utilisant le contrôleur partagé
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final data = await _sharedController.getCurrentPickedData();
                  _showLocationInfo(context, data);
                },
                icon: Icon(Icons.info),
                label: Text('Info Position'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _sharedController.searchController.clear();
                  _sharedController.searchLocation('');
                },
                icon: Icon(Icons.clear),
                label: Text('Effacer'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, OSMController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechercher un lieu'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: OSMSearchField(
            controller: controller,
            hintText: 'Tapez votre recherche...',
            borderColor: Colors.orange,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLocationInfo(BuildContext context, PickedData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations de Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adresse: ${data.addressName}'),
            SizedBox(height: 8),
            Text('Latitude: ${data.latLong.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${data.latLong.longitude.toStringAsFixed(6)}'),
            if (data.address.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Détails:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...data.address.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(ModularExampleApp());
}
