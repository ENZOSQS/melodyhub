import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MelodyHubApp());
}

class MelodyHubApp extends StatelessWidget {
  const MelodyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melody Hub',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Melody Hub'), centerTitle: true),

      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            print('Botão clicado');

            try {
              await FirebaseFirestore.instance.collection('usuarios').add({
                'nome': 'Enzo',
                'xp': 100,
                'nivel': 1,
              });

              print('Dados enviados com sucesso!');
            } catch (e) {
              print('ERRO AO ENVIAR: $e');
            }
          },

          child: const Text('Enviar Dados'),
        ),
      ),
    );
  }
}
