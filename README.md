# CAWS Pet Adoption System

> **Capstone Project:** An Integrated Pet Adoption Platform featuring an Intelligent Pet Recommendation System, In-App Digital Adoption Contracts, and Post-Adoption Health Monitoring.

---

## 1. Project Overview

The **CAWS Pet Adoption System** is a full-stack solution designed to streamline and modernize the pet adoption process. It bridges animal shelters and prospective pet adopters through a lifestyle-based recommendation engine, transparent application workflows, paperless digital contract signing, and routine health check-ins.

The system consists of two primary components:
1. **Backend (`pet-adoption-system`)**: A robust RESTful API built with **Laravel** and **MySQL**, handling business logic, database migrations, the recommendation algorithm, authentication, and push notifications.
2. **Mobile Client (`mobile_petadopt`)**: A mobile application built with **Flutter**, offering an intuitive UI for adopters to browse pets, take the matching quiz, submit adoption applications, and track adoption progress.

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Mobile Client (Flutter)                   │
│                       mobile_petadopt                       │
│  - Match Quiz Screen          - Pet Catalog & Detail        │
│  - Adoption Applications      - Digital Contract Signer     │
│  - Push Notifications (FCM)   - Post-Adoption Health Log    │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / JSON REST API
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Backend Server (Laravel)                   │
│                    pet-adoption-system                      │
│  - Authentication & Profiles  - Matching & Scoring Engine   │
│  - Pet Catalog Management     - Adoption Lifecycle Manager  │
│  - Digital Storage (Uploads)  - Notification Dispatcher     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    Relational Database                      │
│                           MySQL                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Key Features

- **Intelligent Pet Matching Quiz:** Adopters answer questions regarding living environment, activity level, pet experience, work schedule, and desired temperaments. The backend scoring algorithm evaluates lifestyle compatibility and returns top matching pets.
- **Pet Catalog & Advanced Filtering:** Search and filter available rescues by species, age, gender, and adoption status with high-resolution photo galleries.
- **Multi-Step Adoption Application:** Streamlined questionnaire capturing household environment, caretaker capacity, and contact verification.
- **Digital Contract Signing:** Integrated digital signature canvas allowing adopters to sign legal adoption agreements directly inside the mobile app.
- **Post-Adoption Health Check-ins:** Enables adopters to submit ongoing health updates, veterinary records, and photos for shelter monitoring.
- **Push Notifications & Status Alerts:** Automated real-time updates on adoption application reviews via Firebase Cloud Messaging (FCM).
- **Secure Multi-Factor Authentication:** Email/password authentication, Google Sign-In, and Phone OTP verification.

---

## 4. Technology Stack

### Mobile Application (`mobile_petadopt`)
- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.12.0`)
- **State Management & Architecture:** Layered Service-UI Architecture (`lib/screens`, `lib/services`, `lib/widgets`)
- **Networking:** `http` package with centralized `ApiService`
- **Authentication & Notifications:** `firebase_core`, `firebase_messaging`, `firebase_auth`, `google_sign_in`
- **UI & Assets:** `google_fonts` (Poppins), Custom Canvas Painters (Signature Pad & Pet Animations)

### Backend API (`pet-adoption-system`)
- **Framework:** [Laravel](https://laravel.com/) (PHP)
- **Database:** MySQL
- **Authentication:** Laravel Sanctum / Token-based API Auth
- **Storage:** Public Disk / Symlinked Asset Storage for pet photos and digital signatures
- **Push Engine:** Firebase Admin SDK / FCM API

### Machine Learning & Recommendation Engine (`ml/`)
- **Language:** Python
- **Core Libraries:** Scikit-learn, Pandas, NumPy, Joblib
- **Model Artifact:** `pet_match_model.pkl` (Trained lifestyle-pet compatibility model)
- **Datasets:** Austin Animal Center (`aac_shelter_outcomes.csv`) & Shelter Adoption Dataset (`shelter_adoption_dataset.csv`)

---

## 5. Repository & Project Structure

```
├── mobile_petadopt/                 # Mobile Application (Flutter)
│   ├── assets/                      # App branding, icons, and illustrations
│   ├── lib/
│   │   ├── data/                    # Local datasets (Philippine locations, etc.)
│   │   ├── screens/
│   │   │   ├── adoption/            # Application forms, contracts, health check-ins
│   │   │   ├── auth/                # Login, registration, phone verification
│   │   │   ├── home/                # Main dashboard & home feeds
│   │   │   ├── pets/                # Pet catalog, filtering, and pet details
│   │   │   ├── profile/             # User profile, addresses, settings
│   │   │   ├── recommendation/      # Match a Pet lifestyle quiz & evaluation
│   │   │   └── splash/              # Animated splash screen
│   │   ├── services/
│   │   │   ├── api_service.dart     # HTTP client & REST endpoint handlers
│   │   │   ├── notification_service.dart # Local and push notification handler
│   │   │   └── phone_auth_service.dart   # Phone OTP authentication helper
│   │   ├── theme/                   # App theme, color tokens, and typography
│   │   ├── widgets/                 # Reusable UI cards, custom loaders, dialogs
│   │   └── main.dart                # App entry point & initialization
│   ├── pubspec.yaml                 # Dependencies and asset declarations
│   └── README.md                    # Project documentation
│
└── pet-adoption-system/                     # Backend REST API (Laravel)
    ├── app/
    │   ├── Http/
    │   │   ├── Controllers/
    │   │   │   ├── AuthController.php            # User registration, login, phone OTP, Google auth
    │   │   │   ├── PetController.php             # Pet catalog, filtering, pet profiles & images
    │   │   │   ├── RecommendationController.php  # Match quiz processing & recommendation scoring
    │   │   │   ├── AdoptionController.php        # Application submissions & contract signing
    │   │   │   ├── HealthCheckinController.php   # Post-adoption health status reports & photos
    │   │   │   ├── NotificationController.php    # Push notification dispatch & FCM tokens
    │   │   │   └── ProfileController.php         # User profile, address, and password updates
    │   │   ├── Middleware/
    │   │   │   └── Authenticate.php              # API token validation (Sanctum)
    │   │   └── Requests/                         # Form request validations (AdoptionRequest, etc.)
    │   ├── Models/
    │   │   ├── User.php                          # User accounts & roles
    │   │   ├── Pet.php                           # Pet records, attributes, and adoption status
    │   │   ├── AdoptionApplication.php           # Adoption form submissions & review statuses
    │   │   ├── AdoptionContract.php              # Legal agreement & digital signatures
    │   │   ├── HealthCheckin.php                 # Post-adoption health monitoring logs
    │   │   ├── Favorite.php                      # Bookmarked pets by adopters
    │   │   └── UserPreference.php                # Saved adopter quiz criteria & weights
    │   └── Services/
    │       ├── RecommendationService.php         # Lifestyle compatibility algorithm & scoring
    │       └── FirebaseNotificationService.php   # Push notification delivery via FCM
    ├── config/                                   # App, database, auth, and service configs
    ├── database/
    │   ├── migrations/
    │   │   ├── create_users_table.php
    │   │   ├── create_pets_table.php
    │   │   ├── create_adoption_applications_table.php
    │   │   ├── create_adoption_contracts_table.php
    │   │   ├── create_health_checkins_table.php
    │   │   └── create_user_preferences_table.php
    │   └── seeders/
    │       ├── DatabaseSeeder.php                # Master seeder
    │       └── PetSeeder.php                     # Initial pet profiles & test records
    ├── ml/                                       # Machine Learning Recommendation Module
    │   ├── aac_shelter_outcomes.csv              # AAC shelter outcomes dataset
    │   ├── shelter_adoption_dataset.csv          # Shelter adoption training dataset
    │   ├── feature_columns.json                  # Encoded feature column mappings
    │   ├── model_metrics.json                    # Model evaluation scores & performance metrics
    │   ├── pet_match_model.pkl                   # Trained recommendation model artifact
    │   ├── pet_recommender.py                    # Recommendation algorithm logic
    │   ├── run_recommender.py                    # Inference execution script invoked by Laravel
    │   └── train_model.py                        # Model training & evaluation pipeline
    ├── routes/
    │   └── api.php                               # REST API route declarations
    ├── storage/
    │   └── app/public/                           # Uploaded pet photos, avatars & signature PNGs
    ├── .env.example                              # Environment configuration template
    └── composer.json                             # PHP dependencies & Laravel framework
```

---

## 6. Installation & Setup Guide

### Step 1: Setting Up the Backend (`pet-adoption-system`)

1. Open your terminal and navigate to the backend folder:
   ```bash
   cd pet-adoption-system
   ```
2. Install PHP dependencies:
   ```bash
   composer install
   ```
3. Copy environment configuration and generate the application key:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
4. Configure your MySQL database settings inside `.env`:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=pet_adoption_db
   DB_USERNAME=root
   DB_PASSWORD=your_password
   ```
5. Run migrations and seeders:
   ```bash
   php artisan migrate --seed
   ```
6. Create the storage symlink for uploaded images:
   ```bash
   php artisan storage:link
   ```
7. Set up Python environment for the ML recommendation module:
   ```bash
   pip install scikit-learn pandas numpy joblib
   ```
8. Start the local server (bind to your local network IP for mobile testing):
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

---

### Step 2: Setting Up the Mobile App (`mobile_petadopt`)

1. Navigate to the mobile application directory:
   ```bash
   cd mobile_petadopt
   ```
2. Fetch required Flutter packages:
   ```bash
   flutter pub get
   ```
3. Update the API Base URL:
   Open `lib/services/api_service.dart` and update `_baseUrl` with your computer's local Wi-Fi IP address:
   ```dart
   static const String _baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
   ```
4. Run the application on a connected device or emulator:
   ```bash
   flutter run
   ```

---

## 7. Testing & Quality Assurance

- **Flutter Unit & Widget Tests:**
  ```bash
  flutter test
  ```
- **Static Analysis & Linting:**
  ```bash
  flutter analyze
  ```
- **Backend API Feature Tests:**
  ```bash
  php artisan test
  ```

---

## 8. Capstone Information & Authors

* **Project Title:** Design and Development of a Mobile Application for Pet Adoption with Smart Pet Recommendation for CDO Animal Welfare Society Inc. 
* **Academic Year:** 2025–2026
* **Scope:** Mobile Pet Adoption & Intelligent Matching System
