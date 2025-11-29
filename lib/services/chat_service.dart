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

    // add message to Firestore
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // update chat room metadata
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'users': ids,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastMessageSender': currentUserId,
    }, SetOptions(merge: true));

    await updateTypingStatus(receiverId, false);
  }

  // get messages from firestore
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

  // get all chat rooms for current user
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

  Future<void> updateTypingStatus(String receiverId, bool isTyping) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _realtimeDb
        .ref('typing_status/$chatRoomId/$currentUserId')
        .set({'isTyping': isTyping, 'timestamp': ServerValue.timestamp});
  }

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

  // update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _realtimeDb.ref('users/$currentUserId/status').set({
      'isOnline': isOnline,
      'lastSeen': ServerValue.timestamp,
    });

    // set up disconnect handler
    if (isOnline) {
      _realtimeDb.ref('users/$currentUserId/status').onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
  }

  // get online status
  Stream<DatabaseEvent> getOnlineStatus(String userId) {
    return _realtimeDb.ref('users/$userId/status').onValue;
  }

  // get all users from Firestore
  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  // get user data
  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}