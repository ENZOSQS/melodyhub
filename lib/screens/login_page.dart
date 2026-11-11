import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/mh_ui.dart';
import 'register_page.dart';

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
  bool manterConectado = true;
  List<String> emailsSalvos = [];
  final SharedPreferencesAsync _preferencias = SharedPreferencesAsync();
  static const String _chaveEmails = 'melodyhub_emails_login';
  static const String _chaveManterConectado = 'melodyhub_manter_conectado';

  @override
  void initState() {
    super.initState();
    _carregarEmailsSalvos();
  }

  Future<void> _carregarEmailsSalvos() async {
    try {
      final emails = await _preferencias.getStringList(_chaveEmails) ?? [];
      final manterConectadoSalvo =
          await _preferencias.getBool(_chaveManterConectado) ?? true;
      if (!mounted) return;
      setState(() {
        emailsSalvos = emails;
        manterConectado = manterConectadoSalvo;
        if (emailController.text.isEmpty && emails.isNotEmpty) {
          emailController.text = emails.first;
        }
      });
    } catch (_) {
      // O preenchimento manual continua disponível se o armazenamento local falhar.
    }
  }

  Future<void> _salvarEmail(String email) async {
    try {
      final emails = await _preferencias.getStringList(_chaveEmails) ?? [];
      final atualizados = [
        email,
        ...emails.where((item) => item.toLowerCase() != email.toLowerCase()),
      ].take(5).toList();
      await _preferencias.setStringList(_chaveEmails, atualizados);
      if (mounted) setState(() => emailsSalvos = atualizados);
    } catch (_) {
      // A falha ao salvar uma sugestão não deve impedir o login.
    }
  }

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
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(
          manterConectado ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      await _salvarEmail(email);
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> recuperarSenha() async {
    var email = emailController.text.trim();
    if (email.isEmpty) {
      final controlador = TextEditingController();
      email =
          (await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Recuperar senha'),
                      content: TextField(
                        controller: controlador,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, controlador.text),
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                  ) ??
                  '')
              .trim();
      // O diálogo ainda está animando a saída; liberar o controlador só depois
      // evita o erro de "TextEditingController used after being disposed".
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        controlador.dispose,
      );
      if (email.isEmpty || !mounted) return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se houver uma conta associada a este e-mail, enviaremos um link para redefinir sua senha.',
          ),
        ),
      );
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;
      final mensagem = switch (erro.code) {
        'invalid-email' => 'Digite um e-mail válido.',
        'user-not-found' =>
          'Se houver uma conta associada a este e-mail, enviaremos um link para redefinir sua senha.',
        _ =>
          'Não foi possível enviar o e-mail de recuperação. Tente novamente.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível enviar o e-mail de recuperação. Tente novamente.',
          ),
        ),
      );
    }
  }

  void abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: MelodyHubLogo(vertical: true, scale: 2)),
                    const SizedBox(height: 56),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 6),
                          child: Icon(Icons.mail_outline_rounded),
                        ),
                        suffixIcon: emailsSalvos.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                tooltip: 'E-mails usados recentemente',
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (email) {
                                  setState(() => emailController.text = email);
                                },
                                itemBuilder: (context) => emailsSalvos
                                    .map(
                                      (email) => PopupMenuItem<String>(
                                        value: email,
                                        child: Text(email),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: senhaController,
                      obscureText: !mostrarSenha,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!carregando) fazerLogin();
                      },
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 6),
                          child: Icon(Icons.lock_outline_rounded),
                        ),
                        suffixIcon: IconButton(
                          tooltip: mostrarSenha
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: () {
                            setState(() => mostrarSenha = !mostrarSenha);
                          },
                          icon: Icon(
                            mostrarSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: carregando ? null : recuperarSenha,
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    if (kIsWeb)
                      CheckboxListTile(
                        value: manterConectado,
                        onChanged: carregando
                            ? null
                            : (valor) async {
                                final selecionado = valor ?? false;
                                setState(() => manterConectado = selecionado);
                                try {
                                  await _preferencias.setBool(
                                    _chaveManterConectado,
                                    selecionado,
                                  );
                                } catch (_) {
                                  // A sessão ainda pode ser definida no login.
                                }
                              },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        title: const Text(
                          'Manter conectado',
                          style: TextStyle(color: AppColors.text),
                        ),
                        subtitle: const Text(
                          'Neste navegador',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: carregando ? null : fazerLogin,
                        child: carregando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: abrirCadastro,
                        child: const Text.rich(
                          TextSpan(
                            text: 'Não tem conta? ',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Cadastre-se',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
