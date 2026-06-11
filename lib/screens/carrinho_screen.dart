import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pagamento_screen.dart'; // Certifique-se de importar a nova tela

class CarrinhoScreen extends StatefulWidget {
  @override
  _CarrinhoScreenState createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  // Variável para armazenar a opção selecionada pelo cliente
  String _formaPagamento = 'PIX'; 

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Meu Carrinho", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
      ),
      body: uid == null
          ? Center(child: Text("Por favor, faça login para ver seu carrinho."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .doc(uid)
                  .collection('carrinho')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final itens = snapshot.data!.docs;
                if (itens.isEmpty) {
                  return Center(child: Text("Seu carrinho está vazio!"));
                }

                double total = 0;
                for (var doc in itens) {
                  final dados = doc.data() as Map<String, dynamic>;
                  total += (dados['preco'] ?? 0) * (dados['quantidade'] ?? 1);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final dados = itens[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(dados['nome'] ?? 'Produto'),
                            subtitle: Text("${dados['quantidade']}x - R\$ ${dados['preco']}"),
                            trailing: Text("R\$ ${(dados['preco'] * dados['quantidade']).toStringAsFixed(2)}"),
                          );
                        },
                      ),
                    ),
                    
                    // --- NOVA SEÇÃO: SELEÇÃO DE FORMA DE PAGAMENTO ---
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selecione a Forma de Pagamento:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("PIX"),
                                  value: "PIX",
                                  groupValue: _formaPagamento,
                                  activeColor: Colors.red[800],
                                  onChanged: (value) {
                                    setState(() {
                                      _formaPagamento = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("Cartão"),
                                  value: "CARTAO",
                                  groupValue: _formaPagamento,
                                  activeColor: Colors.red[800],
                                  onChanged: (value) {
                                    setState(() {
                                      _formaPagamento = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- SEÇÃO DO TOTAL E BOTÃO DE PAGAMENTO ---
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total do Pedido:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("R\$ ${total.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                            ],
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[800],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                // Navega para a tela de pagamento levando o total e a opção escolhida
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PagamentoScreen(
                                      valorTotal: total,
                                      formaPagamento: _formaPagamento,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Ir para o Pagamento",
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}