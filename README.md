# TropicaGuide 🌍

**Collaborative Travel Planner — Mobile App Development Final Project**

TropicaGuide is a Flutter + Firebase mobile app that lets two people plan a trip together in real time. Users create shared itineraries, add and manage activities, sync a packing checklist live across devices, and optimize their schedule — all from their phones.

---

## Team

| Name | Role |
|------|------|
| Samia Haynes | Person B — UI & Features |
| Bryant Awoh | Person A — Backend & Firebase |

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform mobile frontend |
| Firebase Authentication | User sign up, login, session management |
| Cloud Firestore | Real-time database for trips, activities, and checklists |
| Firebase Storage | Profile photo upload and retrieval |
| Firebase Cloud Messaging | Push notifications between collaborators |

---

## Features

- **User authentication** — Email/password sign up and login via Firebase Auth
- **Traveler profile** — Display name, home city, and profile photo
- **Trip creation** — Create trips with name, destination, and date range
- **Activity management** — Add, edit, and delete activities with time, location, budget, and category
- **Real-time collaboration** — Invite a travel partner by email; both users see changes instantly via Firestore onSnapshot
- **Shared packing checklist** — Live-synced checklist where either user can check off items
- **Itinerary optimizer** — Reorders activities by start time with plain-text change labels
- **Push notifications** — FCM notification sent to collaborator when an activity is added or edited

---

## Project Structure

```
lib/
├── main.dart                          # App entry point + route configuration
├── models/
│   ├── trip.dart                      # Trip data model + Firestore mapping
│   └── activity.dart                  # Activity data model + Firestore mapping
└── screens/
    ├── auth/
    │   ├── splash_screen.dart         # Auth state check + redirect
    │   ├── login_screen.dart          # Email/password sign in
    │   └── signup_screen.dart         # Account creation + Firestore user write
    └── home/
        ├── home_screen.dart           # My Trips — real-time trip list
        ├── create_trip_sheet.dart     # Bottom sheet for new trip creation
        ├── trip_detail_screen.dart    # Activities tab + Packing List tab
        ├── add_activity_screen.dart   # Add or edit a single activity
        ├── packing_list_screen.dart   # Real-time shared checklist
        ├── invite_collaborator_screen.dart  # Add partner by email
        ├── optimizer_result_screen.dart     # Reordered itinerary + accept/cancel
        └── profile_screen.dart        # Edit profile + sign out
```

---

## Firestore Data Model

```
users/
  {uid}/
    displayName     String
    email           String
    homeCity        String
    profilePhotoUrl String
    fcmToken        String
    createdAt       Timestamp

trips/
  {tripId}/
    name            String
    destination     String
    startDate       Timestamp
    endDate         Timestamp
    tripType        String
    ownerUid        String
    collaborators   Array<String>   ← security rule checks this
    createdAt       Timestamp

    activities/     (subcollection)
      {activityId}/
        name              String
        startTime         String    ← stored as "HH:mm"
        location          String
        estimatedBudget   Number
        category          String
        addedBy           String
        createdAt         Timestamp

    checklist/      (subcollection)
      {itemId}/
        text        String
        completed   Boolean
        addedBy     String
        createdAt   Timestamp
```

**Security rule:**
```
allow read, write: if request.auth.uid in resource.data.collaborators;
```

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Dart SDK
- Android Studio with an emulator, or a physical Android device
- A Firebase project with Auth, Firestore, Storage, and FCM enabled

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/tropicaguide_app.git
cd tropicaguide_app
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Connect Firebase**

Install the FlutterFire CLI if you haven't already:
```bash
dart pub global activate flutterfire_cli
```

Then configure your Firebase project:
```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically. Make sure `main.dart` uses it:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**4. Add `google-services.json`**

Download from Firebase Console → Project Settings → Your Android app and place it at:
```
android/app/google-services.json
```

**5. Run the app**

List available devices:
```bash
flutter devices
```

Run on a specific device:
```bash
flutter run -d emulator-5554
```

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  image_picker: ^1.0.0
  intl: ^0.19.0
```

---

## Screens

| Screen | Description |
|--------|-------------|
| Splash | Checks auth state and routes to Login or Home |
| Login | Firebase Auth email/password sign in |
| Sign Up | Account creation — writes to Auth + Firestore simultaneously |
| My Trips | Real-time list of all trips the user owns or is invited to |
| Create Trip | Bottom sheet form for new trip with date picker and trip type |
| Trip Detail | Activities tab with optimize button + Packing List tab |
| Add / Edit Activity | Form for activity name, time, location, budget, category |
| Packing Checklist | Shared real-time checklist — swipe to delete, tap to toggle |
| Invite Collaborator | Look up user by email, add uid to trip collaborators array |
| Optimizer Result | Reordered activity list with change labels — accept or cancel |
| Profile | Edit display name and city, upload photo, sign out |

---

## Real-Time Collaboration

The core feature of TropicaGuide is that two users can edit the same trip simultaneously and see each other's changes instantly. This is powered by Firestore's `onSnapshot` listener wrapped in Flutter's `StreamBuilder` widget.

```dart
Stream<List<Activity>> get _activitiesStream =>
    FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('activities')
        .orderBy('startTime')
        .snapshots()
        .map((s) => s.docs.map((d) => Activity.fromDoc(d)).toList());
```

Every time a collaborator writes to the activities subcollection, Firestore pushes the update to all listening devices. The UI rebuilds automatically — no polling, no manual refresh.

---

## Testing

27 test cases across 4 categories:

| Category | Count | Focus |
|----------|-------|-------|
| Functional | 10 | CRUD, auth flows, form validation, empty states |
| Firebase Integration | 6 | Security rules, FCM token, Storage URL resolution |
| Real-Time Collaboration | 7 | Live sync on two devices, simultaneous edits, optimizer |
| UI & Usability | 7 | Empty states, loading spinners, navigation, screen sizes |

---

## Known Issues & Fixes

| Bug | Fix Applied |
|-----|-------------|
| Firestore security rules blocked all reads | Added collaborators array rule to Firestore rules |
| 93 import errors on startup | Added packages to pubspec.yaml + ran flutterfire configure |
| Trip list not updating after create | Created composite index on trips (collaborators + startDate) via Firebase Console |
| Keyboard covering text fields | Wrapped forms in SingleChildScrollView with viewInsets padding |
| Screen files in wrong folders causing import errors | Reorganized into auth/ and home/ subdirectories |

---

## License

This project was built for academic purposes as part of the Mobile App Development course at Georgia State University.
