import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String fileName;
  final VoidCallback onAddToGroup;
  final VoidCallback onTap;

  const CustomListTile({
    Key? key,
    required this.fileName,
    required this.onAddToGroup,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(fileName),
      trailing: IconButton(
        icon: const Icon(Icons.group_add, color: Colors.blue),
        onPressed: onAddToGroup, // Trigger the add-to-group logic
      ),
      onTap: onTap, // Trigger the on-tap logic
    );
  }
}