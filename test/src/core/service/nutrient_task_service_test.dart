import 'package:flutter_test/flutter_test.dart';
import 'package:hydrodok/src/core/repositories/nutrient_task_repository.dart';
import 'package:hydrodok/src/core/service/nutrient_task_service.dart';
import 'package:mocktail/mocktail.dart';

class MockNutrientTaskService extends Mock implements NutrientTaskService {}

void main() {
  late MockNutrientTaskService mockService;
  late SupabaseNutrientTaskRepository repository;

  setUp(() {
    mockService = MockNutrientTaskService();
    repository = SupabaseNutrientTaskRepository(service: mockService);
  });

  group('SupabaseNutrientTaskRepository', () {
    test('logNutrient delegates to service with exact parameters', () async {
      when(() => mockService.logNutrient(
            farmId: 'farm-123',
            nutrientName: 'Masterblend 4-18-38',
            amount: 50.0,
            notes: 'Top up solution',
          )).thenAnswer((_) async => {
            'id': 'log-1',
            'farm_id': 'farm-123',
            'nutrient_name': 'Masterblend 4-18-38',
            'amount': 50.0,
            'notes': 'Top up solution',
          });

      final result = await repository.logNutrient(
        farmId: 'farm-123',
        nutrientName: 'Masterblend 4-18-38',
        amount: 50.0,
        notes: 'Top up solution',
      );

      expect(result['id'], equals('log-1'));
      expect(result['nutrient_name'], equals('Masterblend 4-18-38'));
      expect(result['amount'], equals(50.0));
      verify(() => mockService.logNutrient(
            farmId: 'farm-123',
            nutrientName: 'Masterblend 4-18-38',
            amount: 50.0,
            notes: 'Top up solution',
          )).called(1);
    });

    test('getNutrientLogs returns list from service', () async {
      when(() => mockService.getNutrientLogs('farm-123')).thenAnswer((_) async => [
            {
              'id': 'log-1',
              'farm_id': 'farm-123',
              'nutrient_name': 'pH Down',
              'amount': 10.0,
            }
          ]);

      final logs = await repository.getNutrientLogs('farm-123');

      expect(logs.length, equals(1));
      expect(logs.first['nutrient_name'], equals('pH Down'));
      verify(() => mockService.getNutrientLogs('farm-123')).called(1);
    });

    test('addTask delegates to service with exact parameters', () async {
      when(() => mockService.addTask(
            farmId: 'farm-123',
            title: 'pH & EC Check',
            description: 'Test reservoir levels',
            dueDate: any(named: 'dueDate'),
            priority: 'high',
          )).thenAnswer((_) async => {
            'id': 'task-1',
            'farm_id': 'farm-123',
            'title': 'pH & EC Check',
            'status': 'pending',
            'priority': 'high',
          });

      final result = await repository.addTask(
        farmId: 'farm-123',
        title: 'pH & EC Check',
        description: 'Test reservoir levels',
        priority: 'high',
      );

      expect(result['id'], equals('task-1'));
      expect(result['priority'], equals('high'));
      verify(() => mockService.addTask(
            farmId: 'farm-123',
            title: 'pH & EC Check',
            description: 'Test reservoir levels',
            dueDate: any(named: 'dueDate'),
            priority: 'high',
          )).called(1);
    });

    test('updateTaskStatus calls service updateTaskStatus', () async {
      when(() => mockService.updateTaskStatus('task-1', 'completed'))
          .thenAnswer((_) async {});

      await repository.updateTaskStatus('task-1', 'completed');

      verify(() => mockService.updateTaskStatus('task-1', 'completed')).called(1);
    });

    test('getFarmTasks returns tasks list from service', () async {
      when(() => mockService.getFarmTasks('farm-123')).thenAnswer((_) async => [
            {
              'id': 'task-1',
              'title': 'Pump Maintenance',
              'status': 'pending',
            }
          ]);

      final tasks = await repository.getFarmTasks('farm-123');

      expect(tasks.length, equals(1));
      expect(tasks.first['title'], equals('Pump Maintenance'));
      verify(() => mockService.getFarmTasks('farm-123')).called(1);
    });
  });
}
