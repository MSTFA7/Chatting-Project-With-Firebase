import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send message using Firestore (persistent storage)
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String currentUserId = currentUser.uid;
    final String currentUserEmail = currentUser.email ?? '';
    final Timestamp timestamp = Timestamp.now();

    // Create message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // Create chat room ID (consistent for both users)
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Add message to Firestore
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update chat room metadata
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'users': ids,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastMessageSender': currentUserId,
    }, SetOptions(merge: true));

    // Also send typing indicator update to Realtime Database
    await updateTypingStatus(receiverId, false);
  }

  // Get messages from Firestore
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get all chat rooms for current user
  Stream<QuerySnapshot> getChatRooms() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Realtime Database: Update typing status
  Future<void> updateTypingStatus(String receiverId, bool isTyping) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    try {
      if (isTyping) {
        await _realtimeDb
            .ref('typing_status/$chatRoomId/$currentUserId')
            .set({
          'isTyping': true,
          'timestamp': ServerValue.timestamp,
        });
      } else {
        await _realtimeDb
            .ref('typing_status/$chatRoomId/$currentUserId')
            .remove();
      }
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Realtime Database: Listen to typing status
  Stream<DatabaseEvent> getTypingStatus(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _realtimeDb
        .ref('typing_status/$chatRoomId/$otherUserId')
        .onValue;
  }

  // Realtime Database: Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _realtimeDb.ref('users/$currentUserId/status').set({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });

      // Also set up disconnect handler when going online
      if (isOnline) {
        await _realtimeDb.ref('users/$currentUserId/status').onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
      } else {
        // Cancel disconnect handler when going offline
        await _realtimeDb.ref('users/$currentUserId/status').onDisconnect().cancel();
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Realtime Database: Get online status
  Stream<DatabaseEvent> getOnlineStatus(String userId) {
    return _realtimeDb.ref('users/$userId/status').onValue;
  }

  // Get all users from Firestore
  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}