
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:dough_fermentation/about_page.dart';

import 'home_page.dart';

final AudioPlayer player = AudioPlayer();

void main() {
  // debugPaintSizeEnabled = true; //Show boarder for each obj
  // debugPaintBaselinesEnabled = true;
  // debugPaintPointersEnabled = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) :super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  List<Widget> pages = const [
    HomePage(),
    AboutPage(),
    // SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dough Fermentation'),
      ),
      body: pages[currentPage],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('Debug Message');
          PlaySound("StartFermentation.mp3");
        },
        child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'About'),
          // NavigationDestination(icon: Icon(Icons.transfer_within_a_station_outlined), label: 'Debug'),
          ],
        onDestinationSelected: (int index) {
          setState((){
            currentPage = index;
            debugPrint('Set State');
          });
        },
        selectedIndex: currentPage,
      ),
    );
  }
}

Future<void> PlaySound(String filename) async {
  String path = "../resources/sounds/$filename";
  await player.play(AssetSource(path));
}
