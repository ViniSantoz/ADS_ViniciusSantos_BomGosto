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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Função para alterar a quantidade ou remover o item diretamente do Firestore
  Future<void> _alterarQuantidade(
    String produtoId,
    int mudanca,
    int qtdAtual,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('carrinho')
        .doc(produtoId);

    if (qtdAtual + mudanca <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantidade': qtdAtual + mudanca});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Carrinho'), centerTitle: true),
      body: uid == null
          ? const Center(
              child: Text('Por favor, faça login para ver seu carrinho.'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .doc(uid)
                  .collection('carrinho')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o carrinho.'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final itens = snapshot.data?.docs ?? [];

                if (itens.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
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

                double totalDoCarrinho = 0.0;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final doc = itens[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};

                          final String id = doc.id;
                          final String nome = data['nome'] ?? 'Sem nome';
                          final double preco = data['preco'] != null
                              ? (data['preco'] as num).toDouble()
                              : 0.0;
                          final int quantidade = data['quantidade'] != null
                              ? (data['quantidade'] as num).toInt()
                              : 1;
                          final String imagemUrl = data['imagemUrl'] ?? '';

                          return Card(
                            key: ValueKey(
                              id,
                            ), // 💡 ESSENCIAL: Diz ao Flutter exatamente qual item é qual, evitando bugs de MouseTracker!
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                // Modificação do leading para estabilidade máxima de tamanho:
                                leading: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imagemUrl.isEmpty
                                        ? Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.fastfood,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : Image.network(
                                            imagemUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                          ),
                                  ),
                                ),
                                title: Text(
                                  nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Valor un: R\$ ${preco.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'Subtotal: R\$ ${(preco * quantidade).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _alterarQuantidade(
                                        id,
                                        -1,
                                        quantidade,
                                      ),
                                    ),
                                    Text(
                                      '$quantidade',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _alterarQuantidade(id, 1, quantidade),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Rodapé com o valor TOTAL e botão de Avançar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
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
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: 18,
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
                            ElevatedButton(
                              onPressed: () {
                                // Gera um ID temporário/prévio para o documento do pedido
                                final String novoIdPedido = _firestore
                                    .collection('pedidos')
                                    .doc()
                                    .id;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PagamentoScreen(
                                      idDoPedido: novoIdPedido,
                                      valorTotal: totalDoCarrinho,
                                      // Padrão inicial de escolha
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'AVANÇAR PARA O PAGAMENTO',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
