import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CadastroFeiticeirosApp());
}

class CadastroFeiticeirosApp extends StatelessWidget {
  const CadastroFeiticeirosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escola Jujutsu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return CentralJujutsuPage(user: user);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _entrando = false;

  Future<void> _entrarComGoogle() async {
    setState(() => _entrando = true);
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem('Falha no login: ${e.message ?? e.code}');
    } catch (e) {
      _mostrarMensagem('Não foi possível entrar com Google. Confira a configuração do Firebase.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF181126), Color(0xFF4C1D95), Color(0xFF111827)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: Color(0xFFEDE9FE),
                        child: Icon(Icons.auto_awesome, size: 42, color: Color(0xFF6D28D9)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ESCOLA JUJUTSU',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Acesso restrito para feiticeiros', textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _entrando ? null : _entrarComGoogle,
                          icon: _entrando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(_entrando ? 'Entrando...' : 'ENTRAR COM GOOGLE'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CentralJujutsuPage extends StatefulWidget {
  const CentralJujutsuPage({super.key, required this.user});

  final User user;

  @override
  State<CentralJujutsuPage> createState() => _CentralJujutsuPageState();
}

class _CentralJujutsuPageState extends State<CentralJujutsuPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  String _grauSelecionado = '2';
  bool _salvando = false;

  CollectionReference<Map<String, dynamic>> get _missoes =>
      FirebaseFirestore.instance.collection('missoes');

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarMissao() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final grau = _grauSelecionado == 'Especial'
          ? 'Especial'
          : int.parse(_grauSelecionado);
      await _missoes.add({
        'titulo': _tituloController.text.trim(),
        'grau': grau,
        'concluida': false,
        'usuarioId': widget.user.uid,
      });
      _tituloController.clear();
      setState(() => _grauSelecionado = '2');
      _mostrarMensagem('Missão cadastrada!');
    } on FirebaseException catch (e) {
      _mostrarMensagem('Erro ao salvar missão: ${e.message ?? e.code}');
    } catch (_) {
      _mostrarMensagem('Não foi possível cadastrar a missão.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alterarConcluida(String id, bool concluida) async {
    try {
      await _missoes.doc(id).update({'concluida': concluida});
    } on FirebaseException catch (e) {
      _mostrarMensagem('Não foi possível atualizar: ${e.message ?? e.code}');
    }
  }

  Future<void> _excluirMissao(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir missão?'),
        content: const Text('Esta missão será removida do banco de dados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _missoes.doc(id).delete();
    } on FirebaseException catch (e) {
      _mostrarMensagem('Não foi possível excluir: ${e.message ?? e.code}');
    }
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // A sessão do Firebase já foi encerrada.
      }
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.user.displayName ?? 'Feiticeiro';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Jujutsu'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: _sair,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _missoes.where('usuarioId', isEqualTo: widget.user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Erro ao carregar missões. Confira as regras do Cloud Firestore.'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final missoes = snapshot.data?.docs.toList() ?? [];
              missoes.sort((a, b) {
                final aConcluida = a.data()['concluida'] == true;
                final bConcluida = b.data()['concluida'] == true;
                return aConcluida == bConcluida ? 0 : (aConcluida ? 1 : -1);
              });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _boasVindas(nome),
                  const SizedBox(height: 16),
                  _formulario(),
                  const SizedBox(height: 20),
                  Text('Minhas missões (${missoes.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (missoes.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Você ainda não cadastrou missões.'),
                      ),
                    ),
                  ...missoes.map((doc) {
                    final dados = doc.data();
                    final titulo = (dados['titulo'] ?? 'Missão sem título').toString();
                    final grau = (dados['grau'] ?? '-').toString();
                    final concluida = dados['concluida'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Checkbox(
                          value: concluida,
                          onChanged: (value) => _alterarConcluida(doc.id, value ?? false),
                        ),
                        title: Text(
                          titulo,
                          style: TextStyle(
                            decoration: concluida ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text('Grau: $grau • ${concluida ? 'Concluída' : 'Pendente'}'),
                        trailing: IconButton(
                          tooltip: 'Excluir missão',
                          onPressed: () => _excluirMissao(doc.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _boasVindas(String nome) {
    final photoUrl = widget.user.photoURL;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bem-vindo, $nome', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(widget.user.email ?? 'E-mail não informado'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cadastrar missão', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título da missão'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o título da missão.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _grauSelecionado,
                decoration: const InputDecoration(labelText: 'Grau da missão'),
                items: const [
                  DropdownMenuItem(value: 'Especial', child: Text('Especial')),
                  DropdownMenuItem(value: '1', child: Text('Grau 1')),
                  DropdownMenuItem(value: '2', child: Text('Grau 2')),
                  DropdownMenuItem(value: '3', child: Text('Grau 3')),
                  DropdownMenuItem(value: '4', child: Text('Grau 4')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _grauSelecionado = value);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _salvando ? null : _cadastrarMissao,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_salvando ? 'Salvando...' : 'Cadastrar missão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
