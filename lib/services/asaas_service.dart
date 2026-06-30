import 'package:http/http.dart' as http;
import 'dart:convert';

class AsaasService {
  // ATENÇÃO: Troque para 'https://api.asaas.com/v3' quando for para produção
  final String _baseUrl = 'https://sandbox.asaas.com/api/v3';
  
  // Alerte-se: Esta chave ficará exposta dentro do código do aplicativo
  final String _apiKey = r''; 

  Future<Map<String, dynamic>?> gerarEBuscarPix(String clienteId, double valor) async {
    final headers = {
      'access_token': _apiKey,
      'Content-Type': 'application/json',
    };

    try {
      // PASSO 1: Criar a cobrança no Asaas para ela aparecer no painel
      final responseCobranca = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: headers,
        body: jsonEncode({
          'customer': clienteId,
          'billingType': 'PIX',
          'value': valor,
          'dueDate': DateTime.now().toIso8601String().split('T')[0], // Vence hoje
        }),
      );

      if (responseCobranca.statusCode != 200 && responseCobranca.statusCode != 201) {
        print('Erro ao criar cobrança: ${responseCobranca.body}');
        return null;
      }

      // Se chegou aqui, a cobrança já existe no painel do Asaas!
      final dadosCobranca = jsonDecode(responseCobranca.body);
      final String cobrancaId = dadosCobranca['id'];

      // PASSO 2: Buscar o QR Code e o Copia e Cola usando o ID gerado
      final responseQrCode = await http.get(
        Uri.parse('$_baseUrl/payments/$cobrancaId/pixQrCode'),
        headers: headers,
        );

      if (responseQrCode.statusCode == 200) {
        final dadosPix = jsonDecode(responseQrCode.body);
        
        // Retorna os dados para a sua tela do Flutter
        return {
          'id': cobrancaId,
          'copiaECola': dadosPix['payload'],
          'imagemBase64': dadosPix['encodedImage'],
        };
      } else {
        print('Erro ao buscar QR Code: ${responseQrCode.body}');
        return null;
      }

    } catch (e) {
      print('Erro na comunicação com o Asaas: $e');
      return null;
    }
  }
}