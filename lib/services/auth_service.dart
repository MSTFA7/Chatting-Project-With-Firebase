import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      });

      await userCredential.user!.updateDisplayName(username);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign up';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user status to online
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign in';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_auth.currentUser != null) {
        final userId = _auth.currentUser!.uid;

        // Update Firestore status
        await _firestore.collection('users').doc(userId).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });

        // Update Realtime Database status
        await _realtimeDb.ref('users/$userId/status').set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });

        // Remove any disconnect handlers
        await _realtimeDb.ref('users/$userId/status').onDisconnect().cancel();
      }

      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }
}