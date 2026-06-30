import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pix_screen.dart';
import '../services/asaas_service.dart';
import 'carrinho_screen.dart';

class PagamentoScreen extends StatefulWidget {
  final String idDoPedido;
  final double valorTotal;

  const PagamentoScreen({
    super.key,
    required this.idDoPedido,
    required this.valorTotal,
  });

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  String formaPagamento = "PIX"; // Opção padrão
  final AsaasService _asaasService = AsaasService();
  bool _carregando = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forma de Pagamento'),
        centerTitle: true,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      key: ValueKey(widget.idDoPedido),
                      child: Column(
                        children: [
                          const Text(
                            "Resumo do Fechamento",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Total a Pagar: R\$ ${widget.valorTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selecione como deseja pagar:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text("PIX (Aprovação Instantânea)"),
                    value: "PIX",
                    groupValue: formaPagamento,
                    onChanged: (value) {
                      setState(() {
                        formaPagamento = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Cartão de Crédito"),
                    value: "Cartão",
                    groupValue: formaPagamento,
                    onChanged: (value) {
                      setState(() {
                        formaPagamento = value!;
                      });
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (uid == null) return;
                      
                      setState(() {
                        _carregando = true;
                      });

                      try {
                        // 1. Cria ou atualiza o pedido usando o idDoPedido que veio por parâmetro
                        await FirebaseFirestore.instance
                            .collection('pedidos')
                            .doc(widget.idDoPedido)
                            .set({
                          'id': widget.idDoPedido,
                          'usuarioId': uid, 
                          'data': Timestamp.now(),
                          'status': 'aguardando_pagamento',
                          'valorTotal': widget.valorTotal, 
                        }, SetOptions(merge: true));

                        if (formaPagamento == "PIX") {
                          
                          // 2. Limpa o carrinho no Firebase ANTES de mudar de tela para não quebrar o contexto
                          final snapshot = await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(uid)
                              .collection('carrinho')
                              .get();

                          for (DocumentSnapshot doc in snapshot.docs) {
                            await doc.reference.delete();
                          }

                          if (!mounted) return;
                          
                          // 3. Agora sim, navega para a tela do Pix de forma segura
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PixScreen(
                                idDoPedido: widget.idDoPedido,
                                valorTotal: widget.valorTotal, 
                              ),
                            ),
                          );

                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fluxo de cartão integrado ao gateway Asaas!')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao processar checkout: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _carregando = false;
                          });
                        }
                      }
                    },
                    child: Text(
                      formaPagamento == "PIX" ? "AVANÇAR PARA O PIX" : "CONFIRMAR COMPRA",
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}