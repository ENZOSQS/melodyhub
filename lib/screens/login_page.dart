import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> fazerLogin() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final credencial =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      print('Login realizado com sucesso!');
      print('UID: ${credencial.user?.uid}');

      if (!mounted) return;

      // Depois do login, vai para a Home.
      // O pushReplacement impede voltar para o Login
      // usando o botão voltar.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível fazer login.';

      if (e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha incorretos.';
      } else if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        mensagem = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'E-mail inválido.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );

      print('Erro Firebase Auth: ${e.code}');
    } catch (e) {
      print('Erro: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  void abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1736),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),

              child: Container(
                padding: const EdgeInsets.all(28),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // LOGO
                    Center(
                      child: Container(
                        height: 75,
                        width: 75,

                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1736),
                          borderRadius: BorderRadius.circular(22),
                        ),

                        child: const Icon(
                          Icons.music_note,
                          color: Color(0xFF16D9C5),
                          size: 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // NOME
                    const Text(
                      'Melody Hub',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Color(0xFF0B1736),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Aprenda música de um jeito mais divertido.',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TÍTULO
                    const Text(
                      'Bem-vindo de volta!',

                      style: TextStyle(
                        color: Color(0xFF0B1736),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // E-MAIL
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,

                      style: const TextStyle(
                        color: Color(0xFF0B1736),
                      ),

                      decoration: InputDecoration(
                        labelText: 'E-mail',

                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF0B1736),
                        ),

                        filled: true,
                        fillColor: const Color(0xFFF4F6FA),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SENHA
                    TextField(
                      controller: senhaController,
                      obscureText: !mostrarSenha,

                      style: const TextStyle(
                        color: Color(0xFF0B1736),
                      ),

                      decoration: InputDecoration(
                        labelText: 'Senha',

                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF0B1736),
                        ),

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              mostrarSenha = !mostrarSenha;
                            });
                          },

                          icon: Icon(
                            mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,

                            color: Colors.black54,
                          ),
                        ),

                        filled: true,
                        fillColor: const Color(0xFFF4F6FA),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTÃO ENTRAR
                    SizedBox(
                      height: 54,

                      child: ElevatedButton(
                        onPressed: carregando
                            ? null
                            : fazerLogin,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16D9C5),
                          foregroundColor: const Color(0xFF0B1736),
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        child: carregando
                            ? const SizedBox(
                                height: 22,
                                width: 22,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ENTRAR',

                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // DIVISOR
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                          ),

                          child: Text(
                            'ou',

                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // CADASTRO
                    TextButton(
                      onPressed: abrirCadastro,

                      child: const Text(
                        'Não tem uma conta? Cadastre-se',

                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}