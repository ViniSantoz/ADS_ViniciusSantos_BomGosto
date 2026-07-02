import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pix_screen.dart';

class PagamentoScreen extends StatefulWidget {
  final double valorTotal;
  final String? idDoPedido; // CORREÇÃO: Parâmetro adicionado para aceitar o ID vindo do carrinho

  const PagamentoScreen({super.key, required this.valorTotal, this.idDoPedido});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  bool _carregando = false;

  void _processarPagamentoPix() async {
    setState(() => _carregando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      String finalPedidoId = widget.idDoPedido ?? '';

      // Se o carrinho não gerou o ID, criamos um novo documento aqui
      if (finalPedidoId.isEmpty) {
        final pedidoRef = await FirebaseFirestore.instance.collection('pedidos').add({
          'userId': user.uid,
          'valorTotal': widget.valorTotal,
          'status': 'Pendente',
          'dataCriacao': FieldValue.serverTimestamp(),
        });
        finalPedidoId = pedidoRef.id;
      }

      if (!mounted) return;

      // Avança para a tela do Pix passando os parâmetros corretos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PixScreen(
            valorTotal: widget.valorTotal,
            pedidoId: finalPedidoId,
          ),
        ),
      );

      // Limpa o carrinho do usuário após abrir a tela de checkout com sucesso
      final carrinhoSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('carrinho')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in carrinhoSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar checkout: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forma de Pagamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Resumo do Pedido', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Total: R\$ ${widget.valorTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _carregando ? null : _processarPagamentoPix,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _carregando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmar e Ir para o Pix', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}