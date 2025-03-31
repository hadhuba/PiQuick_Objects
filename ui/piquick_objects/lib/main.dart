import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'Viewer3D.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'objectNotifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
        child: MaterialApp(
        title: 'PiQuick Objects',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'PiQuick Objects'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var history = <String>[];

  GlobalKey? historyListKey;
  List<dynamic> filteredFiles = [
    
  ];

  var listedObjects = <String>[
    'assets/animal__food__chicken_model_cs2.glb',
    'assets/Astronaut.glb',
    'assets/keypad_from_half_life_2_prop.glb',
    'assets/legendary_chicken_warrior_animated_35_motions.glb',
    'assets/persian_lamassu_gates_of_all_nations_persepolis.glb',
    'assets/snail.glb',
    'assets/toy_freddy.glb',
  ];  

  var filters = <String, Map<String, dynamic>>{
    'armature': {'min': null, 'max': null},
    'weight': {'min': null, 'max': null},
    'height': {'min': null, 'max': null},
  };

  void setFilter(String property, {dynamic min, dynamic max}) {
    if (filters.containsKey(property)) {
      filters[property]!['min'] = min;
      filters[property]!['max'] = max;
    } else {
      throw Exception('The filter "$property" does not exist.');
    }
  }

  // A Map, amely a csoportokat tárolja
  var groups = <String, List<String>>{
    'Group 1': ['Item A', 'Item B', 'Item C'],
    'Group 2': ['Item D', 'Item E'],
    'Group 3': ['Item F', 'Item G', 'Item H', 'Item I'],
  };

  // Új csoport létrehozása
  void newGroup(String name) {
    if (!groups.containsKey(name)) {
      groups[name] = [];
      notifyListeners();
    }
  }
  // Csoport törlése
  void remGroup(String name) {
    if (groups.containsKey(name)) {
      groups.remove(name);
      notifyListeners();
    }
  }

  void addToGroup(String groupName, String obj) {
    if (groups.containsKey(groupName)){
      if (!groups[groupName]!.contains(obj)){
        groups[groupName]!.add(obj);
      } else {
        throw Exception('The object: "$obj" is already in group: "$groupName".');
      }
    } else {
      throw Exception('The group "$groupName" does not exist.');
    }
    notifyListeners();
  }

  void remFromGroup(String groupName, String obj) {
    if (groups.containsKey(groupName)){
      if (groups[groupName]!.contains(obj)){
        groups[groupName]!.remove(obj);
      } else {
        throw Exception('The object: "$obj" is not in group: "$groupName".');
      }
    } else {
      throw Exception('The group "$groupName" does not exist.');
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {  
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) { 

    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = ObjectPickerPage(); //oldalsáv a group-page
        break;
      case 1:
        page = RenderPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: page,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Balra navigáló gomb
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: selectedIndex > 0
                    ? () {
                        setState(() {
                          selectedIndex--;
                        });
                      }
                    : null, // Ha 0 az index, letiltjuk
              ),
              // Jobbra navigáló gomb
              IconButton(
                icon: Icon(Icons.arrow_forward),//NEM MŰKÖDIK  
                onPressed: selectedIndex < 1 // Módosítsd, ha több oldalad lesz
                    ? () {
                        setState(() {
                          selectedIndex++;
                        });
                      }
                    : null, // Ha utolsó oldal, letiltjuk
              ),
            ],
          ),
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Objects",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work),
                label: "Render",
              ),
            ],
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
          ),
        ],
      ),
    );
 
    
  }
}

class ObjectPickerPage extends StatefulWidget {
  @override
  State<ObjectPickerPage> createState() => _ObjectPickerPageState();
}

class _ObjectPickerPageState extends State<ObjectPickerPage> {
  
  //fields for this particular page
  
  
  String? chosenAnimation;
  String? chosenTexture;
  
  @override
  void initState() {
    super.initState();
    
  }
  
  void saveObjToHistory(String newObj) {
      context.read<MyAppState>().history.insert(0, newObj);
      debugPrint('button clicked, Object updated to: $newObj');
    }  


  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return ChangeNotifierProvider(
      create: (_) => ObjectNotifier('assets/legendary_chicken_warrior_animated_35_motions.glb','',''),
      child: Scaffold(
      // body: LayoutBuilder(
      //   builder:(context, constraints) {
      //     if (constraints.maxWidth < 500){
      //       return Column(
      //         children: [
      //           Expanded(child: Scaffold( 
      //             body: Viewer3D(
      //             controller: controller,
      //             showPickerDialog: showPickerDialog,
      //             objectNotifier: _objectNotifier,)
      //             )),
      //           Flexible(child: Scaffold(
      //               appBar: AppBar(title: const Text("Listed Objects")),
      //               body: ListView.builder(
      //                 itemCount: appState.listedObjects.length,
      //                 itemBuilder: (context, index) {
      //                   final file = appState.listedObjects[index];
      //                   return ListTile(
      //                     title: Text(file.split('.')[0].split('/')[1]),
      //                     onTap: () => updateObj(file)
      //                   );
      //                 } ,
      //               ),
      //             ),),
      //           Flexible( child:Scaffold(
      //               appBar: AppBar(title: const Text("Group List")),
      //               body: ListView(
      //                 children: appState.groups.entries.map((entry) {
      //                   String groupName = entry.key; // Csoport neve
      //                   List<String> items = entry.value; // Csoport elemei

      //                   return ExpansionTile(
      //                     title: Text(groupName),
      //                     children: items.map((item) {
      //                       return ListTile(
      //                         title: Text(item),
      //                         onTap: () {
      //                           // Kezeljük az egyedi elemek kiválasztását
      //                           //button to remove from group
      //                           //button to select to view in 3D
      //                         },
      //                       );
      //                     }).toList(),
      //                   );
      //                 }).toList(),
      //               ),
      //             ),)
                
      //         ],
      //       );
      //     } else {
      //       return 
            body: Row(
              children: [                
                  Expanded(child: Scaffold( 
                    body: Viewer3D()
                    ) ),
                  Flexible(child: Column(children: [
                    Flexible(child: Scaffold(
                    appBar: AppBar(title: const Text("Group List")),
                    body: ListView(
                      children: appState.groups.entries.map((entry) {
                        String groupName = entry.key;
                        List<String> items = entry.value;
                        return ExpansionTile(
                          title: Text(groupName),
                          children: items.map((item) {
                            return ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        saveObjToHistory(item);
                                        context.read<ObjectNotifier>().updateObj(item);},
                                      child: Text(item),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      debugPrint('Remove button clicked for: $item');
                                      appState.remFromGroup(groupName, item);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: TextField(
                  //     decoration: InputDecoration(
                  //       labelText: 'Search',
                  //       border: OutlineInputBorder(),
                  //     ),
                  //     onChanged: (value) {
                  //       searchTerm = value;
                  //     },
                  //   ),
                  // ),
                  // ElevatedButton(
                  //   onPressed: () => filterFiles(searchTerm),
                  //   child: Text('Filter'),
                  // ),
                  Flexible(child: Scaffold(
                    appBar: AppBar(title: const Text("Listed Objects")),
                    body: ListView.builder(
                      itemCount: appState.listedObjects.length,
                      itemBuilder: (context, index) {
                        final file = appState.listedObjects[index];
                        return ListTile(
                          title: Text(file.split('.')[0].split('/')[1]),
                          onTap: () {
                            saveObjToHistory(file);
                            context.read<ObjectNotifier>().updateObj(file);}
                        );
                      } ,
                    ),
                  ),)
                  ],)
                  )                  
                ]
            )
          // }
        // }
      )
      ); 
    // );
  }

}

class RenderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Render Page"),
      ),
      body: Center(
        child: Text(
          "This is the Render Page",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

