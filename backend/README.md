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

## IntÃ©grer un modÃ¨le `.h5`

Le backend charge par dÃ©faut le fichier :

```text
backend/app/ml/skin_cancer_model.h5
```

Option 1 : copier ton modÃ¨le tÃ©lÃ©chargÃ© vers ce chemin et le renommer en `skin_cancer_model.h5`.

Option 2 : garder le fichier Ã  un autre emplacement et dÃ©finir la variable d'environnement `MODEL_PATH`.

Exemple PowerShell :

```powershell
$env:MODEL_PATH="C:\Users\asma\Downloads\skin_cancer_model (1).h5"
python -m uvicorn app.main:app --reload
```

Si le modÃ¨le est bien chargÃ©, l'endpoint `POST /prediction/{image_id}` utilisera directement ce fichier.

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
