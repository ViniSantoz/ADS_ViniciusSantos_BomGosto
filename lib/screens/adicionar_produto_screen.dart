import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarProdutoScreen extends StatefulWidget {
  const AdicionarProdutoScreen({super.key});

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  String _categoriaSelecionada = 'Lanches'; // Valor padrão

  final List<String> _categorias = ['Lanches', 'Porções', 'Bebidas'];

  Future<void> _salvarProduto() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Integração com Firebase Firestore (RF03)
        await FirebaseFirestore.instance.collection('produtos').add({
          'nome': _nomeController.text,
          'descricao': _descricaoController.text,
          'preco': double.parse(_precoController.text),
          'categoria': _categoriaSelecionada,
          'disponivel': true, // Regra de disponibilidade do DVP
          'dataCriacao': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto adicionado com sucesso!')),
        );

        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOM GOSTO - Novo Produto')),
      body: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ), // Correção: de double.all para EdgeInsets.all
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço (Ex: 25.50)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Informe o preço' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                items: _categorias.map((String categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? novoValor) {
                  setState(() => _categoriaSelecionada = novoValor!);
                },
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _salvarProduto,
                child: const Text('Cadastrar Produto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
