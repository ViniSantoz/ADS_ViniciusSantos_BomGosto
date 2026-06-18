import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cardapio_screen.dart';
import 'pix_screen.dart'; // Garanta que o import do Pix existe

class PagamentoScreen extends StatefulWidget {
  final double valorTotal;
  final String idDoPedido;

  const PagamentoScreen({
    super.key,
    required this.valorTotal,
    required this.idDoPedido,
  });

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  // Define o método inicial padrão (ajuste conforme seu código)
  String formaPagamento = "PIX";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Pagamento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Valor a pagar: R\$ ${widget.valorTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "Método Selecionado: $formaPagamento",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Botão Avançar / Já Paguei integrado com o fluxo de testes
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Já Paguei (Simular Asaas)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                if (uid == null) return;

                if (formaPagamento == "PIX") {
                  // Redireciona para a tela do PIX injetando os dados obrigatórios
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PixScreen(
                        idDoPedido: widget.idDoPedido,
                        valorTotal: widget.valorTotal,
                      ),
                    ),
                  );
                } else {
                  // Se for outra forma de pagamento (ex: cartão), roda o lote de encerramento
                  final firestore = FirebaseFirestore.instance;
                  try {
                    await firestore
                        .collection('pedidos')
                        .doc(widget.idDoPedido)
                        .update({
                          'status': 'Aprovado',
                          'pagoEm': FieldValue.serverTimestamp(),
                        });

                    final carrinhoRef = firestore
                        .collection('usuarios')
                        .doc(uid)
                        .collection('carrinho');
                    final snapshot = await carrinhoRef.get();
                    WriteBatch batch = firestore.batch();
                    for (var doc in snapshot.docs) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CardapioScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
