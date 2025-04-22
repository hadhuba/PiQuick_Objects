import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/picker/viewModel/picker_view_model.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/repository/render_remote_repository.dart';
import 'package:test_piquick/features/rendering/viewModel/states/render_state.dart';
import 'package:flutter/foundation.dart';

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

    ref.listen<PickerState>(pickerViewModelProvider, (_, next) {
      next.groupedObjects.whenData((objects) {
        updateRender(groupedObjects: objects);
      });
    });

    final initialState = RenderState(renderModel: AsyncValue.loading());

    // Future.microtask(() => initRender());

    return initialState;
  }

  // void initRender() {
  //   print("initrender_called");

  //   // Fetch the initial list of objects from the remote repository
  //   state = state.copyWith(
  //     renderModel: AsyncValue.data(
  //       RenderModel.empty(),
  //     ), // Initialize the state with loading
  //     groupedObjects: AsyncValue.data(ObjectGroups(groups: {})),
  //   );

  //   print("initrender_finished");
  // }

  void updateRender({required ObjectGroups groupedObjects}) {
    // Fetch the initial list of objects from the remote repository

    final newRenderModel = RenderModel.fromObjectGroupsAndSettings(
      objectGroups: groupedObjects,
      renderSettings: RenderSettings(), // Default settings
    );

    state = state.copyWith(renderModel: AsyncValue.data(newRenderModel));
    // state = state.copyWith(
    //   renderModel: AsyncValue.data(
    //     RenderModel.fromObjectGroupsAndSettings(
    //       objectGroups: groupedObjects,
    //       renderSettings: RenderSettings(),
    //     ),
    //   ),
    // );
  }

  void setNumImages(int value) {
    if (state.selectedGroup == null) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(numImages: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(azimuthAug: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(elevationAug: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(resolution: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(modeMulti: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(modeStatic: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(modeFrontView: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(modeFourView: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(engine: value),
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
        (renderModel) => renderModel.setGroupSettings(
          state.selectedGroup!,
          renderModel
              .get(state.selectedGroup!)!
              .settings
              .copyWith(onlyNorthernHemisphere: value),
        ),
      ),
    );
  }

  // void setFinish(bool value) {}

  void selectGroup(String? value) {
    state = state.copyWith(selectedGroup: value);
  }

  void updateGroupSettings(String groupName, RenderSettings newSettings) {
    if (state.renderModel.isLoading) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSettings(groupName, newSettings),
      ),
    );
  }

  // void setDone(selectedGroup) {
  //   if (state.renderModel.isLoading) {
  //     return;
  //   }
  //   state = state.copyWith(
  //     renderModel: state.renderModel.whenData(
  //       (renderModel) => renderModel.setGroupSetting(
  //         selectedGroup,
  //         renderModel.renderGroups[selectedGroup]!.copyWith(
  //           finish: renderModel.renderGroups[selectedGroup]!.setDone(),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void sendSettings() async {
    state = state.copyWith(
      downloadStatus: "Sending rendering request...",
      downloadedFile: const AsyncValue.loading(),
    );

    state.renderModel.whenData((renderModel) async {
      try {
        state = state.copyWith(downloadStatus: "Processing render request...");

        // Check if we're running on the web
        if (kIsWeb) {
          final response = await _renderRemoteRepository.sendSettings(
            renderModel,
          );

          // Even though we don't get a file back on web, we want to update the state
          state = state.copyWith(
            downloadedFile: const AsyncValue.data(null), // No file on web
            downloadStatus: "Rendering complete! Download initiated.",
          );

          // The actual download is handled by the browser through web_download_helper.dart
        } else {
          // Mobile/Desktop platforms
          final file = await _renderRemoteRepository.sendSettings(renderModel);

          if (file != null) {
            state = state.copyWith(
              downloadedFile: AsyncValue.data(file),
              downloadStatus: "Render complete! Ready for download.",
            );
          } else {
            state = state.copyWith(
              downloadedFile: const AsyncValue.error(
                "Failed to download file",
                StackTrace.empty,
              ),
              downloadStatus: "Rendering failed. Please try again.",
            );
          }
        }
      } catch (e, stack) {
        state = state.copyWith(
          downloadedFile: AsyncValue.error(e, stack),
          downloadStatus: "Error: ${e.toString()}",
        );
      }
    });
  }

  void resetDownload() {
    state = state.copyWith(
      downloadedFile: const AsyncValue.data(null),
      downloadStatus: null,
    );
  }
}
