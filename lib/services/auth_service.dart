import 'package:firebase_auth/firebase_auth.dart';

// Classe responsável por toda a lógica de autenticação com Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Faz login com email e senha. Retorna null se deu certo, ou mensagem de erro.
  Future<String?> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null; // sucesso
    } on FirebaseAuthException catch (e) {
      // Traduz alguns códigos de erro comuns do Firebase
      if (e.code == 'user-not-found') return 'Usuário não encontrado';
      if (e.code == 'wrong-password') return 'Senha incorreta';
      if (e.code == 'invalid-email') return 'E-mail inválido';
      return 'Erro ao entrar: ${e.message}';
    }
  }

  // Cria uma nova conta com email e senha
  Future<String?> cadastrar(String email, String senha) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'E-mail já cadastrado';
      if (e.code == 'weak-password') return 'Senha muito fraca (mínimo 6 caracteres)';
      if (e.code == 'invalid-email') return 'E-mail inválido';
      return 'Erro ao cadastrar: ${e.message}';
    }
  }

  // Envia email de recuperação de senha
  Future<String?> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'E-mail não cadastrado';
      return 'Erro: ${e.message}';
    }
  }

  // Faz logout do usuário atual
  Future<void> logout() async => await _auth.signOut();
}
