import 'package:flutter/material.dart';

class CardapioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Definimos 3 abas conforme solicitado: Lanches, Porções e Bebidas
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          // Parte de cima com o nome do sistema (HU01)
          title: Text(
            "BOM GOSTO", 
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          bottom: TabBar(
            tabs: [
              Tab(text: "Lanches"),
              Tab(text: "Porções"),
              Tab(text: "Bebidas"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListaItens("Lanches"),
            _buildListaItens("Porções"),
            _buildListaItens("Bebidas"),
          ],
        ),
      ),
    );
  }

  // Widget para listar os itens (Nome e Preço conforme solicitado)
  Widget _buildListaItens(String categoria) {
    // Exemplo de dados estáticos para visualização inicial
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5, // Exemplo com 5 itens por categoria
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text("$categoria ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Descrição do item para atender a HU01 do DVP."),
            trailing: Text("R\$ 25,00", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            leading: Icon(Icons.fastfood, color: Colors.redAccent),
            onTap: () {
              // Futura implementação: Adicionar ao carrinho (HU02)
            },
          ),
        );
      },
    );
  }
}