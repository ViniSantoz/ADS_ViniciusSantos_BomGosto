import 'dart:convert';
import 'package:http/http.dart' as http;
 
class PixQrCodeData {
  final String paymentId;
  final String encodedImage; // base64 da imagem do QR Code
  final String payload; // código "copia e cola"
  final String? expirationDate;
 
  PixQrCodeData({
    required this.paymentId,
    required this.encodedImage,
    required this.payload,
    this.expirationDate,
  });
}
 
class AsaasService {
  // URL da sua Cloud Function (região southamerica-east1, ajuste
  // pro nome real do seu projeto Firebase)
  static const String _functionsUrl =
      'https://southamerica-east1-SEU-PROJETO.cloudfunctions.net';
 
  /// Chama a Cloud Function que cria a cobrança PIX no Asaas e já
  /// devolve o QR Code pronto. Nenhum token/segredo fica no app.
  static Future<PixQrCodeData> gerarPixCobranca({
    required double valor,
    required String pedidoId,
    required String customerId,
  }) async {
    final response = await http.post(
      Uri.parse('$_functionsUrl/gerarPixCobranca'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'valor': valor,
        'pedidoId': pedidoId,
        'customerId': customerId,
      }),
    );
 
    if (response.statusCode != 200) {
      // Deixa o erro real subir para a tela, em vez de mascarar
      // com um fallback simulado. Assim dá pra ver na hora se é
      // token errado, cliente inválido, etc.
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao gerar cobrança PIX');
    }
 
    final data = jsonDecode(response.body);
    return PixQrCodeData(
      paymentId: data['paymentId'] as String,
      encodedImage: data['encodedImage'] as String,
      payload: data['payload'] as String,
      expirationDate: data['expirationDate'] as String?,
    );
  }
 
  /// Consulta o status do pagamento (populado pelo webhook do Asaas
  /// via Firestore, na Cloud Function statusPagamento).
  static Future<String> consultarStatus(String paymentId) async {
    final response = await http.get(
      Uri.parse('$_functionsUrl/statusPagamento?id=$paymentId'),
    );
 
    if (response.statusCode != 200) {
      throw Exception('Erro ao consultar status: ${response.body}');
    }
 
    final data = jsonDecode(response.body);
    return data['status'] as String;
  }
}
