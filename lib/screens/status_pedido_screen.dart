import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusPedidoScreen extends StatelessWidget {
  final String idDoPedido;

  StatusPedidoScreen({super.key, required this.idDoPedido});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // E-mail administrativo definido no seu DVP
  final String _emailAdmin = "admin@bomgosto.com";

  // Função para o Administrador atualizar o status do pedido no Firestore
  Future<void> _atualizarStatus(String novoStatus) async {
    await _firestore.collection('pedidos').doc(idDoPedido).update({
      'status': novoStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _auth.currentUser?.email == _emailAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('STATUS DO PEDIDO'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('pedidos').doc(idDoPedido).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar dados do pedido.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Pedido não encontrado.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String statusAtual = data['status'] ?? 'Pendente';
          final double valorTotal = (data['valorTotal'] ?? 0.0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido ID: #$idDoPedido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: R\$ ${valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(height: 32),

                // --- LINHA DO TEMPO DO STATUS (Visualização do Cliente e Admin) ---
                const Text(
                  'Acompanhamento:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildEtapaStatus(
                  'Pendente',
                  statusAtual,
                  Icons.access_time,
                  Colors.orange,
                ),
                _buildEtapaStatus(
                  'Em Preparo',
                  statusAtual,
                  Icons.restaurant,
                  Colors.blue,
                ),
                _buildEtapaStatus(
                  'Saiu para Entrega',
                  statusAtual,
                  Icons.delivery_dining,
                  Colors.purple,
                ),
                _buildEtapaStatus(
                  'Entregue',
                  statusAtual,
                  Icons.check_circle,
                  Colors.green,
                ),

                const Spacer(),
                // --- INTERFACE EXCLUSIVA DO ADMINISTRADOR (Painel de Ações) ---
                if (isAdmin) ...[
                  const Divider(),
                  const Text(
                    'Painel do Administrador:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // AJUSTE AQUI: Se estiver "Pendente" OU "Aprovado", libera para ir para a cozinha ("Em Preparo")
                      if (statusAtual == 'Pendente' || statusAtual == 'Aprovado')
                        ElevatedButton.icon(
                          onPressed: () => _atualizarStatus('Em Preparo'),
                          icon: const Icon(Icons.restaurant),
                          label: const Text('Aceitar e Preparar'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                      if (statusAtual == 'Em Preparo')
                        ElevatedButton.icon(
                          onPressed: () => _atualizarStatus('Saiu para Entrega'),
                          icon: const Icon(Icons.delivery_dining),
                          label: const Text('Despachar Pedido'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                        ),
                      if (statusAtual == 'Saiu para Entrega')
                        ElevatedButton.icon(
                          onPressed: () => _atualizarStatus('Entregue'),
                          icon: const Icon(Icons.check),
                          label: const Text('Finalizar Entrega'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Componente visual para renderizar cada etapa do status
  Widget _buildEtapaStatus(
    String etapa,
    String statusAtual,
    IconData icone,
    Color cor,
  ) {
    bool concluida = _verificarEtapaConcluida(etapa, statusAtual);
    bool ativa = statusAtual == etapa;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icone,
            color: concluida ? cor : Colors.grey[400],
            size: ativa ? 32 : 24,
          ),
          const SizedBox(width: 16),
          Text(
            etapa,
            style: TextStyle(
              fontSize: ativa ? 18 : 16,
              fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
              color: ativa
                  ? cor
                  : (concluida ? Colors.black : Colors.grey[500]),
            ),
          ),
          if (ativa) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ],
      ),
    );
  }
  // Lógica atualizada para incluir o status "Aprovado" no início do fluxo
  bool _verificarEtapaConcluida(String etapa, String statusAtual) {
  // Se o status do banco for "Aprovado", tratamos ele visualmente no mesmo nível de "Pendente"
  String statusMapeado = statusAtual == 'Aprovado' ? 'Pendente' : statusAtual;
  
  List<String> ordem = ['Pendente', 'Em Preparo', 'Saiu para Entrega', 'Entregue'];
  return ordem.indexOf(statusMapeado) >= ordem.indexOf(etapa);
  }
}
