import 'package:flutter/material.dart';
import 'pix_screen.dart'; // Importa a nova tela do Pix

class PagamentoScreen extends StatelessWidget {
  final double valorTotal;
  final String formaPagamento;

  // O construtor exige os dados vindos do carrinho
  const PagamentoScreen({
    Key? key,
    required this.valorTotal,
    required this.formaPagamento,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Finalizar Pedido", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do que está sendo processado
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Valor a Pagar:", style: TextStyle(fontSize: 16)),
                    Text(
                      "R\$ ${valorTotal.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            Text(
              "Método Selecionado: $formaPagamento",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            SizedBox(height: 16),

            // Interface condicional baseada na escolha do cliente
            Expanded(
              child: formaPagamento == "PIX"
                  ? _buildInterfacePix()
                  : _buildInterfaceCartao(),
            ),
            
            // Botão de confirmação final que disparará a API
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (formaPagamento == "PIX") {
                    // Redireciona para a nova tela do Pix passando o valor total
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PixScreen(valorTotal: valorTotal),
                      ),
                    );
                child: Text(
                  "Confirmar e Pagar",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget visual para quando for PIX
  Widget _buildInterfacePix() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pix, size: 80, color: Colors.teal),
          SizedBox(height: 16),
          Text(
            "O QR Code e a chave Copia e Cola serão gerados assim que você clicar em confirmar.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]), // <-- Agora o style está no lugar certo, dentro do Text!
          ),
        ],
      ),
    );
  }

  // Widget visual para quando for Cartão
  Widget _buildInterfaceCartao() {
    return ListView(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: "Número do Cartão",
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Validade (MM/AA)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "CVV",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        TextFormField(
          decoration: InputDecoration(
            labelText: "Nome do Titular (como no cartão)",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
$aact_prod_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY6OmJiMWJhMTlmLTAxM2YtNDY3Mi1hMmYyLTBhYTgyMDYwODY1ZDo6JGFhY2hfYWI1YWI0N2QtZDRjMS00ODUwLThhYTUtZmRjZTE1MmVjYzc1