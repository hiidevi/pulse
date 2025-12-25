import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clipboard/clipboard.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/profile_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();
  final _profileService = ProfileService();
  late Future<Map<String, dynamic>> _profileFuture;
  
  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getProfile();
  }

  void _shareInviteId(String inviteId) {
    Share.share('Join me on Pulse! My Invite ID is: $inviteId ✨');
  }

  void _copyInviteId(String inviteId) {
    FlutterClipboard.copy(inviteId).then((value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite ID copied to clipboard! 📋')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.deepPurple));
              }
              
              final profile = snapshot.data ?? {};
              final name = profile['username'] ?? 'Friend';
              final email = profile['email'] ?? '';
              final inviteId = profile['invite_id'] ?? '---';
              final avatar = profile['avatar_emoji'] ?? '👤';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.deepPurple),
                        ),
                        const Spacer(),
                        const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.deepPurple)),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEmojiPicker(context, avatar),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white54,
                      child: Text(avatar, style: const TextStyle(fontSize: 60)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(email, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _settingsService.notificationsEnabled,
                        builder: (context, notificationsEnabled, _) {
                          return ValueListenableBuilder(
                            valueListenable: _settingsService.vibrationMode,
                            builder: (context, vibrationMode, _) {
                              return ListView(
                                children: [
                                  _buildSettingItem(
                                    Icons.photo_library_outlined, 
                                    'Profile Spotlight', 
                                    'Manage your 4-photo gallery',
                                    onTap: () => context.push('/profile/gallery'),
                                  ),
                                  const Divider(height: 32),
                                  _buildSettingItem(
                                    Icons.share_outlined, 
                                    'Your Invite ID', 
                                    inviteId,
                                    onTap: () => _copyInviteId(inviteId),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.share, size: 20, color: AppTheme.deepPurple),
                                      onPressed: () => _shareInviteId(inviteId),
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  _buildSettingItem(
                                    Icons.notifications_none_outlined, 
                                    'Notifications', 
                                    notificationsEnabled ? 'Subtle & calm style' : 'Disabled',
                                    onTap: () => _settingsService.toggleNotifications(),
                                    trailing: Switch(
                                      value: notificationsEnabled,
                                      onChanged: (val) => _settingsService.notificationsEnabled.value = val,
                                      activeColor: AppTheme.deepPurple,
                                    ),
                                  ),
                                  _buildSettingItem(
                                    Icons.vibration_outlined, 
                                    'Vibration Intensity', 
                                    vibrationMode,
                                    onTap: () {
                                      final modes = ['Soft pulse', 'Heartbeat', 'Echo', 'Disabled'];
                                      int nextIdx = (modes.indexOf(vibrationMode) + 1) % modes.length;
                                      _settingsService.setVibration(modes[nextIdx]);
                                    },
                                  ),
                                  const Divider(height: 32),
                                  TextButton(
                                    onPressed: () {
                                      ApiService.clearToken();
                                      context.go('/onboarding');
                                    },
                                    child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, String currentEmoji) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Update Your Vibe', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ep.EmojiPicker(
                onEmojiSelected: (category, emoji) async {
                  context.pop();
                  try {
                    await _profileService.updateProfile(avatarEmoji: emoji.emoji);
                    setState(() {
                      _profileFuture = _authService.getProfile();
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update emoji: $e')),
                      );
                    }
                  }
                },
                config: ep.Config(
                  emojiViewConfig: ep.EmojiViewConfig(
                    backgroundColor: Colors.transparent,
                    emojiSizeMax: 32,
                    columns: 7,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                  ),
                  categoryViewConfig: ep.CategoryViewConfig(
                    backgroundColor: Colors.white,
                    indicatorColor: AppTheme.deepPurple,
                    iconColorSelected: AppTheme.deepPurple,
                    backspaceColor: AppTheme.deepPurple,
                    categoryIcons: const ep.CategoryIcons(),
                  ),
                  bottomActionBarConfig: const ep.BottomActionBarConfig(enabled: false),
                  searchViewConfig: const ep.SearchViewConfig(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
