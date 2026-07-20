import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:storage_client/storage_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hydrodok/src/core/service/farm_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Manual mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// ─────────────────────────────────────────────────────────────────────────────
//  Controlled PostgrestFilterBuilder — overrides then() so the update+eq
//  chain can be awaited without mocktail's limitation with Future subtypes.
// ─────────────────────────────────────────────────────────────────────────────

class _ControlledFilter extends PostgrestFilterBuilder<PostgrestList> {
  _ControlledFilter()
      : super(
          PostgrestBuilder<PostgrestList, PostgrestList, PostgrestList>(
            url: Uri.parse('http://localhost/'),
            headers: <String, String>{},
          ),
        );

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList)? onValue, {
    Function? onError,
  }) {
    if (onValue != null) {
      final result = onValue(<Map<String, dynamic>>[]);
      if (result is Future<R>) return result;
      return Future<R>.value(result as R);
    }
    return Future<R>.value(null as R);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    return _ControlledFilter();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fallback values for mocktail
// ─────────────────────────────────────────────────────────────────────────────

class _FileFake extends Fake implements File {}

class _FileOptionsFake extends Fake implements FileOptions {}

void main() {
  late MockSupabaseClient supabase;
  late MockStorageFileApi mockStorageFile;
  late MockSupabaseQueryBuilder mockFarmQuery;

  setUpAll(() {
    registerFallbackValue(_FileFake());
    registerFallbackValue(_FileOptionsFake());
  });

  setUp(() {
    supabase = MockSupabaseClient();
    mockStorageFile = MockStorageFileApi();
    mockFarmQuery = MockSupabaseQueryBuilder();

    when(() => supabase.from('farms')).thenAnswer((_) => mockFarmQuery);
    when(() => mockFarmQuery.update(any()))
        .thenAnswer((_) => _ControlledFilter());
  });

  // ── updateFarm ─────────────────────────────────────────────────────────

  group('updateFarm', () {
    late FarmService service;

    setUp(() {
      service = FarmService(
        supabase: supabase,
        storageBucket: mockStorageFile,
      );
    });

    test('updates description and photo_url when both provided', () async {
      await service.updateFarm(
        _ownerId,
        description: 'Green Valley Farm',
        photoUrl: _photoUrl,
      );

      final captured =
          verify(() => mockFarmQuery.update(captureAny())).captured;
      final values = captured.first as Map<String, dynamic>;
      expect(values['description'], 'Green Valley Farm');
      expect(values['photo_url'], _photoUrl);
      expect(values.containsKey('updated_at'), isTrue);
    });

    test('updates only description when photo_url is null', () async {
      await service.updateFarm(_ownerId, description: 'Organic farm');

      final captured =
          verify(() => mockFarmQuery.update(captureAny())).captured;
      final values = captured.first as Map<String, dynamic>;
      expect(values['description'], 'Organic farm');
      expect(values.containsKey('photo_url'), isFalse);
      expect(values.containsKey('updated_at'), isTrue);
    });

    test('updates only photo_url when description is null', () async {
      await service.updateFarm(_ownerId, photoUrl: _photoUrl);

      final captured =
          verify(() => mockFarmQuery.update(captureAny())).captured;
      final values = captured.first as Map<String, dynamic>;
      expect(values['photo_url'], _photoUrl);
      expect(values.containsKey('description'), isFalse);
      expect(values.containsKey('updated_at'), isTrue);
    });
  });

  // ── uploadFarmPhoto ────────────────────────────────────────────────────

  group('uploadFarmPhoto', () {
    late FarmService service;

    setUp(() {
      service = FarmService(
        supabase: supabase,
        storageBucket: mockStorageFile,
      );
    });

    test('uploads to farm-images bucket at ownerId/farm_photo.jpg', () async {
      when(() => mockStorageFile.upload(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          )).thenAnswer((_) async => 'user-123/farm_photo.jpg');
      when(() => mockStorageFile.getPublicUrl(any())).thenReturn(_photoUrl);

      final url = await service.uploadFarmPhoto(_ownerId, _fakeFile);

      expect(url, _photoUrl);
      verify(() => mockStorageFile.upload(
            'user-123/farm_photo.jpg',
            _fakeFile,
            fileOptions: any(named: 'fileOptions'),
          )).called(1);
      verify(() => mockStorageFile.getPublicUrl('user-123/farm_photo.jpg'))
          .called(1);
    });

    test('upload uses upsert true and image/jpeg contentType', () async {
      FileOptions? capturedOptions;
      when(() => mockStorageFile.upload(
            any(),
            any(),
            fileOptions: captureAny(named: 'fileOptions'),
          )).thenAnswer((invocation) {
        capturedOptions =
            invocation.namedArguments[Symbol('fileOptions')] as FileOptions?;
        return Future.value('user-123/farm_photo.jpg');
      });
      when(() => mockStorageFile.getPublicUrl(any())).thenReturn(_photoUrl);

      await service.uploadFarmPhoto(_ownerId, _fakeFile);

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.upsert, isTrue);
      expect(capturedOptions!.contentType, 'image/jpeg');
    });
  });

  // ── submitVerification ─────────────────────────────────────────────────

  group('submitVerification', () {
    late FarmService service;

    setUp(() {
      service = FarmService(
        supabase: supabase,
        storageBucket: mockStorageFile,
      );
    });

    test('uploads document and sets verification_status to pending',
        () async {
      when(() => mockStorageFile.upload(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          )).thenAnswer((_) async => 'user-123/verification/dti.jpg');
      when(() => mockStorageFile.getPublicUrl(any())).thenReturn(_docPublicUrl);

      // Capture the update values via a stub answer
      Map? capturedUpdate;
      when(() => mockFarmQuery.update(captureAny())).thenAnswer((inv) {
        capturedUpdate = inv.positionalArguments[0] as Map?;
        return _ControlledFilter();
      });

      await service.submitVerification(_ownerId, _fakeFile, 'dti');

      // Verify storage upload path
      verify(() => mockStorageFile.upload(
            'user-123/verification/dti.jpg',
            _fakeFile,
            fileOptions: any(named: 'fileOptions'),
          )).called(1);

      // Verify DB update values
      expect(capturedUpdate, isNotNull);
      expect(capturedUpdate!['verification_status'], 'pending');
      expect(capturedUpdate!['verification_doc_url'], _docPublicUrl);
      expect(capturedUpdate!.containsKey('updated_at'), isTrue);
    });
  });

  // ── skipVerification ───────────────────────────────────────────────────

  group('skipVerification', () {
    late FarmService service;

    setUp(() {
      service = FarmService(
        supabase: supabase,
        storageBucket: mockStorageFile,
      );
    });

    test('sets verification_status to skipped', () async {
      Map? capturedUpdate;
      when(() => mockFarmQuery.update(captureAny())).thenAnswer((inv) {
        capturedUpdate = inv.positionalArguments[0] as Map?;
        return _ControlledFilter();
      });

      await service.skipVerification(_ownerId);

      expect(capturedUpdate, isNotNull);
      expect(capturedUpdate!['verification_status'], 'unverified');
      expect(capturedUpdate!.containsKey('updated_at'), isTrue);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Test data
// ─────────────────────────────────────────────────────────────────────────────

final _fakeFile = File('/dev/null');
const _ownerId = 'user-123';
const _photoUrl =
    'https://example.com/storage/farm-images/user-123/farm_photo.jpg';
const _docPublicUrl =
    'https://example.com/storage/farm-images/user-123/verification/dti.jpg';
