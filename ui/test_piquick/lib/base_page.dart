import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/picker/view/picker_page.dart';

class BasePage extends ConsumerStatefulWidget {
  const BasePage({super.key});

  @override
  ConsumerState<BasePage> createState() => _BasePageState();
}

class _BasePageState extends ConsumerState<BasePage> {
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
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'PickerPage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Render',
          ),
        ],
      ),
    );
  }
}
