import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _green = Color(0xFF284426);
const _dark = Color(0xFF192B1D);
const _cream = Color(0xFFF7F6F1);
const _sage = Color(0xFFEAF0E8);
const _gold = Color(0xFFB5A07B);
const _ink = Color(0xFF30362F);
const _muted = Color(0xFF72796E);

class _Account {
  const _Account({
    required this.id,
    required this.service,
    required this.user,
    required this.hasPassword,
  });

  final String id;
  final String service;
  final String user;
  final bool hasPassword;

  factory _Account.fromJson(Map<String, dynamic> json) {
    return _Account(
      id: json['id'] as String,
      service: json['service'] as String,
      user: json['user'] as String,
      hasPassword: json['hasPassword'] == true,
    );
  }
}

class _Vault {
  static String get scriptPath {
    final appData = Platform.environment['APPDATA'];

    if (appData == null || appData.isEmpty) {
      throw StateError('No se encontr? APPDATA de Windows.');
    }

    return '$appData\\com.izumi\\izumi_manager'
        '\\credentials\\vault.ps1';
  }

  static Future<Map<String, dynamic>> call(Map<String, dynamic> request) async {
    final process = await Process.start('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptPath,
    ], runInShell: false);

    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();

    process.stdin.writeln(jsonEncode(request));
    await process.stdin.flush();
    await process.stdin.close();

    final result = await output;
    final error = await errors;
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw StateError(
        error.trim().isEmpty
            ? 'No se pudo acceder a las credenciales.'
            : error.trim(),
      );
    }

    return Map<String, dynamic>.from(jsonDecode(result));
  }

  static Future<List<_Account>> all() async {
    final data = await call({'action': 'list'});

    return (data['items'] as List<dynamic>)
        .map(
          (item) => _Account.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<void> save(
    String id,
    String service,
    String user,
    String password,
  ) async {
    await call({
      'action': 'save',
      'id': id,
      'service': service,
      'user': user,
      'password': password,
    });
  }

  static Future<String> reveal(String id) async {
    final data = await call({'action': 'reveal', 'id': id});

    return data['password'] as String? ?? '';
  }

  static Future<void> remove(String id) async {
    await call({'action': 'delete', 'id': id});
  }
}

class CorporateIdentityPage extends StatefulWidget {
  const CorporateIdentityPage({super.key});

  @override
  State<CorporateIdentityPage> createState() => _CorporateIdentityPageState();
}

class _CorporateIdentityPageState extends State<CorporateIdentityPage> {
  static const email = 'izumiecu@gmail.com';

  static const biography =
      'IZUMI | Living Design \u{1F33F}\n'
      '\u{1F90D} Dise\u00f1o de autor \u00b7 Minimalismo\n'
      '\u2728 The art of living beautifully\n'
      '\u{1F4CD} Quito, Ecuador \u{1F1EA}\u{1F1E8}';

  late Future<List<_Account>> accounts;

  String? visibleId;
  String? visiblePassword;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    setState(() {
      accounts = _Vault.all();
      visibleId = null;
      visiblePassword = null;
    });
  }

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    message('Copiado al portapapeles.');
  }

  Future<void> editAccount([_Account? account]) async {
    final service = TextEditingController(text: account?.service ?? '');
    final user = TextEditingController(text: account?.user ?? '');
    final password = TextEditingController();

    final formKey = GlobalKey<FormState>();
    var obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, update) {
            return AlertDialog(
              title: Text(
                account == null ? 'Registrar acceso' : 'Actualizar acceso',
              ),
              content: SizedBox(
                width: 470,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: service,
                        decoration: const InputDecoration(
                          labelText: 'Plataforma',
                          hintText: 'Ej. Gmail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa la plataforma.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: user,
                        decoration: const InputDecoration(
                          labelText: 'Correo o usuario',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa el correo o usuario.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: password,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: account == null
                              ? 'Contrase\u00f1a'
                              : 'Nueva contrase\u00f1a (opcional)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              update(() => obscure = !obscure);
                            },
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (account == null &&
                              (value == null || value.isEmpty)) {
                            return 'Ingresa una contrase\u00f1a.';
                          }
                          return null;
                        },
                      ),
                      if (account != null) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Deja vac?a la contrase\u00f1a para conservar '
                          'la actual.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Guardar acceso'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await _Vault.save(
          account?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          service.text.trim(),
          user.text.trim(),
          password.text,
        );
        if (mounted) {
          refresh();
          message('Acceso guardado y protegido por Windows.');
        }
      } catch (error) {
        message('Error: $error');
      }
    }

    service.dispose();
    user.dispose();
    password.dispose();
  }

  Future<void> togglePassword(_Account account) async {
    if (visibleId == account.id) {
      setState(() {
        visibleId = null;
        visiblePassword = null;
      });
      return;
    }

    try {
      final password = await _Vault.reveal(account.id);
      if (!mounted) return;

      setState(() {
        visibleId = account.id;
        visiblePassword = password;
      });
    } catch (error) {
      message('No se pudo mostrar: $error');
    }
  }

  Future<void> deleteAccount(_Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar acceso'),
        content: Text('?Eliminar las credenciales de ${account.service}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _Vault.remove(account.id);
      if (mounted) {
        refresh();
        message('Acceso eliminado.');
      }
    } catch (error) {
      message('Error: $error');
    }
  }

  Widget panel({
    required String eyebrow,
    required String title,
    required Widget child,
    Color background = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDFE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: _gold,
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: _green,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget channel(IconData icon, String name, String detail, bool registered) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 27, color: _green),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            registered ? Icons.check_circle_outline : Icons.schedule_outlined,
            color: registered ? _green : _muted,
          ),
        ],
      ),
    );
  }

  Widget accountCard(_Account account) {
    final shown = visibleId == account.id;
    final password = shown ? (visiblePassword ?? '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  account.service,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: () => editAccount(account),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: () => deleteAccount(account),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(account.user),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  shown
                      ? password
                      : account.hasPassword
                      ? '????????????'
                      : 'Sin contrase\u00f1a',
                  style: const TextStyle(color: _ink, fontSize: 15),
                ),
              ),
              IconButton(
                tooltip: shown ? 'Ocultar' : 'Mostrar',
                onPressed: account.hasPassword
                    ? () => togglePassword(account)
                    : null,
                icon: Icon(
                  shown
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Copiar contrase\u00f1a',
                onPressed: account.hasPassword
                    ? () async {
                        try {
                          final secret = shown
                              ? password
                              : await _Vault.reveal(account.id);
                          await copy(secret);
                        } catch (error) {
                          message('Error: $error');
                        }
                      }
                    : null,
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        Container(
          padding: const EdgeInsets.all(34),
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IZUMI / CORPORATE IDENTITY',
                style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3),
              ),
              SizedBox(height: 28),
              Text(
                'Nuestra presencia.\nNuestra identidad.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.3,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'La informaci\u00f3n institucional '
                'y los canales oficiales de Izumi.',
                style: TextStyle(color: Color(0xFFD2DCCE), fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        panel(
          eyebrow: '01 / INFORMACI?N EMPRESARIAL',
          title: 'Perfil corporativo',
          child: Column(
            children: [
              profileRow('Marca', 'IZUMI'),
              profileRow('Identidad', 'Izumi | Living Design'),
              profileRow('Sede', 'Quito, Ecuador'),
              profileRow('Mercado', 'Ecuador'),
              profileRow('Canal comercial', '100 % en l\u00ednea'),
              profileRow('Posicionamiento', 'Premium accesible'),
              profileRow(
                'Actividad',
                'Dise\u00f1o y comercializaci?n de piezas '
                    'decorativas que contienen vida.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        panel(
          eyebrow: '02 / CANALES OFICIALES',
          title: 'Presencia digital',
          child: Column(
            children: [
              channel(Icons.email_outlined, 'Gmail', email, true),
              channel(
                Icons.camera_alt_outlined,
                'Instagram',
                'Cuenta creada con el correo oficial',
                true,
              ),
              channel(
                Icons.chat_outlined,
                'WhatsApp Business',
                'Pendiente de nuevo chip',
                false,
              ),
              channel(
                Icons.play_circle_outline,
                'TikTok',
                'Cuenta pendiente de registrar',
                false,
              ),
              channel(
                Icons.groups_outlined,
                'Facebook',
                'P?gina pendiente de registrar',
                false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        panel(
          eyebrow: '03 / INSTAGRAM',
          title: 'Biograf\u00eda oficial',
          background: _sage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SelectableText(
                biography,
                style: TextStyle(fontSize: 17, height: 1.8, color: _ink),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => copy(biography),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar biograf\u00eda'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        panel(
          eyebrow: '04 / SEGURIDAD CORPORATIVA',
          title: 'Credenciales y accesos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contrase\u00f1as protegidas con el cifrado '
                'DPAPI de tu cuenta de Windows. '
                'No se guardan en GitHub.',
                style: TextStyle(color: _muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<_Account>>(
                future: accounts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Error al cargar credenciales: '
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;

                  return Column(
                    children: [
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Todav\u00eda no hay contrase\u00f1as registradas.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      for (final item in items) accountCard(item),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => editAccount(),
                icon: const Icon(Icons.add),
                label: const Text('Registrar credencial'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Center(
          child: Text(
            'IZUMI / DISE\u00d1O QUE CONTIENE VIDA',
            style: TextStyle(color: _muted, letterSpacing: 2, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
