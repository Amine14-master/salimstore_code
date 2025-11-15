# Firebase Authentication Troubleshooting Guide

## Common Signup Issues and Solutions

### 1. Firebase Authentication Not Enabled
**Problem**: "Firebase Auth is not enabled"
**Solution**: 
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project `salimstore-f1830`
3. Go to Authentication > Sign-in method
4. Enable "Email/Password" provider

### 2. Invalid Email Format
**Problem**: Phone numbers might not be valid email formats
**Solution**: The app converts phone numbers to email format:
- Admin: `phone@admin.salimstore.com`
- Client: `phone@client.salimstore.com`

### 3. Network Connectivity Issues
**Problem**: "Network error" or "Connection failed"
**Solution**: 
- Check your internet connection
- Try running on web: `flutter run -d chrome`
- Check firewall settings

### 4. Firestore Rules
**Problem**: "Permission denied" when saving user data
**Solution**: Update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Phone Number Validation
**Problem**: Phone number format issues
**Solution**: 
- Use format: `05xxxxxxxx` or `+213xxxxxxxx`
- Minimum 10 characters
- No spaces or special characters except +

### 6. Password Requirements
**Problem**: Password too weak
**Solution**: 
- Minimum 6 characters
- Use mix of letters and numbers
- Avoid common passwords

## Testing Steps

1. **Check Firebase Console**:
   - Go to Authentication > Users
   - Check if users are being created

2. **Check Browser Console**:
   - Open Developer Tools (F12)
   - Look for error messages in Console tab

3. **Test with Simple Data**:
   - Name: "Test User"
   - Phone: "0555123456"
   - Password: "123456"
   - Wilaya: "Alger" (for client)
   - Commune: "Alger Centre" (for client)

## Debug Information

The app now includes debug logging. Check the browser console for:
- "Starting signup process..."
- "User created successfully: [UID]"
- "Firebase Auth Error: [CODE] - [MESSAGE]"

## Quick Fixes

### If you get "Email already in use":
- Try a different phone number
- Or go to Firebase Console and delete the existing user

### If you get "Invalid email":
- Make sure phone number is at least 10 digits
- Don't include spaces or special characters

### If you get "Network error":
- Check internet connection
- Try running: `flutter clean && flutter pub get`
- Restart the app

## Contact Support

If issues persist, check:
1. Firebase project settings
2. Authentication providers
3. Firestore security rules
4. Network connectivity







