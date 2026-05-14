import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cadastro_screen.dart'; // Import da tela de cadastro

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  Future<void> _fazerLogin() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Se chegou aqui, o login deu certo!
      if (userCredential.user != null) {
        // Redireciona para a tela de Cardápio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CardapioScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Tratar erros (senha errada, usuário não existe, etc)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bom Gosto", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "E-mail", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _senhaController,
              decoration: InputDecoration(labelText: "Senha", border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: _fazerLogin,
              child: Text("Entrar"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            TextButton(
              onPressed: () {
                // Navega para a tela de cadastro
                Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroScreen()));
              },
              child: Text("Não tem uma conta? Cadastre-se aqui"),
            ),
          ],
        ),
      ),
    );
  }
}