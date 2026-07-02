import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bom_gosto/services/asaas_service.dart';

class PixScreen extends StatefulWidget {
  final double valorTotal;
  final String pedidoId;

  const PixScreen({super.key, required this.valorTotal, required this.pedidoId});

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  late Future<PixQrCodeData>? _pixFuture;

  @override
  void initState() {
    super.initState();
    // Dispara a requisição para buscar o QR Code real/dinâmico do Asaas
    _pixFuture = AsaasService.gerarPixCobranca(
    widget.valorTotal, 
    widget.pedidoId,  
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via Pix')),
      // O StreamBuilder monitora alterações do pedido em tempo real no Firestore
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .doc(widget.pedidoId)
            .snapshots(),
        builder: (context, snapshot) {
          // Se o status mudar no banco (via Webhook ou alteração manual), muda de tela sozinho
          if (snapshot.hasData && snapshot.data!.exists) {
            final dados = snapshot.data!.data() as Map<String, dynamic>?;
            if (dados != null && dados['status'] == 'Aprovado') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/status_pedido', // Altere para a sua rota de Status ou Principal
                  (route) => route.isFirst,
                );
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Valor: R\$ ${widget.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escaneie o QR Code abaixo ou utilize o Copia e Cola',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // FutureBuilder que renderiza os dados do QR Code dinâmico do Asaas
                FutureBuilder<PixQrCodeData>(
                  future: _pixFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text('Erro: ${snapshot.error ?? "Erro ao carregar dados"}'));
                    }

                    // Agora o snapshot retorna diretamente o nosso objeto tipado!
                    final pixDados = snapshot.data!;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Renderiza a imagem usando a lógica inteligente contra travamento de CORS
                          pixDados.fallback
                              ? Image.network(pixDados.encodedImage, width: 260, height: 260)
                              : Image.memory(base64Decode(pixDados.encodedImage), width: 260, height: 260),
                          
                          const SizedBox(height: 16),
                          const Text('Código Pix Copia e Cola:'),
                          
                          // Campo com o texto para o usuário copiar
                          SelectableText(pixDados.payload), 
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Aguardando detecção do pagamento...', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}