# DermaScan AI

Application Flutter connectée à un backend FastAPI pour :
- l'inscription et la connexion patient / dermatologue
- l'analyse d'images de lésions cutanées
- la sélection de la zone via carte corporelle
- le stockage des résultats dans le dossier médical du patient

## Prérequis

- Flutter SDK
- Python 3.11+
- PostgreSQL

## Installation équipe

### 1. Backend

Depuis la racine du projet :

```powershell
cd backend
pip install -r requirements.txt
pip install alembic
```

### 2. Base de données

Créer une base PostgreSQL `skin_db`, puis configurer la variable `DATABASE_URL` si besoin.

Exemple :

```powershell
$env:DATABASE_URL="postgresql://postgres:motdepasse@localhost:5432/skin_db"
```

Sinon, le projet utilise la valeur par défaut définie dans :
[config.py](c:/Users/asma/OneDrive/Bureau/Skin_Cancer_App/backend/app/core/config.py)

### 3. Migration PostgreSQL

Depuis `backend` :

```powershell
C:\Users\asma\AppData\Roaming\Python\Python313\Scripts\alembic.exe upgrade head
```

### 4. Lancer le backend

```powershell
cd backend
python -m uvicorn app.main:app --reload
```

Backend par défaut :

```text
http://127.0.0.1:8000
```

### 5. Frontend Flutter

```powershell
cd front-end
flutter pub get
flutter run -d chrome
```

## Configuration API

Le frontend pointe vers :

[api_config.dart](c:/Users/asma/OneDrive/Bureau/Skin_Cancer_App/front-end/lib/core/api/api_config.dart)

Valeur actuelle :

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

Si l'équipe teste sur un autre appareil ou un autre PC, il faut remplacer cette URL par l'IP de la machine qui héberge le backend.

## Fonctionnalités ajoutées dans cette version

- dossier médical patient
- historique des anciennes images
- sélection de la lésion via carte corporelle
- sélection de symptômes avant analyse
- enregistrement de la zone et des symptômes avec le résultat

## Vérification rapide

1. lancer PostgreSQL
2. exécuter la migration Alembic
3. démarrer le backend
4. démarrer Flutter web
5. créer un compte patient
6. ajouter une image
7. sélectionner la zone sur la carte corporelle
8. cocher les symptômes
9. vérifier que le résultat apparaît ensuite dans le dossier médical
