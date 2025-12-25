import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../services/connection_service.dart';
import '../../../models/user.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectionSearchScreen extends StatefulWidget {
  const ConnectionSearchScreen({super.key});

  @override
  State<ConnectionSearchScreen> createState() => _ConnectionSearchScreenState();
}

class _ConnectionSearchScreenState extends State<ConnectionSearchScreen> {
  final _searchController = TextEditingController();
  final _connectionService = ConnectionService();
  List<User> _searchResults = [];
  bool _isSearching = false;

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await _connectionService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(User user) async {
    try {
      await _connectionService.sendConnectionRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${user.username} ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: ${e.toString()}')),
        );
      }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: AppTheme.deepPurple),
                ),
                const SizedBox(height: 24),
                Text(
                  'Expand Your Circle',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find the ones you care about.',
                  style: TextStyle(color: Colors.black45),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _handleSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by username or Invite ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching 
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          onPressed: _handleSearch,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Results', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: _searchResults.isEmpty 
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? 'Type to search...' : 'No users found.',
                          style: const TextStyle(color: Colors.black45),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final isFriend = user.connectionStatus == 'ACCEPTED';
                          final isPending = user.connectionStatus == 'PENDING';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassBox,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (user.profilePhotos != null && user.profilePhotos!.isNotEmpty) {
                                      _showPhotos(context, user);
                                    }
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    child: Text(user.avatarEmoji),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('@${user.inviteId}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (isFriend)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('In Circle', style: TextStyle(color: AppTheme.deepPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Pending', style: TextStyle(color: Colors.black45, fontSize: 11)),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => _sendRequest(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: 0,
                                    ),
                                    child: const Text('Add'),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, color: AppTheme.deepPurple),
                                  onPressed: () => context.push('/send-moment/${user.id}/${user.username}'),
                                  tooltip: 'Send Pulse',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotos(BuildContext context, User user) {
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
