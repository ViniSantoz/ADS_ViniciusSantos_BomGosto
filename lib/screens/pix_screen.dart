import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cardapio_screen.dart';

class PixScreen extends StatefulWidget {
  final String idDoPedido;
  final double valorTotal; // Adicione esta linha para receber o valor

  // Atualize o construtor para exigir os dois parâmetros
  const PixScreen({
    super.key,
    required this.idDoPedido,
    required this.valorTotal,
  });

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  bool _carregando = true;
  String? _erro;

  // Variáveis que vão receber os dados vindos da API do Asaas
  String? _payloadPixCopiaECola;
  String? _qrCodeBase64;

  @override
  void initState() {
    super.initState();
    _gerarPixNoAsaas();
  }

  // --- FUNÇÃO QUE CONECTA COM O CHECKOUT DO ASAAS ---
  Future<void> _gerarPixNoAsaas() async {
    try {
      setState(() {
        _carregando = true;
        _erro = null;
      });

      // =========================================================================
      // SIMULAÇÃO DA CHAMADA AO SEU BACKEND/CLOUD FUNCTION (Padrão de Produção)
      // Quando sua API estiver pronta, você substituirá esse Future.delayed por:
      // final response = await http.post(Uri.parse('SUA_URL/gerar-pix'), body: {...});
      // =========================================================================
      await Future.delayed(Duration(seconds: 2));

      // Dados de exemplo idênticos ao formato que o Asaas retorna no endpoint:
      // /v3/payments/{id}/pixQrCode
      String fakeQrCodeBase64 =
          "iVBORw0KGgoAAAANSUhEUgAAAMgAAADIEAMAAAHYsnNaAAAAG1BMVEUAAAD///89PT07OzsBAQEqKioVFRUiIiIXFxd66U7CAAAACXBIWXMAAA7EAAAOxAGVKw4bAAABMElEQVR4nO3NMQ7CMBAEQDGe8v9/Y8p0WhA6g6gK96YbitXm6vO+78fPZ98XmAtZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFmIufwB7msZ7m9mXm0AAAAASUVORK5CYII=";
      String fakeCopiaECola =
          "00020101021226870014br.gov.bcb.pix2565asaas.com/qr/v2/cobv/v/fake-id-bom-gosto-payment-2026";

      setState(() {
        _qrCodeBase64 = fakeQrCodeBase64;
        _payloadPixCopiaECola = fakeCopiaECola;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = "Não foi possível gerar o PIX. Tente novamente.";
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pagamento via PIX", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[800]!),
            ),
            SizedBox(height: 16),
            Text(
              "Gerando QR Code no Asaas...",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _gerarPixNoAsaas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                ),
                child: Text(
                  "Tentar Novamente",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    Future<void> finalizarPedidoNoBanco() async {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      final uid = auth.currentUser?.uid;

      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: Usuário não autenticado.")),
        );
        return;
      }

      try {
        // 1. Buscar os itens que estão atualmente no carrinho do usuário
        final carrinhoSnapshot = await firestore
            .collection('usuarios')
            .doc(uid)
            .collection('carrinho')
            .get();

        if (carrinhoSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Seu carrinho já está vazio!")),
          );
          return;
        }

        // Mapeia os documentos do carrinho para uma lista de Maps estruturada
        List<Map<String, dynamic>> itensPedido = [];
        for (var doc in carrinhoSnapshot.docs) {
          final dados = doc.data();
          itensPedido.add({
            'idProduto': doc.id,
            'nome': dados['nome'],
            'preco': dados['preco'],
            'quantidade': dados['quantidade'],
          });
        }

        // 2. Criar o documento do pedido na coleção GLOBAL 'pedidos'
        // O dono do restaurante vai ler esta coleção para ver os pedidos novos e antigos
        DocumentReference
        novoPedidoRef = await firestore.collection('pedidos').add({
          'idUsuario': uid,
          'itens': itensPedido,
          'valorTotal': widget.valorTotal,
          'formaPagamento': 'PIX',
          'status':
              'Pendente', // Pode ser: Pendente, Em Preparo, Pronto, Entregue
          'dataCriacao':
              FieldValue.serverTimestamp(), // Guarda a data/hora exata do servidor
        });

        // 3. Limpar o carrinho do usuário (Deleta os itens para liberar o app)
        WriteBatch batch = firestore.batch();
        for (var doc in carrinhoSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // 4. Sucesso! Avisa o usuário e volta para a tela inicial do cardápio
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pedido enviado para a cozinha com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        // Remove as telas de checkout do histórico e volta para a tela principal (Cardápio)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        print("ERRO AO SALVAR PEDIDO: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao processar o pedido. Tente novamente."),
          ),
        );
      }
    }

    // --- INTERFACE DO PIX GERADO COM SUCESSO ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Bom Gosto Gastronomia",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Valor a pagar: R\$ ${widget.valorTotal.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          Divider(height: 40, thickness: 1),

          Text(
            "Abra o app do seu banco e escaneie o QR Code abaixo:",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[800]),
          ),
          SizedBox(height: 24),

          // Renderiza a imagem pura a partir da String Base64 devolvida pelo Asaas
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Image.memory(
              base64Decode(_qrCodeBase64!),
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24),

          Text(
            "Ou pague copiando o código Pix abaixo:",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),

          // Campo visual mostrando o Copia e Cola
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _payloadPixCopiaECola!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 12),

          // Botão Copia e Cola Funcional usando Clipboard do Flutter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _payloadPixCopiaECola!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Código PIX copiado para a área de transferência!",
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                );
              },
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text(
                "Copiar Código PIX",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 40),

          Text(
            "Após realizar o pagamento, nosso sistema identificará o recebimento de forma automática.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
          // ... Código anterior do SingleChildScrollView (abaixo do último Text)
          SizedBox(height: 30),

          // --- NOVO BOTÃO PARA SALVAR O PEDIDO NO BANCO ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Já Paguei (Simular Asaas)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              final firestore = FirebaseFirestore.instance;

              try {
                // 1. SALVA OU ATUALIZA O PEDIDO (Usando .set com merge em vez de .update)
                await firestore
                    .collection('pedidos')
                    .doc(widget.idDoPedido)
                    .set(
                      {
                        'status': 'Aprovado',
                        'pagoEm': FieldValue.serverTimestamp(),
                        'usuarioId': uid,
                        'valorTotal': widget.valorTotal,
                      },
                      SetOptions(merge: true),
                    ); // <-- Isso impede o erro de documento inexistente!

                // 2. LIMPA O CARRINHO DO USUÁRIO
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

                // Feedback visual para você saber que deu certo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sucesso! Pedido criado/aprovado e carrinho limpo.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // 3. FECHA O CICLO (Volta para o Cardápio limpando a árvore de telas)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardapioScreen(),
                  ),
                  (route) => false,
                );
              } catch (e) {
                print(
                  "ERRO NO TESTE: $e",
                ); // Isso vai cuspir o erro real no terminal do VS Code
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao fechar pedido: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ], // Fim do Column
      ), // Fim do SingleChildScrollView
    );
  }
}
