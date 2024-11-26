import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FilterPage(),
    );
  }
}

class FilterPage extends StatefulWidget {
  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  Map<String, List<double?>> filterAspects = {
    "armature": [null, null],
    "edge": [null, null],
    "mesh": [null, null],
    "poly": [null, null],
    "vertex": [null, null],
  };

  void updateFilter(String aspect, int index, double? value){}

  List<dynamic> filteredFiles = [];
  String searchTerm = '';

Future<void> sendFiltersToServer() async {
    final url = Uri.parse("http://127.0.0.1:5000/api/filter"); // A szerver végpontja
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"filter_aspects": filterAspects}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Server response: $responseData");
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending data to server: $e");
    }
  }



  // Future<void> filterFiles(String term) async {
  //   final response = await http.post(
  //     Uri.parse('http://127.0.0.1:5000/api/filter'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({"search_term": term}),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     setState(() {
  //       filteredFiles = data['filtered_files'];
  //     });
  //   } else {
  //     print('Error filtering files: ${response.statusCode}');
  //   }
  // }

  Future<void> fetchFileDetails(String id) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/api/glb/$id'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Selected File: ${data['file']}");
    } else {
      print('Error fetching file: ${response.statusCode}');
    }
  }

  // Felhasználói felület a szűrési paraméterekhez
  Widget buildFilterInput(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Min"),
                onChanged: (value) {
                  updateFilter(key, 0, double.tryParse(value));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max"),
                onChanged: (value) {
                  updateFilter(key, 1, double.tryParse(value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Filter Example")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildFilterInput("Armature", "armature"),
            buildFilterInput("Edge", "edge"),
            buildFilterInput("Mesh", "mesh"),
            buildFilterInput("Poly", "poly"),
            buildFilterInput("Vertex", "vertex"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendFiltersToServer,
              child: const Text("Apply Filters"),
            ),
          ],
        ),
      ),
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Filter GLB Files')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 searchTerm = value;
//               },
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => filterFiles(searchTerm),
//             child: Text('Filter'),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredFiles.length,
//               itemBuilder: (context, index) {
//                 final file = filteredFiles[index];
//                 return ListTile(
//                   title: Text(file['name']),
//                   onTap: () => fetchFileDetails(file['id']),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// void main() {
//   runApp(MyApp());
// }
