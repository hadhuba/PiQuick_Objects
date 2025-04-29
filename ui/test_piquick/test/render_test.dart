import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/viewModel/picker_event_bus.dart';
import 'package:test_piquick/features/rendering/model/group.dart';
import 'package:test_piquick/features/rendering/model/render_events.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/model/settings_form_model.dart';
import 'package:test_piquick/features/rendering/viewModel/render_event_bus.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';
import 'package:test_piquick/features/rendering/model/repository/render_remote_repository.dart';
import 'package:test_piquick/features/rendering/viewModel/settings_form_view_model.dart';
import 'package:test_piquick/features/rendering/viewModel/states/render_state.dart';
import 'package:test_piquick/features/rendering/viewModel/states/settings_form_state.dart';

class MockWebDownloadHelper extends Mock {
  void downloadFile(Uint8List bytes, String fileName);
}

class MockHttpClient extends Mock implements http.Client {}

class MockRenderRepository extends Mock implements RenderRemoteRepository {}

class MockPickerEventBus extends Mock implements PickerEventBus {}

class MockRenderEventBus extends Mock implements RenderEventBus {}

class FakeRenderEvent extends Fake implements RenderEvent {}

class MockRenderModel extends Mock implements RenderModel {}

class FakeSettingsFormViewModel extends SettingsFormViewModel {
  final SettingsFormState Function({
    dynamic groupName,
    RenderSettings? settings,
  })
  buildFn;

  FakeSettingsFormViewModel({required this.buildFn});

  @override
  SettingsFormState build({dynamic groupName, RenderSettings? settings}) =>
      buildFn(groupName: groupName, settings: settings);
}

class FakeRenderViewModel extends RenderViewModel {
  final RenderState Function() buildFn;

  FakeRenderViewModel({required this.buildFn});

  @override
  RenderState build() => buildFn();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(FakeRenderEvent());
    registerFallbackValue(MockRenderModel());
  });

  late MockRenderRepository mockRepo;
  late ProviderContainer container;
  late MockRenderEventBus mockRenderEventBus;
  late MockPickerEventBus mockPickerEventBus;

  setUp(() {
    mockRepo = MockRenderRepository();
    mockRenderEventBus = MockRenderEventBus();
    mockPickerEventBus = MockPickerEventBus();

    when(
      () => mockRenderEventBus.events,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockPickerEventBus.events,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        renderRemoteRepositoryProvider.overrideWithValue(mockRepo),
        renderEventBusProvider.overrideWithValue(mockRenderEventBus),
        pickerEventBusProvider.overrideWithValue(mockPickerEventBus),
        settingsFormViewModelProvider.overrideWith(
          () => FakeSettingsFormViewModel(
            buildFn:
                ({groupName, settings}) => SettingsFormState(
                  groupName: groupName ?? '',
                  formModel:
                      settings != null
                          ? SettingsFormModel.fromSettings(settings)
                          : SettingsFormModel.defaults(),
                ),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RenderViewModel Tests', () {
    test('Initial state is loading', () {
      final viewModel = container.read(renderViewModelProvider.notifier);
      expect(viewModel.state.renderModel.isLoading, isTrue);
    });

    test('sendSettings updates state on success', () async {
      final mockFile = File('mock_path.zip');
      when(
        () => mockRepo.sendSettings(any()),
      ).thenAnswer((_) async => Right(mockFile));

      final viewModel = container.read(renderViewModelProvider.notifier);
      viewModel.updateRender(
        groupedObjects: ObjectGroups(
          groups: {
            'Group1': ["Object1", "Object2"],
          },
        ),
      );

      // Ensure initial state is correct
      expect(viewModel.state.renderModel.isLoading, isFalse);
      expect(viewModel.state.renderModel.hasError, isFalse);

      // Call sendSettings and wait for it to complete
      await viewModel.sendSettings();

      // Allow state updates to propagate
      await Future.delayed(Duration.zero);

      // Assert the final state
      expect(viewModel.state.downloadedFile.value, equals(mockFile));
      expect(viewModel.state.downloadStatus, contains('successful'));
    });

    test('sendSettings updates state on failure', () async {
      when(
        () => mockRepo.sendSettings(any()),
      ).thenAnswer((_) async => Left(AppFailure('Network error')));

      final viewModel = container.read(renderViewModelProvider.notifier);
      viewModel.updateRender(
        groupedObjects: ObjectGroups(
          groups: {
            'Group1': ["Object1", "Object2"],
          },
        ),
      );
      await viewModel.sendSettings();

      // Allow state updates to propagate
      await Future.delayed(Duration.zero);

      expect(viewModel.state.downloadedFile.hasError, isTrue);
      expect(viewModel.state.downloadStatus, contains('unsuccessful'));
    });
  });
}
