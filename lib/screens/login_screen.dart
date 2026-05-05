import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';
import 'cardapio_screen.dart';

// Tela de Login (primeira tela do app)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Chave usada para validar o formulário
  final _formKey = GlobalKey<FormState>();
  // Controllers capturam o texto digitado nos campos
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _auth = AuthService();

  bool _carregando = false; // controla o spinner do botão

  // Função chamada ao apertar "Entrar"
  Future<void> _entrar() async {
  // Valida os campos do formulário (email e senha)
  // Se algum estiver inválido, interrompe a execução
  if (!_formKey.currentState!.validate()) return;

  // Ativa o estado de carregando -> botão mostra o spinner
  setState(() => _carregando = true);

  // Chama o serviço de autenticação (Firebase Auth)
  // Retorna null em caso de sucesso, ou uma String com a mensagem de erro
  final erro = await AuthService().login(
    email: _emailController.text.trim(),
    senha: _senhaController.text,
  );

  // Verifica se o widget ainda está montado antes de usar o context
  // (evita erro caso o usuário saia da tela durante a chamada)
  if (!mounted) return;

  // Desativa o estado de carregando
  setState(() => _carregando = false);

  if (erro == null) {
    // ✅ Login deu certo: navega para a tela do cardápio
    // pushReplacement substitui a tela atual -> usuário não consegue
    // voltar para a tela de login pelo botão "voltar"
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CardapioScreen()),
    );
  } else {
    // ❌ Erro no login: mostra um SnackBar vermelho com a mensagem
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erro),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    // Libera os controllers da memória
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant, size: 80, color: Colors.deepOrange),
                const SizedBox(height: 16),
                const Text('Restaurante',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                // Campo de e-mail
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 16),

                // Campo de senha
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: true, // esconde os caracteres
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),

                // Link "Esqueci minha senha"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecuperarSenhaScreen()),
                    ),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                const SizedBox(height: 8),

                // Botão Entrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Entrar', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Link para tela de cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem conta? '),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroScreen()),
                      ),
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
