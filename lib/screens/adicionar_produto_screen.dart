import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarProdutoScreen extends StatefulWidget {
  const AdicionarProdutoScreen({super.key});

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores dos inputs do formulário
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _imagemController = TextEditingController();

  // Categoria padrão selecionada conforme o DVP (Lanches, Porções, Bebidas)
  String _categoriaSelecionada = 'Lanches';
  bool _isLoading = false;

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cria o documento na coleção global 'produtos' enviando as informações
      await _firestore.collection('produtos').add({
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'preco': double.parse(_precoController.text.trim()),
        'categoria': _categoriaSelecionada,
        'imagemUrl': _imagemController.text.trim().isEmpty
            ? 'https://placehold.co/600x400/png?text=Sem+Foto' // Imagem padrão caso fique vazio
            : _imagemController.text.trim(),
        'disponivel': true, // Padrão ativo conforme regra de negócio do DVP
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto adicionado com sucesso ao cardápio!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retorna para a tela do cardápio
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _imagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Produto'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(
                16.0,
              ), // Correção do EdgeInsets.all aplicada
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Input: Nome do Produto (Obrigatório)
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Produto *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'O nome é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Input: Descrição (Opcional)
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input: Preço (Obrigatório)
                      TextFormField(
                        controller: _precoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Preço (RS) *',
                          border: OutlineInputBorder(),
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O preço é obrigatório';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Insira um valor numérico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Novo: Link / URL da Imagem (Opcional no DVP)
                      TextFormField(
                        controller: _imagemController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL da Imagem do Produto',
                          border: OutlineInputBorder(),
                          hintText: 'https://imgur.com/sua-imagem.png',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown: Seleção de Categoria
                      DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Lanches', 'Porções', 'Bebidas']
                            .map(
                              (categoria) => DropdownMenuItem(
                                value: categoria,
                                child: Text(categoria),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _categoriaSelecionada = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botão de Confirmação e Salvamento
                      ElevatedButton(
                        onPressed: _salvarProduto,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Salvar Produto no Cardápio',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
