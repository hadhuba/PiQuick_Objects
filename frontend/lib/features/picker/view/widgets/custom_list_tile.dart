import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

/// A custom list tile widget designed for displaying object files with actions.
/// Provides functionality to view a 3D object and add it to a selected group.
class CustomListTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onAddToGroup;
  final VoidCallback onTap;

  const CustomListTile({
    super.key,
    required this.fileName,
    required this.onAddToGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fileName),
      trailing: IconButton(
        icon: const Icon(Icons.group_add, color: Pallete.gradient1),
        onPressed: onAddToGroup,
      ),
      onTap: onTap,
    );
  }
}
