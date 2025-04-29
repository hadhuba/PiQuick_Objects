import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';
import 'package:test_piquick/features/rendering/model/repository/render_remote_repository.dart';

class MockRenderRemoteRepository extends Mock
    implements RenderRemoteRepository {}

void main() {
  late MockRenderRemoteRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockRenderRemoteRepository();
    container = ProviderContainer(
      overrides: [
        renderRemoteRepositoryProvider.overrideWithValue(mockRepository),
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
        () => mockRepository.sendSettings(any()),
      ).thenAnswer((_) async => Right(mockFile));

      final viewModel = container.read(renderViewModelProvider.notifier);
      viewModel.sendSettings();

      expect(viewModel.state.downloadedFile.value, equals(mockFile));
      expect(viewModel.state.downloadStatus, contains('successful'));
    });

    test('sendSettings updates state on failure', () async {
      when(
        () => mockRepository.sendSettings(any()),
      ).thenAnswer((_) async => Left(AppFailure('Network error')));

      final viewModel = container.read(renderViewModelProvider.notifier);
      viewModel.sendSettings();

      expect(viewModel.state.downloadedFile.hasError, isTrue);
      expect(viewModel.state.downloadStatus, contains('unsuccessful'));
    });
  });
}
