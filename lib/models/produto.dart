// Modelo de dados de um produto do cardápio.
// Usamos uma classe para deixar o código mais organizado e tipado.
class Produto {
  final String nome;     // Nome do produto (ex: "X-Burguer")
  final double preco;    // Preço em reais
  final String imagem;   // URL ou caminho do asset da imagem
  final String categoria;
  final String descricao; // "lanches", "bebidas" ou "porcoes"

  Produto({
    required this.nome,
    required this.preco,
    required this.imagem,
    required this.categoria,
    required this.descricao,
  });
}
