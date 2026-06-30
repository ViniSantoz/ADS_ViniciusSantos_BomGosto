import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar os dados digitados
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  
  bool _carregando = true;
  bool _salvando = false;
  String _emailUsuario = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  // Função para buscar os dados atuais no Firestore
  Future<void> _carregarDadosUsuario() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _emailUsuario = user.email ?? '';
        });

        // Busca o documento correspondente ao UID do usuário logado
        DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          _nomeController.text = dados['nome'] ?? '';
          _telefoneController.text = dados['telefone'] ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  // Função para atualizar os dados (Salvar)
  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Atualiza os dados no documento específico do usuário usando o UID
        await _firestore.collection('usuarios').doc(user.uid).update({
          'nome': _nomeController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso! 🎉')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    } finally {
      setState(() {
        _salvando = false;
      });
    }
  }

  // Função de Logout (Opcional, mas excelente para a experiência do usuário)
  Future<void> _fazerLogout() async {
    await _auth.signOut();
    // Substitua pelo nome da sua tela inicial/login se necessário
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEU PERFIL'),
        centerTitle: true,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Cor vermelha do botão
              foregroundColor: Colors.white, // Cor do texto e ícone
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Sair da Conta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              // 1. Desloga o usuário do Firebase
              await FirebaseAuth.instance.signOut();

              // 2. Redireciona para a tela de login limpando o histórico
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()), // Destino corrigido para Login
                  (route) => false, // Impede o usuário de voltar usando o botão físico do celular
                );
              }
            },
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amber,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo de E-mail (Apenas visualização por segurança)
                    TextFormField(
                      initialValue: _emailUsuario,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                      ),
                      enabled: false, // Bloqueia a edição deste campo
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Nome (Editável)
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Telefone (Editável)
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / Celular',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu telefone.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Botão de Salvar Alterações
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _salvando ? null : _salvarDados,
                      child: _salvando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SALVAR ALTERAÇÕES',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
}