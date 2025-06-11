import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class IdentificationProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final List<IdentificationModel> _identifications = [];
  IdentificationModel? _currentIdentification;
  bool _isLoading = false;
  String? _error;
  
  // Untuk filter
  String _filterType = 'all'; // 'all', 'flora', 'fauna'
  String _sortBy = 'latest'; // 'latest', 'oldest'
  String _searchQuery = '';
  
  // Box name untuk penyimpanan identifikasi
  static const String _boxName = 'identificationsBox';
  
  // Getters
  List<IdentificationModel> get identifications => _getFilteredIdentifications();
  IdentificationModel? get currentIdentification => _currentIdentification;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterType => _filterType;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;
  
  // Inisialisasi provider
  Future<void> init() async {
    try {
      final box = Hive.box(_boxName);
      
      // Load data identifikasi dari Hive
      final identificationsData = box.values.toList();
      _identifications.clear();
      
      for (final data in identificationsData) {
        if (data is Map) {
          try {
            final identification = IdentificationModel(
              id: data['id'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              type: data['type'] ?? '',
              commonName: data['commonName'] ?? '',
              scientificName: data['scientificName'] ?? '',
              confidenceLevel: (data['confidenceLevel'] as num?)?.toDouble() ?? 0.0,
              description: data['description'] ?? '',
              habitat: data['habitat'] ?? '',
              taxonomy: Map<String, String>.from(data['taxonomy'] ?? {}),
              conservationStatus: data['conservationStatus'] ?? '',
              createdAt: data['createdAt'] != null 
                  ? DateTime.parse(data['createdAt']) 
                  : DateTime.now(),
              hasQuiz: data['hasQuiz'] ?? false,
            );
            
            _identifications.add(identification);
          } catch (e) {
            debugPrint('Error parsing identification: $e');
          }
        }
      }
      
      // Sort berdasarkan tanggal terbaru
      _sortIdentifications();
    } catch (e) {
      debugPrint('Error saat inisialisasi IdentificationProvider: $e');
    }
    
    notifyListeners();
  }
  
  // Mengambil gambar dari kamera
  Future<File?> getImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // Di web, kita tidak dapat mengembalikan File langsung
          // Tetapi kita akan menggunakan XFile untuk mendapatkan Uint8List
          final bytes = await pickedFile.readAsBytes();
          // Sekarang kita gunakan bytes langsung untuk identifikasi di web
          await _identifyImageBytesForWeb(bytes);
          return null; // File tidak bisa dikembalikan di web
        } else {
          return File(pickedFile.path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error mengambil gambar dari kamera: $e');
      return null;
    }
  }
  
  // Mengambil gambar dari galeri
  Future<File?> getImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // Di web, kita tidak dapat mengembalikan File langsung
          // Tetapi kita akan menggunakan XFile untuk mendapatkan Uint8List
          final bytes = await pickedFile.readAsBytes();
          // Sekarang kita gunakan bytes langsung untuk identifikasi di web
          await _identifyImageBytesForWeb(bytes);
          return null; // File tidak bisa dikembalikan di web
        } else {
          return File(pickedFile.path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error mengambil gambar dari galeri: $e');
      return null;
    }
  }
  
  // Khusus untuk web: identifikasi dari bytes langsung
  Future<bool> _identifyImageBytesForWeb(Uint8List bytes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Gunakan metode identifikasi dari bytes di GeminiService
      final identification = await _geminiService.identifySpeciesFromBytes(bytes);
      
      if (identification != null) {
        _currentIdentification = identification;
        _identifications.add(identification);
        
        try {
          // Simpan ke penyimpanan lokal
          final box = Hive.box(_boxName);
          await box.put(identification.id, {
            'id': identification.id,
            'imageUrl': identification.imageUrl,
            'type': identification.type,
            'commonName': identification.commonName,
            'scientificName': identification.scientificName,
            'confidenceLevel': identification.confidenceLevel,
            'description': identification.description,
            'habitat': identification.habitat,
            'taxonomy': identification.taxonomy,
            'conservationStatus': identification.conservationStatus,
            'createdAt': identification.createdAt.toIso8601String(),
            'hasQuiz': identification.hasQuiz,
          });
        } catch (e) {
          debugPrint('Error saat menyimpan ke Hive: $e');
        }
        
        // Sort ulang
        _sortIdentifications();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Gagal mengidentifikasi, coba lagi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Identifikasi spesies dari gambar
  Future<bool> identifySpecies(File? imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Untuk web, file akan null karena sudah ditangani di getImage... methods
      if (kIsWeb && imageFile == null) {
        // Identifikasi sudah dilakukan di _identifyImageBytesForWeb
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      final identification = await _geminiService.identifySpecies(imageFile);
      
      if (identification != null) {
        _currentIdentification = identification;
        _identifications.add(identification);
        
        try {
          // Simpan ke penyimpanan lokal
          final box = Hive.box(_boxName);
          await box.put(identification.id, {
            'id': identification.id,
            'imageUrl': identification.imageUrl,
            'type': identification.type,
            'commonName': identification.commonName,
            'scientificName': identification.scientificName,
            'confidenceLevel': identification.confidenceLevel,
            'description': identification.description,
            'habitat': identification.habitat,
            'taxonomy': identification.taxonomy,
            'conservationStatus': identification.conservationStatus,
            'createdAt': identification.createdAt.toIso8601String(),
            'hasQuiz': identification.hasQuiz,
          });
        } catch (e) {
          debugPrint('Error saat menyimpan ke Hive: $e');
          // Lanjutkan meskipun penyimpanan gagal
        }
        
        // Sort ulang
        _sortIdentifications();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Gagal mengidentifikasi, coba lagi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Mendapatkan identification berdasarkan ID
  IdentificationModel? getIdentificationById(String id) {
    try {
      return _identifications.firstWhere((item) => item.id == id);
    } catch (e) {
      debugPrint('Identification dengan ID $id tidak ditemukan');
      return null;
    }
  }
  
  // Set current identification
  void setCurrentIdentification(String id) {
    _currentIdentification = _identifications.firstWhere(
      (identification) => identification.id == id,
      orElse: () => _identifications.first,
    );
    notifyListeners();
  }
  
  // Update status quiz untuk identifikasi
  Future<void> updateHasQuiz(String identificationId, bool hasQuiz) async {
    final index = _identifications.indexWhere((i) => i.id == identificationId);
    
    if (index != -1) {
      final identification = _identifications[index];
      final updatedIdentification = identification.copyWith(hasQuiz: hasQuiz);
      
      _identifications[index] = updatedIdentification;
      
      if (_currentIdentification?.id == identificationId) {
        _currentIdentification = updatedIdentification;
      }
      
      try {
        final box = Hive.box(_boxName);
        await box.put(identificationId, {
          'id': updatedIdentification.id,
          'imageUrl': updatedIdentification.imageUrl,
          'type': updatedIdentification.type,
          'commonName': updatedIdentification.commonName,
          'scientificName': updatedIdentification.scientificName,
          'confidenceLevel': updatedIdentification.confidenceLevel,
          'description': updatedIdentification.description,
          'habitat': updatedIdentification.habitat,
          'taxonomy': updatedIdentification.taxonomy,
          'conservationStatus': updatedIdentification.conservationStatus,
          'createdAt': updatedIdentification.createdAt.toIso8601String(),
          'hasQuiz': updatedIdentification.hasQuiz,
        });
      } catch (e) {
        debugPrint('Error saat update hasQuiz ke Hive: $e');
        // Lanjutkan meskipun penyimpanan gagal
      }
      
      notifyListeners();
    }
  }
  
  // Set filter
  void setFilter(String filterType) {
    _filterType = filterType;
    notifyListeners();
  }
  
  // Set sort
  void setSort(String sortBy) {
    _sortBy = sortBy;
    _sortIdentifications();
    notifyListeners();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Reset filter
  void resetFilter() {
    _filterType = 'all';
    _sortBy = 'latest';
    _searchQuery = '';
    _sortIdentifications();
    notifyListeners();
  }
  
  // Filter identifikasi berdasarkan kriteria
  List<IdentificationModel> _getFilteredIdentifications() {
    List<IdentificationModel> filteredList = List.from(_identifications);
    
    // Filter berdasarkan tipe
    if (_filterType != 'all') {
      filteredList = filteredList.where((i) => i.type == _filterType).toList();
    }
    
    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((i) {
        final name = i.commonName.toLowerCase();
        final scientific = i.scientificName.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || scientific.contains(query);
      }).toList();
    }
    
    return filteredList;
  }
  
  // Sort identifikasi
  void _sortIdentifications() {
    if (_sortBy == 'latest') {
      _identifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _identifications.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }
} 