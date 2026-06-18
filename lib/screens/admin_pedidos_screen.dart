import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Certifique-se de ter o pacote 'intl' no pubspec.yaml para formatar as datas

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função auxiliar para formatar o Timestamp do Firebase em Data legível (ex: 11/06/2026)
  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return "Sem data";
    DateTime data = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(data);
  }

  // Função auxiliar para formatar a hora (ex: 21:15)
  String _formatarHora(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime data = timestamp.toDate();
    return DateFormat('HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Admin - Pedidos'),
        centerTitle: true,
        backgroundColor: Colors.amber[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ouve em tempo real todos os pedidos do sistema, ordenados do mais recente para o mais antigo
        stream: _firestore
            .collection('pedidos')
            .orderBy('pagoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum pedido realizado até o momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // ESTRUTURA DE AGRUPAMENTO: Vamos agrupar os documentos por String da Data (ex: "11/06/2026")
          Map<String, List<QueryDocumentSnapshot>> pedidosAgrupados = {};

          for (var doc in docs) {
            final dados = doc.data() as Map<String, dynamic>;
            Timestamp? timestamp = dados['pagoEm'] as Timestamp?;

            // Se o timestamp ainda não foi processado pelo servidor (null temporário), joga na data de hoje
            String dataChave = timestamp != null
                ? _formatarData(timestamp)
                : _formatarData(Timestamp.now());

            if (pedidosAgrupados[dataChave] == null) {
              pedidosAgrupados[dataChave] = [];
            }
            pedidosAgrupados[dataChave]!.add(doc);
          }

          // Pega todas as chaves de dias (ex: ["11/06/2026", "10/06/2026"])
          final listaDias = pedidosAgrupados.keys.toList();

          return ListView.builder(
            itemCount: listaDias.length,
            itemBuilder: (context, index) {
              String dia = listaDias[index];
              List<QueryDocumentSnapshot> pedidosDoDia = pedidosAgrupados[dia]!;

              return ExpansionTile(
                initiallyExpanded:
                    index == 0, // Deixa o dia mais recente já aberto por padrão
                leading: const Icon(Icons.calendar_today, color: Colors.amber),
                title: Text(
                  "Pedidos de: $dia",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                trailing: Chip(
                  label: Text(
                    "${pedidosDoDia.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.amber[800],
                ),
                children: pedidosDoDia.map((pedidoDoc) {
                  final dadosPedido = pedidoDoc.data() as Map<String, dynamic>;

                  String idCurto = pedidoDoc.id
                      .substring(0, 5)
                      .toUpperCase(); // Pega os 5 primeiros dígitos do ID para facilitar
                  double valor = (dadosPedido['valorTotal'] ?? 0.0).toDouble();
                  String status = dadosPedido['status'] ?? 'Pendente';
                  Timestamp? horaTimestamp =
                      dadosPedido['pagoEm'] as Timestamp?;
                  String hora = _formatarHora(horaTimestamp);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 1,
                    child: ListTile(
                      title: Text(
                        "Pedido #$idCurto - R\$ ${valor.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Horário: $hora | Status: $status"),
                      trailing: Icon(
                        status == 'Aprovado'
                            ? Icons.check_circle
                            : Icons.warning,
                        color: status == 'Aprovado'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      onTap: () {
                        // DICA: Aqui você pode abrir um Modal ou uma nova tela
                        // detalhando quais lanches estão dentro desse pedido!
                      },
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
