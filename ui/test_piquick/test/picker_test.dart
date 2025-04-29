import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/model/picker_events.dart';
import 'package:test_piquick/features/picker/model/repository/picker_remote_repository.dart';
import 'package:test_piquick/features/picker/view/picker_page.dart';
import 'package:test_piquick/features/picker/viewModel/picker_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test_piquick/features/picker/viewModel/picker_event_bus.dart';
import 'package:test_piquick/features/filters/viewModel/filter_event_bus.dart';
import 'package:test_piquick/features/filters/model/filter_events.dart';
import 'package:test_piquick/features/picker/viewModel/states/viewer_3d_state.dart';

// Mock osztály létrehozása a PickerViewModel-hez

class MockHttpClient extends Mock implements http.Client {}

class MockPickerRepository extends Mock implements PickerRemoteRepository {}

class MockFilterEventBus extends Mock implements FilterEventBus {}

class MockPickerEventBus extends Mock implements PickerEventBus {}

class FakePickerEvent extends Fake implements PickerEvent {}

class FakePickerViewModel extends PickerViewModel {
  final PickerState Function() buildFn;

  FakePickerViewModel({required this.buildFn});

  @override
  PickerState build() => buildFn();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(FakePickerEvent());
  });

  late MockPickerRepository mockRepo;
  late ProviderContainer container;
  late MockFilterEventBus mockFilterEventBus;
  late MockPickerEventBus mockPickerEventBus;

  setUp(() {
    mockRepo = MockPickerRepository();
    mockFilterEventBus = MockFilterEventBus();
    mockPickerEventBus = MockPickerEventBus();

    when(
      () => mockFilterEventBus.events,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        pickerRemoteRepositoryProvider.overrideWithValue(mockRepo),
        filterEventBusProvider.overrideWithValue(mockFilterEventBus),
        pickerEventBusProvider.overrideWithValue(mockPickerEventBus),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PickerViewModel Tests', () {
    test('initial state should be loading', () {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      final state = container.read(pickerViewModelProvider);

      expect(state.objects.isLoading, isTrue);
      expect(state.groupedObjects.isLoading, isTrue);
      expect(
        state.viewer3DState.value?.currentObj,
        equals('assets/Astronaut.glb'),
      );
      expect(state.viewer3DState.value?.currentTexture, isNull);
    });

    test('initHome should update state with empty data', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);

      // Manually call initHome since it's normally called via microtask
      await viewModel.initHome();

      final state = container.read(pickerViewModelProvider);
      expect(state.objects.value, isEmpty);
      expect(state.groupedObjects.value?.groups, isEmpty);
    });

    test('updateObj should update viewer3DState when successful', () {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const testObjectUrl = 'http://example.com/object.glb';

      // Mock the repository response
      when(
        () => mockRepo.hostThisObject(newObj: 'test_object'),
      ).thenReturn(Right(testObjectUrl));

      // Call the method to test
      viewModel.updateObj('test_object');

      // Verify the state was updated correctly
      final state = container.read(pickerViewModelProvider);
      expect(state.viewer3DState.value?.currentObj, equals(testObjectUrl));
      expect(state.viewer3DState.value?.currentTexture, isNull);
    });

    test('updateObj should handle error state', () {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const errorMessage = 'Failed to load object';

      // Mock the repository error response
      when(
        () => mockRepo.hostThisObject(newObj: 'invalid_object'),
      ).thenReturn(Left(AppFailure(errorMessage)));

      // Call the method to test
      viewModel.updateObj('invalid_object');

      // Verify the error state
      final state = container.read(pickerViewModelProvider);
      expect(state.viewer3DState.hasError, isTrue);
      expect(state.viewer3DState.error.toString(), contains(errorMessage));
    });

    test('updateTexture should update the current texture', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const testTexture = 'http://example.com/texture.jpg';
      when(
        () => mockRepo.hostThisObject(newObj: "test_object"),
      ).thenAnswer((invocation) => Right("test_object"));

      // First ensure we have a valid state with an object
      await viewModel.initHome();
      viewModel.updateObj('test_object');

      // Update the texture
      viewModel.updateTexture(testTexture);

      // Verify the texture was updated
      final state = container.read(pickerViewModelProvider);
      expect(state.viewer3DState.value?.currentTexture, equals(testTexture));
    });

    test('selectGroup should update the selected group', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const groupName = 'TestGroup';

      // First ensure we have a valid state
      await viewModel.initHome();

      // Select a group
      viewModel.selectGroup(groupName);

      // Verify the group was selected
      final state = container.read(pickerViewModelProvider);
      expect(state.selectedGroup, equals(groupName));
    });

    test('newGroup should create a new group when name is valid', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const groupName = 'NewTestGroup';

      // First ensure we have a valid state
      await viewModel.initHome();

      // Set up the mock for the event bus
      when(() => mockPickerEventBus.emit(any())).thenReturn(null);

      // Create a new group
      final error = viewModel.newGroup(groupname: groupName);

      // Verify the group was created
      expect(error, isNull);
      final state = container.read(pickerViewModelProvider);
      expect(state.groupedObjects.value?.groups.containsKey(groupName), isTrue);

      // Verify the event was emitted
      verify(() => mockPickerEventBus.emit(any())).called(1);
    });

    test('newGroup should return error when group name is empty', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);

      // First ensure we have a valid state
      await viewModel.initHome();

      // Try to create a group with an empty name
      final error = viewModel.newGroup(groupname: '  ');

      // Verify the error message
      expect(error, equals("Group name cannot be empty"));
    });

    test(
      'newGroup should return error when group name already exists',
      () async {
        final viewModel = container.read(pickerViewModelProvider.notifier);
        const groupName = 'ExistingGroup';

        // First ensure we have a valid state
        await viewModel.initHome();

        // Set up the mock for the event bus
        when(() => mockPickerEventBus.emit(any())).thenReturn(null);

        // Create a group first
        viewModel.newGroup(groupname: groupName);

        // Try to create a group with the same name
        final error = viewModel.newGroup(groupname: groupName);

        // Verify the error message
        expect(error, equals("A group with name '$groupName' already exists"));
      },
    );

    test('removeGroup should remove an existing group', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const groupName = 'GroupToRemove';

      // First ensure we have a valid state and create a group
      await viewModel.initHome();
      when(() => mockPickerEventBus.emit(any())).thenReturn(null);
      viewModel.newGroup(groupname: groupName);

      // Remove the group
      viewModel.removeGroup(groupname: groupName);

      // Verify the group was removed
      final state = container.read(pickerViewModelProvider);
      expect(
        state.groupedObjects.value?.groups.containsKey(groupName),
        isFalse,
      );

      // Verify the event was emitted twice (once for creation, once for removal)
      verify(() => mockPickerEventBus.emit(any())).called(2);
    });

    test('addToGroup should add an object to the selected group', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const groupName = 'MyGroup';
      const objectId = 'object1';

      // First ensure we have a valid state and create a group
      await viewModel.initHome();
      when(() => mockPickerEventBus.emit(any())).thenReturn(null);
      viewModel.newGroup(groupname: groupName);
      viewModel.selectGroup(groupName);

      // Add object to group
      viewModel.addToGroup(objectId);

      // Verify the object was added to the group
      final state = container.read(pickerViewModelProvider);
      final objects = state.groupedObjects.value?.groups[groupName];
      expect(objects, contains(objectId));

      // Verify the event was emitted twice (once for creation, once for adding object)
      verify(() => mockPickerEventBus.emit(any())).called(2);
    });

    test('removeFromGroup should remove an object from a group', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      const groupName = 'MyGroup';
      const objectId = 'object1';

      // First ensure we have a valid state and create a group with an object
      await viewModel.initHome();
      when(() => mockPickerEventBus.emit(any())).thenReturn(null);
      viewModel.newGroup(groupname: groupName);
      viewModel.selectGroup(groupName);
      viewModel.addToGroup(objectId);

      // Remove object from group
      viewModel.removeFromGroup(groupname: groupName, objectId: objectId);

      // Verify the object was removed from the group
      final state = container.read(pickerViewModelProvider);
      final objects = state.groupedObjects.value?.groups[groupName];
      expect(objects, isNot(contains(objectId)));

      // Verify the event was emitted three times
      verify(() => mockPickerEventBus.emit(any())).called(3);
    });

    test('handleFiltersAppliedEvent should update objects list', () async {
      final viewModel = container.read(pickerViewModelProvider.notifier);
      final testObjects = ['object1', 'object2', 'object3'];

      // First ensure we have a valid state
      await viewModel.initHome();

      // Create and handle the event
      final event = AppliedFiltersEvent(newObjects: testObjects);
      viewModel.handleFiltersAppliedEvent(event);

      // Verify the objects were updated
      final state = container.read(pickerViewModelProvider);
      expect(state.objects.value, equals(testObjects));
    });
  });

  group('PickerPage Tests', () {
    testWidgets('Shows loading indicator when data is loading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pickerViewModelProvider.overrideWith(
            () => FakePickerViewModel(
              buildFn:
                  () => PickerState(
                    objects: const AsyncValue.loading(),
                    groupedObjects: const AsyncValue.loading(),
                    viewer3DState: const AsyncValue.loading(),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PickerPage()),
        ),
      );

      // Updated assertion to check for two loading indicators
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });

    testWidgets('PickerPage shows data when loaded', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pickerViewModelProvider.overrideWith(
            () => FakePickerViewModel(
              buildFn:
                  () => PickerState(
                    objects: AsyncValue.data(['object1', 'object2']),
                    groupedObjects: AsyncValue.data(ObjectGroups(groups: {})),
                    viewer3DState: AsyncValue.data(
                      Viewer3DState(
                        currentObj: 'object1',
                        currentTexture: null,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PickerPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('object1'), findsNWidgets(2));
      expect(find.text('object2'), findsOneWidget);
    });

    testWidgets('PickerPage shows error widget when loading fails', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pickerViewModelProvider.overrideWith(
            () => FakePickerViewModel(
              buildFn:
                  () => PickerState(
                    objects: AsyncValue.error(
                      'Error loading objects',
                      StackTrace.current,
                    ),
                    groupedObjects: AsyncValue.error(
                      'Error loading groups',
                      StackTrace.current,
                    ),
                    viewer3DState: AsyncValue.error(
                      'Error loading viewer',
                      StackTrace.current,
                    ),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PickerPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading objects'), findsOneWidget);
      expect(find.textContaining('Error loading groups'), findsOneWidget);
      expect(find.textContaining('Error loading viewer'), findsOneWidget);
    });
  });
}
