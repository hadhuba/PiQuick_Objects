import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/repository/render_remote_repository.dart';
import 'package:test_piquick/features/rendering/viewModel/states/render_state.dart';

import '../../picker/viewModel/picker_view_model.dart';

part 'render_view_model.g.dart';

@riverpod
class RenderViewModel extends _$RenderViewModel {
  late RenderRemoteRepository _renderRemoteRepository;

  @override
  RenderState build() {
    _renderRemoteRepository =
        RenderRemoteRepository(); // we cant continously track the changes in authremoterepo
    _renderRemoteRepository = ref.watch(
      renderRemoteRepositoryProvider,
    ); // if it changes the latest comes, build runs again

    final initialState = RenderState(
      renderModel: AsyncValue.loading(), // Initialize the state with loading
      groupedObjects: AsyncValue.loading(),
    );

    Future.microtask(() => initRender());

    return initialState;
  }

  Future<void> initRender() async {
    // Fetch the initial list of objects from the remote repository

    final groups =
        ref.read<PickerState>(pickerViewModelProvider).groupedObjects;

    // Handle the response using a switch expression
    groups.when(
      data: (data) {
        state = state.copyWith(
          renderModel: AsyncValue.data(RenderModel.fromObjects(data)),
          groupedObjects: AsyncValue.data(data),
        );
      },
      error: (error, stackTrace) {
        // Handle the error state
        state = state.copyWith(
          renderModel: AsyncValue.error(error, stackTrace),
        );
      },
      loading: () {
        // Handle the loading state
        state = state.copyWith(
          renderModel: AsyncValue.loading(),
          groupedObjects: AsyncValue.loading(),
        );
      },
    );
  }

  void setNumImages(int value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            numImages: value,
          ),
        ),
      ),
    );
  }

  void setAzimuthAug(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            azimuthAug: value,
          ),
        ),
      ),
    );
  }

  void setElevationAug(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            elevationAug: value,
          ),
        ),
      ),
    );
  }

  void setResolution(int value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            resolution: value,
          ),
        ),
      ),
    );
  }

  void setModeMulti(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            modeMulti: value,
          ),
        ),
      ),
    );
  }

  void setModeStatic(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            modeStatic: value,
          ),
        ),
      ),
    );
  }

  void setModeFrontView(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            modeFrontView: value,
          ),
        ),
      ),
    );
  }

  void setModeFourView(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            modeFourView: value,
          ),
        ),
      ),
    );
  }

  void setEngine(String value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            engine: value,
          ),
        ),
      ),
    );
  }

  void setOnlyNorthernHemisphere(bool value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSetting(
          state.selectedGroup!,
          renderModel.renderGroups[state.selectedGroup!]!.copyWith(
            onlyNorthernHemisphere: value,
          ),
        ),
      ),
    );
  }
}
