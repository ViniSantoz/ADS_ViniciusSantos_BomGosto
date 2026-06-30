import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'status_pedido_screen.dart';

class ListaPedidosAdminScreen extends StatelessWidget {
  const ListaPedidosAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Pedidos Ativos'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Traz todos os pedidos que não estão finalizados/entregues
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('status', isNotEqualTo: 'Entregue')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar pedidos.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum pedido pendente no momento! 🎉'),
            );
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedidoDoc = pedidos[index];
              final data = pedidoDoc.data() as Map<String, dynamic>;
              final String idPedido = pedidoDoc.id;
              final String status = data['status'] ?? 'Pendente';
              final double valorTotal = (data['valorTotal'] ?? 0.0).toDouble();

              // Define uma cor baseada no status para o admin bater o olho rápido
              Color corStatus = Colors.orange;
              if (status == 'Aprovado') corStatus = Colors.green; // Verde para pagamento aprovado!
              if (status == 'Em Preparo') corStatus = Colors.blue;
              if (status == 'Saiu para Entrega') corStatus = Colors.purple;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: corStatus.withAlpha(40),
                    child: Icon(Icons.assignment, color: corStatus),
                  ),
                  title: Text(
                    'Pedido #$idPedido',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: $status\nTotal: R\$ ${valorTotal.toStringAsFixed(2)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  isThreeLine: true,
                  onTap: () {
                    // Ao clicar, o admin vai direto para a tela de controle do status
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StatusPedidoScreen(idDoPedido: idPedido),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
