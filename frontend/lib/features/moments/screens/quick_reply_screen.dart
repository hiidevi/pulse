import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/moment_service.dart';

class QuickReplyScreen extends StatefulWidget {
  final int momentId;
  final String senderName;
  final String originalEmoji;

  const QuickReplyScreen({
    super.key,
    required this.momentId,
    required this.senderName,
    required this.originalEmoji,
  });

  @override
  State<QuickReplyScreen> createState() => _QuickReplyScreenState();
}

class _QuickReplyScreenState extends State<QuickReplyScreen> {
  final _textController = TextEditingController();
  final _momentService = MomentService();
  bool _isLoading = false;
  bool _showEmojiPicker = false;

  Future<void> _sendReply() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a message first ✨')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find the first emoji or use default
      String emoji = '✨';
      final RegExp emojiRegex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
      final match = emojiRegex.firstMatch(text);
      if (match != null) {
        emoji = match.group(0)!;
      }

      await _momentService.sendReply(widget.momentId, text, emoji);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent with love ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reply to ${widget.senderName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: AppTheme.deepPurple),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                            if (_showEmojiPicker) {
                              FocusScope.of(context).unfocus();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('In response to: ${widget.originalEmoji}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: 2,
                    onTap: () {
                      if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a micro-message...',
                      hintStyle: const TextStyle(color: Colors.black38),
                      fillColor: Colors.black.withOpacity(0.05),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _textController.text += emoji.emoji;
                        },
                        config: Config(
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: Colors.transparent,
                            emojiSizeMax: 28,
                            columns: 7,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: Colors.white,
                            indicatorColor: AppTheme.deepPurple,
                            iconColorSelected: AppTheme.deepPurple,
                            dividerColor: Colors.transparent,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Send Pulse Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
