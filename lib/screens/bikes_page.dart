import 'package:flutter/material.dart';
import 'home_page.dart';

class BikesPage extends StatefulWidget {
  const BikesPage({super.key});

  @override
  State<BikesPage> createState() => _BikesPageState();
}

class _BikesPageState extends State<BikesPage> {
  final List<Map<String, String>> _bikes = [
    {'model': 'Yamaha MT-03', 'cc': '321 cc', 'consumption': '22 km/L'},
    {'model': 'Honda CB 500X', 'cc': '471 cc', 'consumption': '28 km/L'},
  ];

  void _openBikeForm({int? index}) {
    final isEditing = index != null;
    final modelController = TextEditingController(text: isEditing ? _bikes[index]['model'] : '');
    final ccController = TextEditingController(text: isEditing ? _bikes[index]['cc'] : '');
    final consController = TextEditingController(text: isEditing ? _bikes[index]['consumption'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Motocicleta' : 'Cadastrar Motocicleta',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Modelo')),
            TextField(controller: ccController, decoration: const InputDecoration(labelText: 'Cilindrada (cc)')),
            TextField(controller: consController, decoration: const InputDecoration(labelText: 'Consumo (km/L)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: HomePage.laranja, foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    final newBike = {
                      'model': modelController.text,
                      'cc': ccController.text,
                      'consumption': consController.text,
                    };
                    if (isEditing) {
                      _bikes[index] = newBike;
                    } else {
                      _bikes.add(newBike);
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Garagem de Motos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: HomePage.laranja,
        onPressed: () => _openBikeForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bikes.length,
        itemBuilder: (context, index) {
          final bike = _bikes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: HomePage.preto,
                child: Icon(Icons.two_wheeler, color: HomePage.laranja),
              ),
              title: Text(bike['model']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${bike['cc']} • Consumo: ${bike['consumption']}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _openBikeForm(index: index),
              ),
            ),
          );
        },
      ),
    );
  }
}