import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante para verificar o usuário
import 'adicionar_produto_screen.dart';

class CardapioScreen extends StatelessWidget {
  const CardapioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pegamos o usuário que está logado no momento
    final user = FirebaseAuth.instance.currentUser;
    // Defina aqui o e-mail que você usa para administrar o Bom Gosto
    final bool isAdmin = user?.email == 'admin@bomgosto.com';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('BOM GOSTO'),
          actions: [
            // O botão só é renderizado se isAdmin for verdadeiro (RNF01)
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Adicionar Produto',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdicionarProdutoScreen(),
                    ),
                  );
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lanches'),
              Tab(text: 'Porções'),
              Tab(text: 'Bebidas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListaProdutos('Lanches'),
            _buildListaProdutos('Porções'),
            _buildListaProdutos('Bebidas'),
          ],
        ),
      ),
    );
  }

  Widget _buildListaProdutos(String categoria) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('categoria', isEqualTo: categoria)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Erro ao carregar itens.'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return Center(child: Text('Nenhum item em $categoria.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['nome'] ?? 'Sem nome'),
              subtitle: Text(data['descricao'] ?? ''),
              trailing: Text(
                'R\$ ${data['preco'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
