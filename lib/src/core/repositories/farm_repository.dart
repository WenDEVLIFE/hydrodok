import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/farm_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Abstract Farm Repository Interface
// ─────────────────────────────────────────────────────────────────────────────

/// Clean domain interface for all farm-related data operations, retrieval,
/// photo uploads, location pinning, and verification workflows.
abstract class FarmRepository {
  /// Creates a new hydroponic farm entry for [ownerId].
  Future<void> createFarm({
    required String ownerId,
    required String farmName,
    required String address,
    required List<String> produceTypes,
    String? description,
    String? photoUrl,
  });

  /// Updates farm details (description, photo, coordinates, address).
  Future<void> updateFarm(
    String ownerId, {
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
  });

  /// Uploads farm photo to storage.
  Future<String> uploadFarmPhoto(String ownerId, File imageFile);

  /// Uploads verification document and sets status to pending.
  Future<String> submitVerification(
    String ownerId,
    File documentFile,
    String docType,
  );

  /// Skips farm verification.
  Future<void> skipVerification(String ownerId);

  /// Retrieves all admin-verified, published farms for live map rendering.
  Future<List<Map<String, dynamic>>> getVerifiedFarms();

  /// Retrieves pending farm verification requests for admin review.
  Future<List<Map<String, dynamic>>> getPendingFarms();

  /// Retrieves farm details for a given [ownerId].
  Future<Map<String, dynamic>?> getFarmByOwnerId(String ownerId);

  /// Approves farm verification request and publishes to live map.
  Future<void> approveFarmVerification(String farmId);

  /// Rejects farm verification request with an optional denial reason.
  Future<void> rejectFarmVerification(String farmId, {String? reason});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supabase-backed Farm Repository Implementation
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseFarmRepository implements FarmRepository {
  final FarmService _farmService;

  SupabaseFarmRepository({FarmService? farmService, SupabaseClient? supabaseClient})
      : _farmService = farmService ??
            FarmService(supabase: supabaseClient ?? Supabase.instance.client);

  @override
  Future<void> createFarm({
    required String ownerId,
    required String farmName,
    required String address,
    required List<String> produceTypes,
    String? description,
    String? photoUrl,
  }) {
    return _farmService.createFarm(
      ownerId: ownerId,
      farmName: farmName,
      address: address,
      produceTypes: produceTypes,
      description: description,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> updateFarm(
    String ownerId, {
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return _farmService.updateFarm(
      ownerId,
      description: description,
      photoUrl: photoUrl,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  @override
  Future<String> uploadFarmPhoto(String ownerId, File imageFile) {
    return _farmService.uploadFarmPhoto(ownerId, imageFile);
  }

  @override
  Future<String> submitVerification(
    String ownerId,
    File documentFile,
    String docType,
  ) {
    return _farmService.submitVerification(ownerId, documentFile, docType);
  }

  @override
  Future<void> skipVerification(String ownerId) {
    return _farmService.skipVerification(ownerId);
  }

  @override
  Future<List<Map<String, dynamic>>> getVerifiedFarms() {
    return _farmService.getVerifiedFarms();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingFarms() {
    return _farmService.getPendingFarms();
  }

  @override
  Future<Map<String, dynamic>?> getFarmByOwnerId(String ownerId) {
    return _farmService.getFarmByOwnerId(ownerId);
  }

  @override
  Future<void> approveFarmVerification(String farmId) {
    return _farmService.approveFarmVerification(farmId);
  }

  @override
  Future<void> rejectFarmVerification(String farmId, {String? reason}) {
    return _farmService.rejectFarmVerification(farmId, reason: reason);
  }
}
