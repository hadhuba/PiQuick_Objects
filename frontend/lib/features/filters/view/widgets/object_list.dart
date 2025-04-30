
// Extracted reusable widget for the object list
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ObjectList extends StatelessWidget {
  final AsyncValue<List<String>> objects;

  const ObjectList({
    required this.objects,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return objects.when(
      data: (objectsList) => objectsList.isEmpty
          ? const Center(
              child: Text(
                'No objects match the current filters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: objectsList.length,
              itemBuilder: (context, index) {
                final object = objectsList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      object,
                      style: const TextStyle(fontSize: 14),
                    ),
                    dense: true,
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          '$error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
