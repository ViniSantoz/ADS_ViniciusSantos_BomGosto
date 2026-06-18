import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pagamento_screen.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função auxiliar para atualizar a quantidade do item no Firestore
  Future<void> _alterarQuantidade(String docId, int novaQuantidade) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('carrinho')
        .doc(docId);

    if (novaQuantidade <= 0) {
      // Se a quantidade chegar a 0, removemos o item do carrinho
      await docRef.delete();
    } else {
      await docRef.update({'quantidade': novaQuantidade});
    }
  }

  // Função auxiliar para remover o item diretamente
  Future<void> _removerItem(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('carrinho')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    // Se o usuário não estiver logado, impede o carregamento
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuário não autenticado. Faça login para ver seu carrinho.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Carrinho'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        // Ouve em tempo real as atualizações da subcoleção de carrinho do usuário logado
        stream: _firestore
            .collection('usuarios')
            .doc(uid)
            .collection('carrinho')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final itens = snapshot.data!.docs;
          double totalDoCarrinho = 0.0;

          // Calcula o valor total multiplicando preço e quantidade de cada documento
          for (var doc in itens) {
            final dados = doc.data() as Map<String, dynamic>;
            double preco = (dados['preco'] ?? 0.0).toDouble();
            int quantidade = (dados['quantidade'] ?? 1).toInt();
            totalDoCarrinho += (preco * quantidade);
          }

          return Column(
            children: [
              // Lista de Itens do Carrinho
              Expanded(
                child: ListView.builder(
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final doc = itens[index];
                    final dados = doc.data() as Map<String, dynamic>;

                    String nome = dados['nome'] ?? 'Item sem nome';
                    double preco = (dados['preco'] ?? 0.0).toDouble();
                    int quantidade = (dados['quantidade'] ?? 1).toInt();
                    String imagemUrl = dados['imagemUrl'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: imagemUrl.isNotEmpty
                            ? Image.network(
                                imagemUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.fastfood, size: 40),
                              )
                            : const Icon(Icons.fastfood, size: 40),
                        title: Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "R\$ ${preco.toStringAsFixed(2)} x $quantidade",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão de diminuir quantidade
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.orange,
                              ),
                              onPressed: () =>
                                  _alterarQuantidade(doc.id, quantidade - 1),
                            ),
                            Text(
                              '$quantidade',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Botão de aumentar quantidade
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _alterarQuantidade(doc.id, quantidade + 1),
                            ),
                            // Botão de remover item completo
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removerItem(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Rodapé com o Resumo Financeiro e Ação de Avançar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'R\$ ${totalDoCarrinho.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            // Cria antecipadamente uma referência limpa com ID aleatório no Firestore
                            String novoIdPedido = _firestore
                                .collection('pedidos')
                                .doc()
                                .id;

                            // Avança para a tela de pagamento passando as variáveis necessárias
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PagamentoScreen(
                                  valorTotal: totalDoCarrinho,
                                  idDoPedido: novoIdPedido,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'AVANÇAR PARA O PAGAMENTO',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
