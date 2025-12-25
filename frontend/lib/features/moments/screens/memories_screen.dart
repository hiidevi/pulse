import 'package:flutter/material.dart';
import '../../../models/moment.dart';
import '../../../services/moment_service.dart';
import '../../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  late Future<List<Moment>> _memoriesFuture;

  @override
  void initState() {
    super.initState();
    _memoriesFuture = MomentService().getMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Memories', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepPurple)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Your circle of care, preserved in time.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Moment>>(
                  future: _memoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.deepPurple));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Failed to load memories.'));
                    }
                    
                    final memories = snapshot.data ?? [];
                    if (memories.isEmpty) {
                      return const Center(child: Text('No memories yet. Send a moment to start your album!'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: memories.length,
                      itemBuilder: (context, index) {
                        final moment = memories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.glassBox.copyWith(
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(moment.emoji, style: const TextStyle(fontSize: 40)),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(moment.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(
                                        DateFormat('MMM d, h:mm a').format(moment.createdAt),
                                        style: const TextStyle(color: Colors.black45, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                moment.text,
                                style: const TextStyle(fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
