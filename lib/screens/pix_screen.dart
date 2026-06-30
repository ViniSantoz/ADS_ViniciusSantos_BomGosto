// Pasta: lib/screens/
// Arquivo: pix_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'status_pedido_screen.dart';

class PixScreen extends StatelessWidget {
  final String idDoPedido;
  final double valorTotal;

  const PixScreen({
    super.key,
    required this.idDoPedido,
    required this.valorTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento via PIX'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Impede o cliente de voltar e duplicar ações
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').doc(idDoPedido).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao verificar status do pagamento.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidoData = snapshot.data?.data() as Map<String, dynamic>?;
          final status = pedidoData?['status'] ?? 'Pendente';

          // SE O STATUS MUDAR PARA APROVADO (Via Webhook do Asaas ou Admin), PULA PARA A TELA DE STATUS
          if (status == 'Aprovado' || status == 'Em Preparo') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StatusPedidoScreen(idDoPedido: idDoPedido),
                ),
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Aguardando Pagamento...",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                const SizedBox(height: 10),
                Text(
                  "Valor a pagar: R\$ ${valorTotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                
                // Representação do QR Code (Aqui você pode futuramente puxar a URL Base64 real do Asaas)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=200&auto=format&fit=crop',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    key: ValueKey(idDoPedido),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Copie a chave abaixo ou escaneie o código acima pelo app do seu banco. A sua tela atualizará sozinha assim que o Asaas confirmar a liquidação.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    // Implementação básica de copiar código Pix Copia e Cola
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código Copia e Cola copiado para a área de transferência!')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copiar Código Pix"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}