import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/moment_service.dart';
import 'package:go_router/go_router.dart';

class SendMomentScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const SendMomentScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<SendMomentScreen> createState() => _SendMomentScreenState();
}

class _SendMomentScreenState extends State<SendMomentScreen> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _momentService = MomentService();
  String _selectedEmoji = '❤️';
  String _selectedEmotion = 'Thinking of You';
  bool _isLoading = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  // Expanded emotional palette
  final List<String> _emojis = [
    // Warm Love
    '❤️', '💖', '🌹', '🫂', '💓', '💗', '💌', '🥰', '💝', '🫶',
    // High Energy
    '🔥', '✨', '⚡', '💥', '🚀', '🎉', '🏆', '🤩', '🎯', '👑',
    // Calm
    '🌿', '🕊️', '🧘', '🍃', '🍀', '🌲', '🍵', '☀️', '🌻',
    // Mystical
    '🌌', '🌚', '🔮', '💤', '🪐', '🌙', '💜', '🦄', '🎭',
    // Flow
    '🥺', '😭', '🌊', '💧', '☁️', '❄️', '🧊', '⚓', '🎐'
  ];
  final List<String> _emotions = [
    'Thinking of You', 
    'Miss You', 
    'Love You', 
    'So Proud', 
    'In My Prayers', 
    'Deepest Care', 
    'Celebrating You', 
    'Healing Hug',
    'Rooting for You',
    'Stay Strong',
    'Dream Big'
  ];

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutExpo),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMoment() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share a feeling before sending ✨')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      _heartController.forward();
      
      final receiverIdInt = int.parse(widget.receiverId);
      final fullText = '[$_selectedEmotion] ${_textController.text.trim()}';
      
      await _momentService.sendMoment(
        receiverIdInt,
        fullText,
        _selectedEmoji,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sent with love and light ✨')),
        );
      }
    } catch (e) {
      _heartController.reverse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: AppTheme.deepPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To ${widget.receiverName}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // Emotion Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _emotions.map((emotion) {
                        final isSelected = _selectedEmotion == emotion;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmotion = emotion),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.deepPurple : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              emotion,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.deepPurple,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassBox,
                    child: Column(
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'What are you feeling?',
                            hintStyle: TextStyle(color: Colors.black38),
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                        const Spacer(),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _emojis.map((emoji) {
                              final isSelected = _selectedEmoji == emoji;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedEmoji = emoji),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: _heartScale,
                          child: FadeTransition(
                            opacity: ReverseAnimation(_heartController),
                            child: const Text('❤️', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _sendMoment,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.deepPurple,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.deepPurple.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Release the Moment',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
