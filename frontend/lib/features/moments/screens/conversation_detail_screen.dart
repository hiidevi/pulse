import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../models/moment.dart';
import '../../../services/moment_service.dart';
import '../../../services/profile_service.dart';
import '../../../models/user.dart' as model;
import '../../../theme/app_theme.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;

  const ConversationDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _momentService = MomentService();
  final _profileService = ProfileService();
  late Future<List<Moment>> _historyFuture;
  late Future<model.User> _otherUserFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _momentService.getConversationHistory(widget.otherUserId);
    _otherUserFuture = _profileService.getPublicProfile(widget.otherUserId).then((data) => model.User(
      id: data['id'],
      username: data['username'],
      email: '', // Not needed
      avatarEmoji: data['avatar_emoji'],
      inviteId: '', // Not needed
      connectionStatus: data['connection_status'],
      profilePhotos: data['profile_photos'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FutureBuilder<model.User>(
          future: _otherUserFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return GestureDetector(
              onTap: () {
                if (user != null && user.profilePhotos != null && user.profilePhotos!.isNotEmpty) {
                  _showPhotos(context, user);
                }
              },
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null) Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(user.avatarEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      Text(
                        widget.otherUserName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  Text(
                    'Private History',
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.black54, letterSpacing: 1),
                  ),
                ],
              ),
            );
          }
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/send-moment/${widget.otherUserId}/${widget.otherUserName}');
        },
        backgroundColor: AppTheme.deepPurple,
        label: const Text('Send Pulse', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Text('💓', style: TextStyle(fontSize: 20)),
      ),
      body: FutureBuilder<List<Moment>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.deepPurple));
          }
          
          final moments = snapshot.data ?? [];
          if (moments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'No shared heartbeats yet.',
                    style: GoogleFonts.outfit(color: Colors.black45),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              final isMe = moment.senderId != widget.otherUserId;

              return Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildMomentBubble(moment, isMe),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMomentBubble(Moment moment, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.deepPurple.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMe ? AppTheme.deepPurple.withOpacity(0.1) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(moment.emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Text(
                DateFormat('h:mm a').format(moment.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            moment.text,
            style: GoogleFonts.outfit(fontSize: 16, height: 1.4),
          ),
          if (moment.replies.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            ...moment.replies.map((reply) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(reply.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reply.text,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _showPhotos(BuildContext context, model.User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('${user.username}\'s Spotlight', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                itemCount: user.profilePhotos!.length,
                itemBuilder: (context, index) {
                  final photo = user.profilePhotos![index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(photo['image'], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
