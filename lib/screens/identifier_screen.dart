import 'dart:io';

import 'package:biodiva/constants/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/providers/user_provider.dart';
import 'package:biodiva/models/identification_model.dart';
import 'package:intl/intl.dart';

class IdentifierScreen extends StatefulWidget {
  const IdentifierScreen({super.key});

  @override
  State<IdentifierScreen> createState() => _IdentifierScreenState();
}

class _IdentifierScreenState extends State<IdentifierScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Inisialisasi provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IdentificationProvider>(context, listen: false).init();
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = Provider.of<IdentificationProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Sumber Gambar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context: context,
                  icon: Icons.camera_alt,
                  title: AppStrings.takePhoto,
                  onTap: () => _getImage(true),
                ),
                _buildImageSourceOption(
                  context: context,
                  icon: Icons.photo_library,
                  title: AppStrings.fromGallery,
                  onTap: () => _getImage(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(bool isCamera) async {
    Navigator.pop(context); // Close bottom sheet
    
    final provider = Provider.of<IdentificationProvider>(context, listen: false);
    
    try {
      // Tampilkan loading melalui setState
      setState(() {
        // Loading indicator akan ditampilkan dari widget consumer
      });
      
      File? image;
      if (isCamera) {
        image = await provider.getImageFromCamera();
      } else {
        image = await provider.getImageFromGallery();
      }
      
      // Di web, image akan null tapi proses identifikasi sudah berjalan
      // di dalam provider.getImageFromCamera/Gallery
      if (context.mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Identifikasi gambar (pada platform web, ini hanya akan mengupdate state)
        final success = await provider.identifySpecies(image);
        
        if (success && context.mounted) {
          // Update statistik pengguna
          await userProvider.incrementIdentificationCount();
          
          // Navigasi ke detail
          final identification = provider.currentIdentification;
          if (identification != null) {
            context.go('/identifier/detail/${identification.id}');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.identifierTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onSelected: (value) {
                    Provider.of<IdentificationProvider>(context, listen: false)
                        .setFilter(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text(AppStrings.filterAll),
                    ),
                    const PopupMenuItem(
                      value: 'flora',
                      child: Text(AppStrings.filterFlora),
                    ),
                    const PopupMenuItem(
                      value: 'fauna',
                      child: Text(AppStrings.filterFauna),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onSelected: (value) {
                    Provider.of<IdentificationProvider>(context, listen: false)
                        .setSort(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'latest',
                      child: Text(AppStrings.sortLatest),
                    ),
                    const PopupMenuItem(
                      value: 'oldest',
                      child: Text(AppStrings.sortOldest),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // List identifications
          Expanded(
            child: Consumer<IdentificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(AppStrings.loadingIdentifying),
                      ],
                    ),
                  );
                }
                
                final identifications = provider.identifications;
                
                if (identifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noIdentifications,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppStrings.startIdentifying,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceOptions,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Mulai Identifikasi'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // List dengan hasil identifikasi
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: identifications.length,
                  itemBuilder: (context, index) {
                    final identification = identifications[index];
                    return _buildIdentificationCard(context, identification);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<IdentificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          return FloatingActionButton(
            onPressed: _showImageSourceOptions,
            child: const Icon(Icons.add_a_photo),
          );
        },
      ),
    );
  }
  
  Widget _buildIdentificationCard(BuildContext context, IdentificationModel identification) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(identification.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/identifier/detail/${identification.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildIdentificationImage(identification),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: identification.type == 'flora' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      identification.type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    identification.commonName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    identification.scientificName,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (identification.hasQuiz)
                        const Icon(
                          Icons.quiz,
                          color: Colors.blue,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationImage(IdentificationModel identification) {
    // Untuk web dan path spesial, gunakan placeholder
    if (kIsWeb && identification.imageUrl.startsWith('web_image_')) {
      return _buildPlaceholderImage(identification);
    } 
    
    // Path error atau kosong
    if (identification.imageUrl.isEmpty || 
        identification.imageUrl.startsWith('error_image_')) {
      return _buildPlaceholderImage(identification);
    }
    
    // Jika path menunjuk ke assets
    if (identification.imageUrl.startsWith('assets/')) {
      return Image.asset(
        identification.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error memuat gambar dari assets: $error');
          return _buildPlaceholderImage(identification);
        },
      );
    }
    
    // Untuk mobile, gunakan File jika file ada
    try {
      final file = File(identification.imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error memuat gambar file: $error');
            return _buildPlaceholderImage(identification);
          },
        );
      } else {
        debugPrint('File gambar tidak ditemukan: ${identification.imageUrl}');
        return _buildPlaceholderImage(identification);
      }
    } catch (e) {
      debugPrint('Error saat memuat gambar: $e');
      return _buildPlaceholderImage(identification);
    }
  }
  
  Widget _buildPlaceholderImage(IdentificationModel identification) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            identification.type == 'flora' ? Icons.local_florist : Icons.pets,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Gambar ${identification.type} - ${identification.commonName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 