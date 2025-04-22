import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';
import 'package:test_piquick/features/rendering/view/render_settings_form.dart';

class RenderPage extends ConsumerStatefulWidget {
  const RenderPage({super.key});

  @override
  ConsumerState<RenderPage> createState() => _RenderPageState();
}

class _RenderPageState extends ConsumerState<RenderPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(renderViewModelProvider.notifier);
    final modelAsync = ref.watch(renderViewModelProvider).renderModel;

    return modelAsync.when(
      data: (_) {
        final groupNames = viewModel.getGroupNames();
        final selectedGroup = viewModel.getSelectedGroup();

        return Scaffold(
          appBar: AppBar(title: const Text('Render Settings')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedGroup,
                  hint: const Text('Select a Group'),
                  items:
                      groupNames.map((groupName) {
                        return DropdownMenuItem<String>(
                          value: groupName,
                          child: Text(groupName),
                        );
                      }).toList(),
                  onChanged: (value) {
                    viewModel.selectGroup(value);
                  },
                ),
                const SizedBox(height: 20),
                if (selectedGroup != null)
                  Expanded(child: RenderSettingsForm(groupName: selectedGroup)),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Loader()),
      error:
          (error, stack) =>
              const Scaffold(body: Center(child: Text('Hiba történt'))),
    );
  }
}
