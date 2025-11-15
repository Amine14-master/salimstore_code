# Salim Store - Admin & Client Apps

A beautiful Flutter authentication system with two separate apps: Admin and Client, using Firebase Authentication.

## Features

### Admin App
- **Sign Up**: Name, Phone, Password, Confirm Password
- **Sign In**: Phone, Password
- Beautiful gradient UI with animations
- Firebase Authentication integration

### Client App
- **Sign Up**: Name, Phone, Wilaya, Commune, Password, Confirm Password
- **Sign In**: Phone, Password
- Dynamic wilaya and commune selection from Algeria cities data
- Beautiful gradient UI with animations
- Firebase Authentication integration

## Setup Instructions

### 1. Firebase Configuration

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password provider
3. Download the `google-services.json` file for Android
4. Place the `google-services.json` file in:
   - `admin/android/app/google-services.json`
   - `client/android/app/google-services.json`

### 2. Install Dependencies

For both admin and client apps, run:

```bash
# Navigate to admin directory
cd admin
flutter pub get

# Navigate to client directory
cd ../client
flutter pub get
```

### 3. Run the Apps

#### Admin App
```bash
cd admin
flutter run
```

#### Client App
```bash
cd client
flutter run
```

## Project Structure

```
salimstore/
├── admin/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   └── auth_service.dart
│   │   ├── screens/
│   │   │   └── auth_screen.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   └── pubspec.yaml
└── client/
    ├── lib/
    │   ├── main.dart
    │   ├── services/
    │   │   └── auth_service.dart
    │   ├── screens/
    │   │   └── auth_screen.dart
    │   ├── theme/
    │   │   └── app_theme.dart
    │   └── data/
    │       └── algeria_cities.json
    └── pubspec.yaml
```

## Dependencies

### Core Dependencies
- `firebase_core: ^3.6.0` - Firebase core functionality
- `firebase_auth: ^5.3.1` - Firebase Authentication
- `cloud_firestore: ^5.4.4` - Cloud Firestore database

### UI Dependencies
- `google_fonts: ^6.2.1` - Beautiful typography
- `flutter_svg: ^2.0.10+1` - SVG support
- `lottie: ^3.1.2` - Lottie animations
- `flutter_animate: ^4.5.0` - Smooth animations

## Features

### Beautiful UI Design
- Modern gradient backgrounds
- Smooth animations and transitions
- Material Design 3 components
- Custom card designs with shadows
- Responsive layout

### Authentication Flow
- Real-time authentication state management
- Form validation with helpful error messages
- Loading states during authentication
- Success/error feedback with snackbars

### Location Selection (Client App)
- Dynamic wilaya dropdown
- Commune dropdown based on selected wilaya
- Data loaded from Algeria cities JSON file

## Firebase Security Rules

Make sure to set up proper Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin collection
    match /admins/{adminId} {
      allow read, write: if request.auth != null && request.auth.uid == adminId;
    }
    
    // Client collection
    match /clients/{clientId} {
      allow read, write: if request.auth != null && request.auth.uid == clientId;
    }
  }
}
```

## Customization

### Colors
Edit the color scheme in `lib/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6366F1);
static const Color secondaryColor = Color(0xFF8B5CF6);
static const Color accentColor = Color(0xFF06B6D4);
```

### Animations
Customize animations in the auth screens by modifying the `.animate()` calls.

## Troubleshooting

### Common Issues

1. **Firebase not initialized**: Make sure `google-services.json` is in the correct location
2. **Build errors**: Run `flutter clean` and `flutter pub get`
3. **Authentication errors**: Check Firebase console for enabled providers

### Debug Mode
Both apps run in debug mode by default. For production builds:

```bash
flutter build apk --release
```

## Support

For issues and questions, please check the Firebase documentation or Flutter documentation.

---

**Note**: This is a demo authentication system. For production use, implement additional security measures like email verification, password strength requirements, and proper error handling.







# salimstore_admin
