import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini YouTube',
      theme: ThemeData.dark(),
      home: const YouTubePantalla(),
    );
  }
}

class YouTubePantalla extends StatelessWidget {
  const YouTubePantalla({super.key});

  final List<Map<String, String>> videos = const [
    {
      'title': 'Flutter Tutorial Básico',
      'thumbnail': 'https://img.youtube.com/vi/QrU4Tj0FPQE/0.jpg',
    },
    {
      'title': 'Cómo usar StatefulWidget',
      'thumbnail': 'https://img.youtube.com/vi/1gDhl4leEzA/0.jpg',
    },
    {
      'title': 'Animaciones en Flutter',
      'thumbnail': 'https://img.youtube.com/vi/2y1n2bKfFzY/0.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini YouTube')),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                Image.network(video['thumbnail']!),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    video['title']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aquí podrías abrir el video con url_launcher
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Ver video'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

