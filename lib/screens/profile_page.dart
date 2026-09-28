import 'package:flutter/material.dart';
import 'home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: HomePage.preto,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('João Malcorra', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('joao.malcorra@email.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HomePage.laranja, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
                      SizedBox(width: 8),
                      Text(
                        'Moto Ride Premium',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Assine e tenha acesso ao download de mapas e corridas para visualização offline.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: HomePage.laranja,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assinatura Premium contratada com sucesso!')),
                      );
                    },
                    child: const Text('ASSINAR POR R\$ 14,90/mês', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
              title: const Text('Conta Google Vinculada'),
              subtitle: const Text('joao.malcorra@gmail.com'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}