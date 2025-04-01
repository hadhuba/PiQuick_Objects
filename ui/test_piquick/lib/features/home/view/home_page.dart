import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/home/view/picker_widget.dart';
import '../viewModel/viewer_3d_view_model.dart';
import 'viewer_3d_widget.dart';
import '../../filters/view/filters_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedIndex = 0;

  final pages = const [
    FiltersPage(),
    // LibraryPage(),
  ];
  final Flutter3DController controller = Flutter3DController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Stack(
        children: [
          pages[selectedIndex],
          Positioned(
            bottom: 0,
            child: PickerWidget(
              controller: controller,
            ), // Pass the controller to PickerWidget
          ),

          BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.filter_list),
                label: 'Filters',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
