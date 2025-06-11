import 'package:biodiva/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isFirstTime = true;
  
  // Box name untuk penyimpanan user
  static const String _boxName = 'userBox';
  static const String _userKey = 'user';
  
  UserModel? get user => _user;
  bool get isFirstTime => _isFirstTime;
  bool get isLoggedIn => _user != null;
  
  // Inisialisasi provider
  Future<void> init() async {
    final box = Hive.box(_boxName);
    
    // Cek apakah sudah ada data user
    if (box.containsKey(_userKey)) {
      final userData = box.get(_userKey);
      if (userData is Map) {
        _user = UserModel(
          name: userData['name'] ?? '',
          createdAt: userData['createdAt'] != null 
              ? DateTime.parse(userData['createdAt']) 
              : DateTime.now(),
          identifiedCount: userData['identifiedCount'] ?? 0,
          quizCount: userData['quizCount'] ?? 0,
        );
        _isFirstTime = false;
      }
    }
    
    notifyListeners();
  }
  
  // Setup user baru
  Future<void> setupUser(String name) async {
    final newUser = UserModel(name: name);
    _user = newUser;
    _isFirstTime = false;
    
    // Simpan ke penyimpanan lokal
    final box = Hive.box(_boxName);
    await box.put(_userKey, {
      'name': newUser.name,
      'createdAt': newUser.createdAt.toIso8601String(),
      'identifiedCount': newUser.identifiedCount,
      'quizCount': newUser.quizCount,
    });
    
    notifyListeners();
  }
  
  // Update statistik identifikasi
  Future<void> incrementIdentificationCount() async {
    if (_user == null) return;
    
    final updatedUser = _user!.copyWith(
      identifiedCount: _user!.identifiedCount + 1,
    );
    
    _user = updatedUser;
    
    // Update di penyimpanan lokal
    final box = Hive.box(_boxName);
    await box.put(_userKey, {
      'name': updatedUser.name,
      'createdAt': updatedUser.createdAt.toIso8601String(),
      'identifiedCount': updatedUser.identifiedCount,
      'quizCount': updatedUser.quizCount,
    });
    
    notifyListeners();
  }
  
  // Update statistik quiz
  Future<void> incrementQuizCount() async {
    if (_user == null) return;
    
    final updatedUser = _user!.copyWith(
      quizCount: _user!.quizCount + 1,
    );
    
    _user = updatedUser;
    
    // Update di penyimpanan lokal
    final box = Hive.box(_boxName);
    await box.put(_userKey, {
      'name': updatedUser.name,
      'createdAt': updatedUser.createdAt.toIso8601String(),
      'identifiedCount': updatedUser.identifiedCount,
      'quizCount': updatedUser.quizCount,
    });
    
    notifyListeners();
  }
} 