# 🎬 OMDb Movie App

Application mobile Flutter pour rechercher, gérer et découvrir des films en utilisant l'API OMDb.

**Deadline:** 14 juin 2026  
**Plateforme:** Android (SDK gphone64 x86 64) + Samsung SM-A165M  
**État:** ✅ Complet avec touches personnelles

---

## ✨ Fonctionnalités Principales

### 🔍 **Recherche de Films**
- Rechercher par titre, série ou acteur
- Historique des 10 dernières recherches
- Résultats en temps réel via l'API OMDb

### ❤️ **Favoris**
- Ajouter/Retirer des films en favoris
- Statistiques personnalisées:
  - Nombre total de films
  - Films par année
  - Distribution par type
  - Répartition par décade

### 📁 **Collections Personnalisées**
- Créer plusieurs collections
- Ajouter/Retirer des films aux collections
- Voir les films dans chaque collection
- Accès direct aux détails du film

### 🎥 **Détails du Film**
- Affiche du film
- Note IMDB
- Acteurs, réalisateur, genre
- Durée, langue, pays
- Lien IMDB direct

### ⭐ **Avis Personnel**
- Donner une note personnelle (1-5 étoiles)
- Écrire un avis texte
- Modifier/Supprimer les avis
- Comparaison note personnelle vs IMDB

### 📍 **Carte des Cinémas**
- Afficher les cinémas proches via OpenStreetMap
- Géolocalisation GPS
- Données réelles des cinémas Marocains (Overpass API)

### 🌙 **Mode Sombre/Clair**
- Toggle en haut à droite
- Design Material 3
- Thème Marocain (couleurs du drapeau bleu/rouge)

### 🎨 **Filtres Avancés**
- Filtre par année (Range Slider: 1990-2024)
- Tri par année ou titre
- Mise en jour en temps réel

---

## 🛠️ **Touches Personnelles** (Bonus)

### 1️⃣ **Historique de Recherche**
- Sauvegarde les 10 dernières recherches
- Clic rapide pour relancer
- Bouton pour effacer une recherche

### 2️⃣ **Avis Personnel + Note**
- ⭐ Note personnelle 1-5 étoiles
- 💬 Avis texte personnalisé
- 📊 Comparaison avec la note IMDB
- ✏️ Modification possible
- 🗑️ Suppression possible

### 3️⃣ **Collections Personnalisées**
- 📁 Créer des listes custom
- ➕ Ajouter films directement depuis page détails
- 🎬 Voir tous les films de la collection
- 🔗 Accès aux détails du film
- ✅ Gestion complète (ajouter/retirer)

---

## 📱 **Navigation**

```
┌─────────────────────────────────────┐
│ Recherche | Favoris | Collections | Cinémas │
│    🔍    │    ❤️   │    📁     │   📍   │
└─────────────────────────────────────┘
```

### **Onglets:**
1. **Recherche** - Chercher des films avec filtres avancés
2. **Favoris** - Voir les favoris + statistiques
3. **Collections** - Gérer ses collections personnalisées
4. **Cinémas** - Voir les cinémas sur la carte

---

## 🚀 **Installation**

### **Prérequis:**
- Flutter SDK (dernière version)
- Android SDK ou émulateur
- Clé API OMDb (gratuite sur [omdbapi.com](https://www.omdbapi.com/))

### **Étapes:**

1. **Cloner le projet** (ou extraire l'archive ZIP)
```bash
cd omdb_app
```

2. **Installer les dépendances**
```bash
flutter clean
flutter pub get
```

3. **Configurer la clé API**
```
lib/config/api_constants.dart
└─ const String apiKey = 'votre_clé_api';
```

4. **Compiler et lancer**
```bash
# Sur émulateur
flutter run

# Sur appareil physique
flutter run -d device_id
```

---

## 📦 **Dépendances**

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  json_annotation: ^4.8.0
  sqflite: ^2.3.0
  path: ^1.8.3
  url_launcher: ^6.2.0
  provider: ^6.1.0
  geolocator: ^10.1.0
  permission_handler: ^11.4.4
  flutter_map: ^6.1.0
  latlong2: ^0.9.1

dev_dependencies:
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
```

---

## 📁 **Structure du Projet**

```
lib/
├── config/
│   └── api_constants.dart         # Clé API OMDb
├── models/
│   ├── movie.dart                 # Modèle Movie
│   ├── movie_details.dart         # Détails complets
│   └── cinema.dart                # Modèle Cinéma
├── services/
│   ├── api_service.dart           # Appels API OMDb
│   ├── database_service.dart      # SQLite (Favoris, Avis, Collections)
│   ├── location_service.dart      # Géolocalisation
│   └── cinema_service.dart        # Recherche cinémas (Overpass API)
├── screens/
│   ├── main_navigation.dart       # Navigation principale
│   ├── home_screen.dart           # Recherche + historique + filtres
│   ├── movie_details_screen.dart  # Détails film + avis
│   ├── favorites_screen.dart      # Favoris + statistiques
│   ├── collections_screen.dart    # Gestion collections
│   ├── collection_details_screen.dart  # Films d'une collection
│   └── map_screen.dart            # Carte cinémas
├── widgets/
│   └── movie_list_item.dart       # Widget liste film
├── main.dart                      # Point d'entrée (thème)
└── pubspec.yaml                   # Dépendances

android/
├── app/
│   ├── src/main/AndroidManifest.xml  # Permissions
│   └── build.gradle                  # Configuration Android
```

---

## 🎮 **Utilisation**

### **Rechercher un film:**
1. Allez à l'onglet "Recherche"
2. Tapez le nom du film/série/acteur
3. Appuyez sur "Afficher filtres" pour filtrer par année
4. Cliquez sur un film pour voir les détails

### **Ajouter aux favoris:**
1. Ouvrez un film
2. Cliquez sur le bouton "❤️ Aimer"
3. Allez à "Favoris" pour voir votre liste

### **Écrire un avis:**
1. Ouvrez un film
2. Allez à "Mon Avis Personnel"
3. Donnez une note (1-5 ⭐)
4. Écrivez votre avis
5. Cliquez "Sauvegarder"

### **Créer une collection:**
1. Allez à "Collections"
2. Cliquez sur "➕ Créer une collection"
3. Donnez un nom et une description
4. Validez

### **Ajouter un film à une collection:**
- **Depuis la page détails:** Cliquez "📁 Ajouter à une collection"
- **Depuis la collection:** Cliquez "➕ Ajouter un film"

### **Voir les cinémas:**
1. Allez à "Cinémas"
2. Accordez l'accès à votre localisation
3. Les cinémas proches s'affichent sur la carte

---

## 🔧 **Technologies Utilisées**

### **Frontend:**
- **Flutter** - Framework UI
- **Dart** - Langage de programmation
- **Material Design 3** - Design system

### **Backend/API:**
- **OMDb API** - Recherche et détails films
- **Overpass API** - Données cinémas (OpenStreetMap)

### **Base de données:**
- **SQLite** - Stockage local (Favoris, Avis, Collections)

### **Localisation:**
- **Geolocator** - Géolocalisation GPS
- **Flutter Map** - Affichage cartographique

---

## ⚠️ **Limitations Connues**

- **Historique:** Sauvegardé en mémoire (réinitialisation au redémarrage)
- **Recherche par acteur:** Filtre sur le titre uniquement (limitation API OMDb gratuite)
- **Cinémas:** Données via Overpass API (HTTP 406 peut survenir)
- **Requêtes API:** ~45 requêtes/jour max (plan gratuit OMDb)

---

## 🐛 **Dépannage**

### **App crash au lancement:**
```bash
flutter clean
flutter pub get
flutter run
```

### **Erreur "Impossible de se connecter à l'API":**
- Vérifiez votre clé API OMDb
- Vérifiez votre connexion Internet
- Vérifiez les limites de requêtes API

### **Carte ne s'affiche pas:**
- Vérifiez les permissions de localisation
- Assurez-vous d'avoir Internet

### **Base de données vide:**
- Les favoris/avis/collections sont stockés localement
- Premier lancement = base vide (normal)

---

## 📊 **Spécifications Techniques**

| Aspect | Détail |
|--------|--------|
| **Langage** | Dart 3.0+ |
| **Flutter** | 3.10+ |
| **Min SDK Android** | 21 |
| **Target SDK Android** | 33+ |
| **Architecture** | MVVM |
| **Base de données** | SQLite |
| **Authentification** | Aucune (API gratuite) |

---

## 📝 **Notes de Développement**

- **Versioning:** Utiliser `pubspec.yaml`
- **Build APK:** `flutter build apk --release`
- **Build AAB:** `flutter build appbundle`
- **Logs:** `flutter logs` pour déboguer
- **Tests:** Pas de tests unitaires implémentés

---

## 📄 **Licence**

Projet académique - Université

---

## 👨‍💻 **Auteurs**

- **Saad Berra**
- **Aya Ouknouz**
- **Date:** Juin 2026
- **Groupe:** 2 étudiants

---

## 📞 **Support**

Pour toute question ou problème, consultez la documentation Flutter: https://docs.flutter.dev

---

**Dernière mise à jour:** 04 Juin 2026  
**Status:** ✅ Prêt pour la remise