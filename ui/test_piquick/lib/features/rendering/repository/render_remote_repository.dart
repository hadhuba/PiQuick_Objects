import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';

part 'render_remote_repository.g.dart';

@riverpod
RenderRemoteRepository renderRemoteRepository(RenderRemoteRepositoryRef ref) {
  return RenderRemoteRepository();
}

class RenderRemoteRepository {
  void sendSettings(RenderModel renderModel) {}
}
