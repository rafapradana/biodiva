import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/constants/app_theme.dart';

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
    
    // Inisialisasi provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IdentificationProvider>(context, listen: false).init();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Identifier'),
        centerTitle: true,
      ),
      body: Consumer<IdentificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang Mengidentifikasi...'),
                ],
              ),
            );
          }
          
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
                  'Belum Ada Identifikasi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mulai identifikasi flora dan fauna dengan menekan tombol kamera',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Mulai Identifikasi'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
} 