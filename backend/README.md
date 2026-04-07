# Skin Cancer Backend

Backend FastAPI pour l'application DermaScan AI.

## Fonctionnalités

- authentification patient / dermatologue
- upload d'images de lésions
- prédiction simulée
- notifications de risque
- suivi chronologique
- dossier médical patient
- stockage de la zone corporelle et des symptômes associés à chaque image

## Prérequis

- Python 3.11+
- PostgreSQL

## Installation

Depuis le dossier `backend` :

```powershell
pip install -r requirements.txt
pip install alembic
```

## Base de données

Configurer `DATABASE_URL` si nécessaire.

Exemple :

```powershell
$env:DATABASE_URL="postgresql://postgres:motdepasse@localhost:5432/skin_db"
```

La configuration par défaut se trouve dans :
[config.py](c:/Users/asma/OneDrive/Bureau/Skin_Cancer_App/backend/app/core/config.py)

## Migration PostgreSQL

Depuis `backend` :

```powershell
C:\Users\asma\AppData\Roaming\Python\Python313\Scripts\alembic.exe upgrade head
```

Cette migration ajoute notamment :
- `patients.date_naissance`
- `images.body_zone_id`
- `images.body_zone_label`
- `images.symptoms_json`

## Lancer le serveur

```powershell
python -m uvicorn app.main:app --reload
```

API locale :

```text
http://127.0.0.1:8000
```

## Endpoints principaux

- `/auth/register`
- `/auth/login`
- `/image/upload`
- `/image/intake-options`
- `/image/medical-record`
- `/prediction/{image_id}`
- `/suivi/timeline`
- `/stats/dashboard`

## Vérification rapide

1. lancer PostgreSQL
2. exécuter la migration Alembic
3. démarrer FastAPI
4. tester l'inscription
5. tester l'upload d'image avec zone corporelle + symptômes
6. vérifier que le résultat remonte dans le dossier médical
