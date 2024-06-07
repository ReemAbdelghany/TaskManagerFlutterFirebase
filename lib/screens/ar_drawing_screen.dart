import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector64;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Import ARCore Flutter Plugin
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import other screens
import 'login_screen.dart';
import 'profile_screen.dart';

class DrawingStroke {
  List<vector64.Vector3> positions;
  Color color;
  List<String> nodeNames;

  DrawingStroke(this.positions, this.color, this.nodeNames);

  Map<String, dynamic> toJson() => {
    'positions': positions.map((pos) => {'x': pos.x, 'y': pos.y, 'z': pos.z}).toList(),
    'color': {'r': color.red, 'g': color.green, 'b': color.blue, 'a': color.alpha},
    'nodeNames': nodeNames,
  };

  static DrawingStroke fromJson(Map<String, dynamic> json) {
    final positionsJson = json['positions'] as List;
    final colorJson = json['color'];
    final nodeNames = List<String>.from(json['nodeNames']);
    final positions = positionsJson.map((posJson) => vector64.Vector3(posJson['x'], posJson['y'], posJson['z'])).toList();
    return DrawingStroke(
      positions,
      Color.fromARGB(colorJson['a'], colorJson['r'], colorJson['g'], colorJson['b']),
      nodeNames,
    );
  }
}

class ArDrawingScreen extends StatefulWidget {
  const ArDrawingScreen({Key? key}) : super(key: key);

  @override
  _ArDrawingScreenState createState() => _ArDrawingScreenState();
}

class _ArDrawingScreenState extends State<ArDrawingScreen> {
  late ArCoreController coreController;
  Color selectedColor = Colors.amberAccent;
  List<DrawingStroke> strokes = [];
  bool isDrawing = false;

  @override
  void initState() {
    super.initState();
    loadPositions();
  }

  @override
  void dispose() {
    coreController.dispose();
    super.dispose();
  }

  void onArCoreViewCreated(ArCoreController controller) {
    coreController = controller;
    coreController.onPlaneTap = handleOnPlaneTap;
    drawSavedPositions();
  }

  void handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    final hitPose = hit.pose;
    final translation = hitPose.translation;

    // Start drawing if not already drawing
    if (!isDrawing) {
      setState(() {
        isDrawing = true;
      });
    }

    // Add position and color to strokes list for continuous drawing
    final nodeNames = <String>[];
    final positions = [translation];
    strokes.add(DrawingStroke(positions, selectedColor, nodeNames));
    drawStroke(coreController, translation, selectedColor, nodeNames);
  }

  void drawStroke(ArCoreController controller, vector64.Vector3 position, Color color, List<String> nodeNames) {
    final materials = ArCoreMaterial(
      color: color,
      metallic: 2,
    );

    final sphere = ArCoreSphere(
      radius: 0.02, // Small sphere to simulate brush stroke
      materials: [materials],
    );

    final nodeName = UniqueKey().toString();
    final node = ArCoreNode(
      shape: sphere,
      position: position,
      name: nodeName,
    );

    controller.addArCoreNode(node);
    nodeNames.add(nodeName);
  }

  void onColorSelected(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  void endDrawing() {
    setState(() {
      isDrawing = false;
    });
    savePositions();
  }

  void undoLastStroke() {
    if (strokes.isNotEmpty) {
      final lastStroke = strokes.removeLast();
      for (var nodeName in lastStroke.nodeNames) {
        coreController.removeNode(nodeName: nodeName);
      }
      savePositions();
    }
  }

  Future<void> savePositions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedStrokes = strokes
        .map((stroke) => jsonEncode(stroke.toJson()))
        .toList();
    await prefs.setStringList('strokes', encodedStrokes);
  }

  Future<void> loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encodedStrokes = prefs.getStringList('strokes');
    if (encodedStrokes != null) {
      strokes = encodedStrokes
          .map((encodedStroke) => DrawingStroke.fromJson(jsonDecode(encodedStroke)))
          .toList();
      setState(() {});
    }
  }

  void drawSavedPositions() {
    if (coreController != null) {
      for (var stroke in strokes) {
        for (var position in stroke.positions) {
          drawStroke(coreController, position, stroke.color, stroke.nodeNames);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Drawing'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const ProfileScreen();
              }));
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () {
              showDialog(context: context, builder: (ctx) {
                return AlertDialog(
                  title: const Text('Confirmation !!!'),
                  content: const Text('Are you sure to Log Out ?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                          return const LoginScreen();
                        }));
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                );
              });
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (isDrawing && strokes.isNotEmpty) {
            final lastStroke = strokes.last;

            // Calculate new position relative to the last position
            final lastPosition = lastStroke.positions.last;
            final newPosition = vector64.Vector3(
              lastPosition.x + details.delta.dx * 0.001,
              lastPosition.y - details.delta.dy * 0.001,
              lastPosition.z,
            );

            lastStroke.positions.add(newPosition);
            drawStroke(coreController, newPosition, selectedColor, lastStroke.nodeNames);
          }
        },
        onPanEnd: (_) {
          endDrawing();
        },
        child: Stack(
          children: [
            ArCoreView(
              onArCoreViewCreated: onArCoreViewCreated,
              enableTapRecognizer: true,
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: () => onColorSelected(Colors.red),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () => onColorSelected(Colors.green),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () => onColorSelected(Colors.blue),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.yellow,
                    onPressed: () => onColorSelected(Colors.yellow),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.purple,
                    onPressed: () => onColorSelected(Colors.purple),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: undoLastStroke,
                    child: Icon(Icons.undo, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
