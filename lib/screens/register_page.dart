import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> cadastrarUsuario() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
        ),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception(
          'Não foi possível obter o usuário criado.',
        );
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .set({
        'uid': usuario.uid,
        'nome': nome,
        'email': email,
        'xp': 0,
        'nivel': 1,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      await usuario.updateDisplayName(nome);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conta criada com sucesso! Faça login para continuar.',
          ),
        ),
      );

      print('Usuário criado com sucesso!');
      print('UID: ${usuario.uid}');
      print('Nome: $nome');
      print('E-mail: $email');
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível criar a conta.';

      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'O e-mail informado é inválido.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha é muito fraca.';
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

                    const Text(
                      'Criar conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0B1736),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Comece sua jornada musical no Melody Hub.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: nomeController,
                      style: const TextStyle(
                        color: Color(0xFF0B1736),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(
                          Icons.person_outline,
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

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            carregando ? null : cadastrarUsuario,
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
                                'CRIAR CONTA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Já tenho uma conta',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontWeight: FontWeight.bold,
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