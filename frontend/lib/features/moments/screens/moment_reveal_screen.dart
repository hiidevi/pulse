import 'package:flutter/material.dart';
import '../../../models/moment.dart';
import '../../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../services/moment_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MomentRevealScreen extends StatefulWidget {
  final Moment moment;

  const MomentRevealScreen({super.key, required this.moment});

  @override
  State<MomentRevealScreen> createState() => _MomentRevealScreenState();
}

class _MomentRevealScreenState extends State<MomentRevealScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _emojiScale;
  late Animation<double> _textOpacity;

  final List<String> _reactions = [
    '❤️', '💖', '🔥', '✨', '🥺', '🫂', '😭', '🌹', '🕊️', '🌊', 
    '🎯', '👑', '🌿', '🔮', '🪐', '❄️', '🎐', '🫶', '💝', '🤩'
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _showReactionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 150,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const Text('Send an emotional vibe back', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _reactions.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () async {
                    final emoji = _reactions[index];
                    Navigator.pop(context); // Close sheet
                    
                    try {
                      final momentService = MomentService();
                      await momentService.sendReply(widget.moment.id, "Reacted with $emoji", emoji);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Sent $emoji back to ${widget.moment.senderName} ✨')),
                        );
                        Navigator.pop(this.context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Failed to send reaction: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(_reactions[index], style: const TextStyle(fontSize: 36)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotionalTheme = AppTheme.getEmojiTheme(widget.moment.emoji);
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: emotionalTheme['gradient']),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      ),
                      const Spacer(),
                      Text(
                        'PULSE FROM ${widget.moment.senderName.toUpperCase()}',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        ScaleTransition(
                          scale: _emojiScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Reflection glow
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      blurRadius: 100,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Text(widget.moment.emoji, style: const TextStyle(fontSize: 160)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        FadeTransition(
                          opacity: _textOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Column(
                              children: [
                                Text(
                                  widget.moment.text,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  DateFormat('EEEE, h:mm a').format(widget.moment.createdAt),
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Thread Section
                        if (widget.moment.replies.isNotEmpty) ...[
                          const SizedBox(height: 60),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MICRO-CONVERSATION',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...widget.moment.replies.map((reply) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(reply.emoji, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reply.text,
                                              style: const TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${reply.senderName} • ${DateFormat('h:mm a').format(reply.createdAt)}',
                                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Fixed Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.reply_rounded, 'Reply', () {
                        context.push('/quick-reply/${widget.moment.id}/${widget.moment.senderName}/${widget.moment.emoji}');
                      }),
                      _buildActionButton(Icons.favorite_rounded, 'React', _showReactionSheet),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
