import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/home/view/picker_page.dart';
import '../../filters/view/filters_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PickerPage(), // PickerPage widget for 3D object selection.
      // const RenderPage(), // Render page.
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Piquick Objects')),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: pages[selectedIndex], // Display the selected page.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'PickerPage'),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Render',
          ),
        ],
      ),
    );
  }

  // Build the content for the HomePage.
  Widget _buildHomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: PickerPage(controller: controller), // PickerWidget.
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Navigate to FiltersPage when the button is pressed.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FiltersPage()),
            );
          },
          child: const Text('Go to Filters'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
