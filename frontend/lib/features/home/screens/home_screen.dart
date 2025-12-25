import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../services/settings_service.dart';
import '../../../services/moment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/connection_service.dart';
import '../../../models/moment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  final _momentService = MomentService();
  final _audioPlayer = AudioPlayer();
  final _settingsService = SettingsService();
  final _authService = AuthService();
  final _connectionService = ConnectionService();

  late Future<List<Moment>> _recentMomentsFuture;
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _pendingRequestsFuture;
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  Timer? _pollTimer;
  int? _lastMomentId;
  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
    _startPolling();
  }

  void _loadData() {
    setState(() {
      _recentMomentsFuture = _momentService.getMemories().then((moments) {
        if (moments.isNotEmpty && _lastMomentId == null) {
          _lastMomentId = moments.first.id;
        }
        return moments;
      });
      _profileFuture = _authService.getProfile();
      _pendingRequestsFuture = _connectionService.getPendingRequests();
      _friendsFuture = _connectionService.getFriends();
    });
  }

  int? _lastReplyId;
  int? _lastRequestId;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;
      
      try {
        final activity = await _momentService.getRecentActivity();
        final List momentsData = activity['moments'] ?? [];
        final List repliesData = activity['replies'] ?? [];
        final List pendingRequests = activity['pending_requests'] ?? [];

        // 1. Handle New Moments
        if (momentsData.isNotEmpty) {
          final latestMoment = Moment.fromJson(momentsData.first);
          if (_lastMomentId != null && latestMoment.id > _lastMomentId!) {
            _lastMomentId = latestMoment.id;
            _showPulseNotification(latestMoment, isReply: false);
            _loadData();
          } else if (_lastMomentId == null) {
            // If first time seeing a moment, show it if it's very fresh
            _lastMomentId = latestMoment.id;
            _showPulseNotification(latestMoment, isReply: false);
            _loadData();
          }
        }

        // 2. Handle New Replies (Reactions)
        if (repliesData.isNotEmpty) {
          final latestReply = repliesData.first;
          final replyId = latestReply['id'];
          if (_lastReplyId != null && replyId > _lastReplyId!) {
            _lastReplyId = replyId;
            _showReactionNotification(latestReply);
            _loadData();
          } else if (_lastReplyId == null) {
            _lastReplyId = replyId;
            _showReactionNotification(latestReply);
            _loadData();
          }
        }
        // 3. Handle Connection Requests
        if (pendingRequests.isNotEmpty) {
          final latestReq = pendingRequests.first;
          final reqId = latestReq['id'];
          
          if (_lastRequestId != null && reqId > _lastRequestId!) {
            _lastRequestId = reqId;
            _showFloatingOverlay(
              emoji: '💌',
              title: 'Circle Request',
              subtitle: '${latestReq['requester']['username']} wants to join your circle!',
              onTap: () => _loadData(),
            );
          } else if (_lastRequestId == null) {
            _lastRequestId = reqId;
            _showFloatingOverlay(
              emoji: '💌',
              title: 'Circle Request',
              subtitle: '${latestReq['requester']['username']} wants to join your circle!',
              onTap: () => _loadData(),
            );
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
        if (e.toString().contains('401')) {
          _pollTimer?.cancel();
          if (mounted) context.go('/onboarding');
        }
      }
    });
  }

  void _showReactionNotification(Map<String, dynamic> reply) {
    final text = reply['text'] ?? '';
    final sender = reply['sender']['username'] ?? 'Somebody';
    
    // If text starts with "Reacted with", treat it as a reaction
    final isReaction = text.startsWith('Reacted with') || text.length < 5;
    
    _showFloatingOverlay(
      emoji: reply['emoji'],
      title: isReaction ? '$sender reacted' : '$sender replied',
      subtitle: text,
      onTap: () {
        // Clear or navigate
      },
    );
  }

  void _showPulseNotification(Moment moment, {required bool isReply}) {
    _showFloatingOverlay(
      emoji: moment.emoji,
      title: '${moment.senderName} sent a heartbeat',
      subtitle: moment.text,
      onTap: () {
        context.push('/reveal', extra: moment);
      },
    );
  }

  void _showFloatingOverlay({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    if (_notificationOverlay != null) {
      _notificationOverlay!.remove();
    }

    final emotionalTheme = AppTheme.getEmojiTheme(emoji);

    // Play pulse sound if enabled
    if (_settingsService.notificationsEnabled.value) {
      _audioPlayer.play(AssetSource('sounds/pulse.mp3')).catchError((e) => debugPrint('Audio error: $e'));
    }

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: -100.0, end: 0.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                _notificationOverlay?.remove();
                _notificationOverlay = null;
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: emotionalTheme['gradient'],
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (emotionalTheme['shadow'] as Color).withOpacity(0.4), 
                      blurRadius: 30, 
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                        ],
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, 
                              color: Colors.white, 
                              fontSize: 16,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9), 
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () {
                        if (_notificationOverlay != null) {
                          _notificationOverlay!.remove();
                          _notificationOverlay = null;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_notificationOverlay!);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _notificationOverlay?.remove();
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _respondToRequest(int connectionId, String status) async {
    try {
      await _connectionService.respondToConnection(connectionId, status);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Circle Request $status ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pulse', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.deepPurple)),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.deepPurple),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.settings_outlined, color: AppTheme.deepPurple),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Profile & Greeting
                  FutureBuilder<Map<String, dynamic>>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final name = snapshot.data?['username'] ?? 'Friend';
                      final avatar = snapshot.data?['avatar_emoji'] ?? '👤';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.5),
                              child: Text(avatar, style: const TextStyle(fontSize: 30)),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_getGreeting()},', style: const TextStyle(color: Colors.black54)),
                                Text('$name ✨', style: themeText(context).headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Pending Requests Section
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _pendingRequestsFuture,
                    builder: (context, snapshot) {
                      final requests = snapshot.data ?? [];
                      if (requests.isEmpty) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassBox.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('💌', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('New Circle Requests', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepPurple)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...requests.map((req) {
                              final sender = req['requester'];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      child: Text(sender['avatar_emoji'] ?? '👤'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(sender['username'], style: const TextStyle(fontWeight: FontWeight.w600))),
                                    IconButton(
                                      onPressed: () => _respondToRequest(req['id'], 'REJECTED'), 
                                      icon: const Icon(Icons.close, color: Colors.black38, size: 20)
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      onPressed: () => _respondToRequest(req['id'], 'ACCEPTED'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.deepPurple,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  
                  // Main Pulse Button
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Colors.white, Color(0xFFFFB6C1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('💓', style: TextStyle(fontSize: 70)),
                              SizedBox(height: 4),
                              Text(
                                'Send Love',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.deepPurple,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Your Circle (Friends List)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Circle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        TextButton(
                          onPressed: () => context.push('/search'), 
                          child: const Text('Add Member')
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _friendsFuture,
                      builder: (context, snapshot) {
                        final friendsRaw = snapshot.data ?? [];
                        if (friendsRaw.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Your circle is quiet. Invite someone to start sharing heartbeats.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black38, fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ),
                          );
                        }
                        
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _profileFuture,
                          builder: (context, profileSnapshot) {
                            if (!profileSnapshot.hasData) return const SizedBox.shrink();
                            
                            final myId = profileSnapshot.data?['id'];
                            
                            // Deduplicate friends by ID to prevent UI glitches if data is messy
                            final Map<int, Map<String, dynamic>> dedupedFriends = {};
                            for (var f in friendsRaw) {
                              final friend = (f['requester']['id'] == myId) 
                                  ? f['receiver'] 
                                  : f['requester'];
                              dedupedFriends[friend['id']] = f;
                            }
                            final friends = dedupedFriends.values.toList();
                            
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              scrollDirection: Axis.horizontal,
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                final friendData = friends[index];
                                final friend = friendData['requester']['id'] == myId 
                                    ? friendData['receiver'] 
                                    : friendData['requester'];

                                return GestureDetector(
                                  onTap: () => context.push('/conversation/${friend['id']}/${friend['username']}'),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 20),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.primaryPink.withOpacity(0.5), width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white.withOpacity(0.8),
                                            child: Text(friend['avatar_emoji'] ?? '👤', style: const TextStyle(fontSize: 30)),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          friend['username'], 
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        );
                      },
                    ),
                  ),

                  // Recent Moments Section
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(minHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Heartbeats', style: themeText(context).titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => context.push('/memories'),
                              child: const Text('Full History'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Moment>>(
                          future: _recentMomentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppTheme.deepPurple));
                            }
                            
                            final moments = snapshot.data ?? [];
                            if (moments.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Column(
                                    children: [
                                      Text('✨', style: TextStyle(fontSize: 40)),
                                      SizedBox(height: 8),
                                      Text(
                                        'No heartbeats yet.\nBe the first to send a moment.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: moments.length > 5 ? 5 : moments.length,
                              itemBuilder: (context, index) {
                                final moment = moments[index];
                                return GestureDetector(
                                  onTap: () => context.push('/reveal', extra: moment),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: AppTheme.glassBox,
                                    child: Row(
                                      children: [
                                        Text(moment.emoji, style: const TextStyle(fontSize: 32)),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(moment.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              Text(
                                                moment.text,
                                                style: const TextStyle(color: Colors.black87),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          DateFormat.jm().format(moment.createdAt),
                                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextTheme themeText(BuildContext context) => Theme.of(context).textTheme;
}
