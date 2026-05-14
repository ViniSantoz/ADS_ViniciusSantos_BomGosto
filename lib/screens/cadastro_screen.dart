import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CadastroScreen extends StatefulWidget {
  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar os dados conforme o DVP
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Função que verifica o e-mail e realiza o cadastro
  Future<void> _processarCadastro() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Verifica se o e-mail já existe (Regra HU01 do DVP)
        final metodos = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(_emailController.text.trim());

        if (metodos.isNotEmpty) {
          _mostrarMensagem("Este e-mail já está em uso por outra conta.");
          return;
        }

        // 2. Tenta criar o usuário no Firebase Auth
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );

        _mostrarMensagem("Cadastro realizado com sucesso!");
        
        // Após sucesso, retorna para a tela de login
        Navigator.pop(context); 

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _mostrarMensagem("Erro: O e-mail já está cadastrado.");
        } else {
          _mostrarMensagem("Erro ao cadastrar: ${e.message}");
        }
      } catch (e) {
        _mostrarMensagem("Ocorreu um erro inesperado.");
      }
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro - Bom Gosto")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo Nome (RF01)
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Informe seu nome" : null,
              ),
              SizedBox(height: 15),
              
              // Campo Endereço (HU08)
              TextFormField(
                controller: _enderecoController,
                decoration: InputDecoration(labelText: "Endereço de Entrega", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Informe seu endereço" : null,
              ),
              SizedBox(height: 15),

              // Campo Telefone (RF01 / HU04)
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: "Telefone", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Informe seu telefone" : null,
              ),
              SizedBox(height: 15),

              // Campo E-mail (RF01)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "E-mail", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains("@") ? "E-mail inválido" : null,
              ),
              SizedBox(height: 15),

              // Campo Senha (RF01)
              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(labelText: "Senha", border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.length < 6 ? "A senha deve ter no mínimo 6 caracteres" : null,
              ),
              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _processarCadastro,
                child: Text("Finalizar Cadastro"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}