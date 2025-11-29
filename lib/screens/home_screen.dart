import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _chatService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _chatService.updateOnlineStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Firebase Chat'),
        backgroundColor: const Color(0xFF2A2A2A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF9800)),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3A3A3A), width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFF9800),
                  child: Text(
                    currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF9800),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;

                    if (userId == currentUser?.uid) {
                      return const SizedBox.shrink();
                    }

                    return StreamBuilder<DatabaseEvent>(
                      stream: _chatService.getOnlineStatus(userId),
                      builder: (context, statusSnapshot) {
                        bool isOnline = false;
                        if (statusSnapshot.hasData &&
                            statusSnapshot.data!.snapshot.value != null) {
                          final statusData =
                          statusSnapshot.data!.snapshot.value as Map;
                          isOnline = statusData['isOnline'] ?? false;
                        }

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFFF9800),
                                child: Text(
                                  userData['username']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF2A2A2A),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            userData['username'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: isOnline
                              ? const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  receiverUserId: userId,
                                  receiverUsername:
                                  userData['username'] ?? 'Unknown',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}