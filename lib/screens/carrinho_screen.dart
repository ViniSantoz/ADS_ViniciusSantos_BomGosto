import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarrinhoScreen extends StatelessWidget {
  const CarrinhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Carrinho'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Busca os itens do carrinho vinculados ao UID do usuário logado
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user?.uid)
                  .collection('carrinho')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Erro ao carregar carrinho'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final itens = snapshot.data!.docs;

                if (itens.isEmpty) {
                  return const Center(child: Text('Seu carrinho está vazio.'));
                }

                double total = 0;
                // Cálculo automático do valor total conforme RF02
                for (var item in itens) {
                  total += (item['preco'] * item['quantidade']);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final data =
                              itens[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['nome']),
                            subtitle: Text('Qtd: ${data['quantidade']}'),
                            trailing: Text(
                              'R\$ ${(data['preco'] * data['quantidade']).toStringAsFixed(2)}',
                            ),
                            // Permite remover itens conforme HU02 [cite: 98]
                            onLongPress: () => itens[index].reference.delete(),
                          );
                        },
                      ),
                    ),
                    _buildResumoTotal(total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoTotal(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAlignment,
            children: [
              const Text(
                'Total do Pedido:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              // Próxima etapa: Finalização de Pedidos (19/05)
            },
            child: const Text('REVISAR PEDIDO'),
          ),
        ],
      ),
    );
  }
}
