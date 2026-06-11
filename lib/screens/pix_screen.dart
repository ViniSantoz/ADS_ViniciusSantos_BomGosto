import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixScreen extends StatefulWidget {
  final double valorTotal;

  const PixScreen({Key? key, required this.valorTotal}) : super(key: key);

  @override
  _PixScreenState createState() => _PixScreenState();
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
      String fakeQrCodeBase64 = "iVBORw0KGgoAAAANSUhEUgAAAMgAAADIEAMAAAHYsnNaAAAAG1BMVEUAAAD///89PT07OzsBAQEqKioVFRUiIiIXFxd66U7CAAAACXBIWXMAAA7EAAAOxAGVKw4bAAABMElEQVR4nO3NMQ7CMBAEQDGe8v9/Y8p0WhA6g6gK96YbitXm6vO+78fPZ98XmAtZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFkIWQhZCFmIufwB7msZ7m9mXm0AAAAASUVORK5CYII=";
      String fakeCopiaECola = "00020101021226870014br.gov.bcb.pix2565asaas.com/qr/v2/cobv/v/fake-id-bom-gosto-payment-2026";

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
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red[800]!)),
            SizedBox(height: 16),
            Text("Gerando QR Code no Asaas...", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
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
              Text(_erro!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _gerarPixNoAsaas,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                child: Text("Tentar Novamente", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    // --- INTERFACE DO PIX GERADO COM SUCESSO ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Bom Gosto Gastronomia",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red[800]),
          ),
          SizedBox(height: 8),
          Text(
            "Valor a pagar: R\$ ${widget.valorTotal.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[700]),
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
              fit: .BoxFit.contain,
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
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.grey[700]),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _payloadPixCopiaECola!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Código PIX copiado para a área de transferência!"),
                      ],
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                );
              },
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text("Copiar Código PIX", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: 40),
          
          Text(
            "Após realizar o pagamento, nosso sistema identificará o recebimento de forma automática.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], italic: true),
          ),
        ],
      ),
    );
  }
}