import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:test_piquick/core/utils.dart';
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
    // Watch specific parts of the state to ensure we react to all relevant changes
    final viewModel = ref.watch(renderViewModelProvider.notifier);
    // Watch all these state selectors separately to ensure rebuilds happen properly
    final modelAsync = ref.watch(
      renderViewModelProvider.select((state) => state.renderModel),
    );
    final selectedGroup = ref.watch(
      renderViewModelProvider.select((state) => state.selectedGroup),
    );
    final downloadStatus = ref.watch(
      renderViewModelProvider.select((state) => state.downloadStatus),
    );
    final downloadedFile = ref.watch(
      renderViewModelProvider.select((state) => state.downloadedFile),
    );

    return modelAsync.when(
      data: (_) {
        final groupNames = ref.watch(
          renderViewModelProvider.select((state) => state.groupNames),
        );

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
                  Expanded(
                    child: RenderSettingsForm(
                      viewModel: viewModel.settingsFormViewModel,
                    ),
                  ),
                ElevatedButton(
                  onPressed:
                      viewModel.isDownloading()
                          ? null // Disable button while downloading
                          : () => viewModel.sendSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply & Send to Server'),
                ),

                // File Download Status & Controls
                if (downloadStatus != null || downloadedFile.isLoading)
                  _buildDownloadStatusCard(viewModel),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Loader()),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading render settings: ${error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(renderViewModelProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDownloadStatusCard(RenderViewModel viewModel) {
    // Explicitly watch downloadedFile state to ensure rebuilds
    final downloadedFile = ref.watch(
      renderViewModelProvider.select((state) => state.downloadedFile),
    );
    final downloadStatus = viewModel.getDownloadStatus();
    final isDownloading = viewModel.isDownloading();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendering Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Download Status Text
            if (downloadStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(downloadStatus),
              ),

            // Loading Indicator
            if (isDownloading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),

            // Download Complete - Show Open File Button or Web Message
            downloadedFile.when(
              data: (file) {
                if (kIsWeb) {
                  // On web, we show a success message - download is handled by the browser
                  if (downloadStatus?.contains("Download initiated") == true) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Your download has started. If it doesn\'t appear, check your browser\'s download folder.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => viewModel.resetDownload(),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    );
                  }

                  // Handle non-201 status code errors
                  if (downloadStatus?.contains("Error") == true) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'An error occurred during the download. Please try again.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => viewModel.resetDownload(),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                } else {
                  // On mobile/desktop, we provide a button to open the downloaded file
                  if (file != null) {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.file_open),
                            label: const Text('Open Rendered Files'),
                            onPressed: () => _openFile(file),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => viewModel.resetDownload(),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
              error:
                  (error, stackTrace) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error: ${viewModel.getDownloadError()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: () => viewModel.resetDownload(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
              loading: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        // Show a message if the file couldn't be opened
        if (mounted) {
          showSnackBar(context, 'Could not open the file. ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening file: $e');
      }
    }
  }
}
