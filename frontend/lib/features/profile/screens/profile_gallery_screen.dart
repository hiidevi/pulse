import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class ProfileGalleryScreen extends StatefulWidget {
  const ProfileGalleryScreen({super.key});

  @override
  State<ProfileGalleryScreen> createState() => _ProfileGalleryScreenState();
}

class _ProfileGalleryScreenState extends State<ProfileGalleryScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  final _picker = ImagePicker();
  
  Map<int, dynamic> _photos = {}; // order -> photo data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getProfile();
      final photosList = user['profile_photos'] as List;
      final Map<int, dynamic> photoMap = {};
      for (var p in photosList) {
        photoMap[p['order']] = p;
      }
      setState(() {
        _photos = photoMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUpload(int order) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.uploadProfilePhoto(File(image.path), order);
      await _loadProfile(); // Refresh
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    setState(() => _isLoading = true);
    try {
      await _profileService.deleteProfilePhoto(photoId);
      await _loadProfile();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.deepPurple),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile Gallery',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.deepPurple),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepPurple))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Spotlight',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.deepPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload up to 4 high-res photos to let your friends see the real you.',
                      style: GoogleFonts.outfit(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final order = index + 1;
                          final photo = _photos[order];
                          
                          return _buildPhotoSlot(order, photo);
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

  Widget _buildPhotoSlot(int order, dynamic photo) {
    return GestureDetector(
      onTap: () => _pickAndUpload(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          image: photo != null 
            ? DecorationImage(
                image: NetworkImage(photo['image']),
                fit: BoxFit.cover,
              )
            : null,
        ),
        child: Stack(
          children: [
            if (photo == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppTheme.deepPurple),
                    const SizedBox(height: 8),
                    Text(
                      'Spot $order',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.deepPurple, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (photo != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deletePhoto(photo['id']),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
