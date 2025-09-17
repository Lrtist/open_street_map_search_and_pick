# Widgets OSM Modulaires

Ce plugin a été étendu pour offrir des widgets modulaires qui peuvent être utilisés séparément ou ensemble, offrant une plus grande flexibilité dans la conception de votre interface utilisateur.

## Nouveaux Composants

### 1. OSMController
Le contrôleur central qui gère la communication entre les widgets de recherche et de carte.

```dart
final controller = OSMController();
controller.initialize(initialPosition: LatLng(48.8566, 2.3522));
```

### 2. OSMSearchField
Widget de champ de recherche indépendant avec suggestions automatiques.

```dart
OSMSearchField(
  controller: controller,
  hintText: 'Rechercher une adresse...',
  borderColor: Colors.blue,
  maxSuggestions: 5,
)
```

### 3. OSMMapView
Widget de carte indépendant avec contrôles optionnels.

```dart
OSMMapView(
  controller: controller,
  showZoomControls: true,
  showCurrentLocationButton: true,
  showLocationPin: true,
  buttonColor: Colors.blue,
)
```

## Exemples d'Utilisation

### Widgets Complètement Séparés

```dart
class SeparatedWidgetsExample extends StatefulWidget {
  @override
  _SeparatedWidgetsExampleState createState() => _SeparatedWidgetsExampleState();
}

class _SeparatedWidgetsExampleState extends State<SeparatedWidgetsExample> {
  final searchController = OSMController();
  final mapController = OSMController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Champ de recherche indépendant
        OSMSearchField(
          controller: searchController,
          hintText: 'Recherche indépendante...',
        ),
        
        // Carte indépendante
        Expanded(
          child: OSMMapView(
            controller: mapController,
            showZoomControls: true,
          ),
        ),
      ],
    );
  }
}
```

### Widgets Connectés avec Contrôleur Partagé

```dart
class ConnectedWidgetsExample extends StatefulWidget {
  @override
  _ConnectedWidgetsExampleState createState() => _ConnectedWidgetsExampleState();
}

class _ConnectedWidgetsExampleState extends State<ConnectedWidgetsExample> {
  final sharedController = OSMController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Champ de recherche
        OSMSearchField(
          controller: sharedController,
          hintText: 'Rechercher...',
        ),
        
        // Carte synchronisée
        Expanded(
          child: OSMMapView(
            controller: sharedController,
            showZoomControls: true,
          ),
        ),
        
        // Bouton pour récupérer la position
        ElevatedButton(
          onPressed: () async {
            final data = await sharedController.getCurrentPickedData();
            print('Position: ${data.addressName}');
          },
          child: Text('Obtenir Position'),
        ),
      ],
    );
  }
}
```

### Widget Combiné Simple

```dart
OSMSearchAndMapWidget(
  hintText: 'Rechercher un lieu...',
  primaryColor: Colors.green,
  showSearchField: true,
  showMapControls: true,
  onLocationPicked: (pickedData) {
    print('Lieu sélectionné: ${pickedData.addressName}');
  },
)
```

### Layout Personnalisé

```dart
class CustomLayoutExample extends StatelessWidget {
  final controller = OSMController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carte simple
        OSMMapViewSimple(
          controller: controller,
          interactive: true,
        ),
        
        // Champ de recherche en overlay
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: OSMSearchFieldCompact(
            controller: controller,
            readOnly: true,
            onTap: () => _showSearchDialog(context),
          ),
        ),
        
        // Contrôles personnalisés
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton.small(
                onPressed: () => controller.zoomIn(),
                child: Icon(Icons.add),
              ),
              SizedBox(height: 8),
              FloatingActionButton.small(
                onPressed: () => controller.zoomOut(),
                child: Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Propriétés et Méthodes

### OSMController

#### Propriétés
- `mapController`: Contrôleur de la carte Flutter Map
- `searchController`: Contrôleur du champ de texte
- `focusNode`: Nœud de focus pour le champ de recherche
- `searchOptions`: Liste des suggestions de recherche
- `baseUri`: URI de base pour l'API Nominatim

#### Méthodes
- `initialize(initialPosition)`: Initialise le contrôleur
- `searchLocation(query)`: Effectue une recherche
- `selectLocation(location)`: Sélectionne une location
- `moveToPosition(position, zoom)`: Déplace la carte
- `zoomIn()` / `zoomOut()`: Contrôles de zoom
- `getCurrentPickedData()`: Récupère les données actuelles

### OSMSearchField

#### Propriétés Principales
- `controller`: Le contrôleur OSM
- `hintText`: Texte d'aide
- `borderColor`: Couleur de la bordure
- `maxSuggestions`: Nombre maximum de suggestions
- `showSuggestions`: Afficher/masquer les suggestions
- `suggestionBuilder`: Builder personnalisé pour les suggestions

### OSMMapView

#### Propriétés Principales
- `controller`: Le contrôleur OSM
- `initialCenter`: Position initiale de la carte
- `showZoomControls`: Afficher les contrôles de zoom
- `showCurrentLocationButton`: Afficher le bouton de position actuelle
- `showLocationPin`: Afficher le pin de position
- `buttonColor`: Couleur des boutons
- `onCurrentLocationPressed`: Callback pour le bouton de position

## Migration depuis l'Ancien Widget

L'ancien widget `OpenStreetMapSearchAndPick` reste disponible pour la compatibilité. Pour migrer vers les nouveaux widgets modulaires :

### Avant
```dart
OpenStreetMapSearchAndPick(
  onPicked: (pickedData) {
    print(pickedData.addressName);
  },
)
```

### Après (Version Modulaire)
```dart
OpenStreetMapSearchAndPickModular(
  onPicked: (pickedData) {
    print(pickedData.addressName);
  },
)
```

### Après (Widgets Séparés)
```dart
final controller = OSMController();

Column(
  children: [
    OSMSearchField(controller: controller),
    Expanded(
      child: OSMMapView(controller: controller),
    ),
    ElevatedButton(
      onPressed: () async {
        final data = await controller.getCurrentPickedData();
        onPicked(data);
      },
      child: Text('Sélectionner'),
    ),
  ],
)
```

## Avantages des Widgets Modulaires

1. **Flexibilité**: Utilisez seulement les composants dont vous avez besoin
2. **Personnalisation**: Chaque widget peut être stylé indépendamment
3. **Réutilisabilité**: Les widgets peuvent être réutilisés dans différents contextes
4. **Contrôle**: Contrôle total sur le layout et l'interaction
5. **Performance**: Chargez seulement les fonctionnalités nécessaires

## Exemples Complets

Consultez le fichier `example/lib/modular_example.dart` pour des exemples complets d'utilisation des widgets modulaires.
