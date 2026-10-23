import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _forest = Color(0xFF284426);
const _deep = Color(0xFF1A2D18);
const _ivory = Color(0xFFF4F2ED);
const _sage = Color(0xFFE7ECE4);
const _taupe = Color(0xFFB8A48B);
const _stone = Color(0xFF726F68);
const _ink = Color(0xFF283029);
const _line = Color(0xFFDFE5D9);

class VisualIdentityPage extends StatelessWidget {
  const VisualIdentityPage({super.key});

  static const colors = [
    ('Verde Izumi', '#284426', _forest, 'Principal'),
    ('Verde profundo', '#1A2D18', _deep, 'Contraste'),
    ('Marfil', '#F4F2ED', _ivory, 'Fondo claro'),
    ('Sage', '#E7ECE4', _sage, 'Fondo secundario'),
    ('Taupe', '#B8A48B', _taupe, 'Acentos'),
    ('Piedra', '#726F68', _stone, 'Texto secundario'),
  ];

  static const fonts = [
    (
      'Autography',
      'Logotipo oficial',
      'Firma manuscrita de la marca.',
      Icons.draw_outlined,
    ),
    (
      'Cormorant Garamond',
      'Titulares editoriales',
      'Colecciones, packaging y portadas.',
      Icons.title,
    ),
    (
      'Great Vibes',
      'Caligraf\u00eda especial',
      'Detalles discretos y ediciones especiales.',
      Icons.edit_outlined,
    ),
    (
      'Manrope',
      'Comunicaci\u00f3n principal',
      'Textos corporativos y descripciones.',
      Icons.article_outlined,
    ),
    (
      'Inter',
      'Informaci\u00f3n funcional',
      'Precios, datos y tienda digital.',
      Icons.view_headline,
    ),
    (
      'Plus Jakarta Sans',
      'Comunicaci\u00f3n comercial',
      'Redes sociales y cat\u00e1logos.',
      Icons.web_outlined,
    ),
  ];

  String? get logoPath {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) return null;

    final directory =
        '$appData\\com.izumi\\izumi_manager'
        '\\visual_identity';

    for (final ext in ['png', 'jpg', 'jpeg', 'webp']) {
      final path = '$directory\\logo.$ext';
      if (File(path).existsSync()) return path;
    }

    return null;
  }

  Future<void> copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$value copiado')));
  }

  Widget section(
    String eyebrow,
    String title,
    Widget content, {
    Color background = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(27),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: _taupe,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w500,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget logo(BuildContext context) {
    final path = logoPath;

    return section(
      '01 / FIRMA DE MARCA',
      'Nuestro logotipo',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 240),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _forest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: path == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Izumi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 65,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Selecciona el archivo original del '
                          'logotipo desde Windows.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  : Image.file(
                      File(path),
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'No se pudo abrir el logotipo.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Autography es la tipograf\u00eda original '
            'de nuestra firma. El logotipo debe '
            'conservar sus proporciones, trazos '
            'y elegancia manuscrita.',
            style: TextStyle(color: _ink, height: 1.7),
          ),
          const SizedBox(height: 15),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag('Principal: blanco sobre verde'),
              _MiniTag('Inversa: verde sobre marfil'),
              _MiniTag('Monocrom\u00e1tica'),
            ],
          ),
        ],
      ),
    );
  }

  Widget palette(BuildContext context) {
    return section(
      '02 / SISTEMA CROM\u00c1TICO',
      'Paleta de colores',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Una paleta sobria inspirada en '
            'la naturaleza, el minimalismo '
            'y la elegancia discreta.',
            style: TextStyle(color: _stone, height: 1.7),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 400
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in colors)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: () => copy(context, color.$2),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _ivory,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: color.$3,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(13),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(13),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      color.$1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _ink,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      color.$2,
                                      style: const TextStyle(
                                        color: _forest,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      color.$4,
                                      style: const TextStyle(
                                        color: _stone,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Pulsa un color para copiar su c\u00f3digo HEX.',
            style: TextStyle(fontSize: 12, color: _stone),
          ),
        ],
      ),
    );
  }

  Widget typography() {
    return section(
      '03 / IDENTIDAD TIPOGR\u00c1FICA',
      'Nuestras seis tipograf\u00edas',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Una familia tipogr\u00e1fica flexible '
            'con aplicaciones espec\u00edficas. '
            'La caligraf\u00eda se utiliza con moderaci\u00f3n '
            'para mantener una composici\u00f3n limpia.',
            style: TextStyle(color: _stone, height: 1.7),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < fonts.length; index++) ...[
            _FontLine(
              index: index + 1,
              name: fonts[index].$1,
              purpose: fonts[index].$2,
              detail: fonts[index].$3,
              icon: fonts[index].$4,
            ),
            if (index < fonts.length - 1)
              const Divider(color: _line, height: 24),
          ],
        ],
      ),
    );
  }

  Widget photographic() {
    return section(
      '04 / DIRECCI\u00d3N FOTOGR\u00c1FICA',
      'La est\u00e9tica Izumi',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calma, luz natural y una sola pieza protagonista.',
            style: TextStyle(
              fontSize: 21,
              color: _forest,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          _Principle(
            Icons.wb_sunny_outlined,
            'Iluminaci\u00f3n',
            'Luz suave, natural y sombras delicadas.',
          ),
          _Principle(
            Icons.chair_outlined,
            'Escenograf\u00eda',
            'Madera, lino, piedra y superficies sobrias.',
          ),
          _Principle(
            Icons.crop_free,
            'Composici\u00f3n',
            'Espacios despejados y una maceta como protagonista.',
          ),
          _Principle(
            Icons.palette_outlined,
            'Colores',
            'Tonos neutros, verdes profundos y marfiles c\u00e1lidos.',
          ),
        ],
      ),
    );
  }

  Widget packaging() {
    return section(
      '05 / PRESENTACI\u00d3N DE PRODUCTO',
      'Packaging Izumi',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Una experiencia editorial, sofisticada '
            'y premium accesible.',
            style: TextStyle(fontSize: 21, color: _forest, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            'El empaque debe elevar el valor percibido '
            'sin elevar innecesariamente el costo. '
            'Preferimos materiales sencillos, '
            'una composici\u00f3n cuidada, '
            'tipograf\u00eda elegante y detalles discretos.\n\n'
            'Las colecciones limitadas pueden integrar '
            'su nombre, historia y numeraci\u00f3n '
            'en el propio empaque.',
            style: TextStyle(color: _ink, height: 1.85),
          ),
        ],
      ),
    );
  }

  Widget rules() {
    return section(
      '06 / NORMAS DE IDENTIDAD',
      'Principios de aplicaci\u00f3n',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rule(
            'Mantener',
            'Proporciones originales del logotipo, '
                'espacios amplios, contraste, '
                'sobriedad y jerarqu\u00eda visual.',
            Icons.check_circle_outline,
            _forest,
          ),
          SizedBox(height: 15),
          _Rule(
            'Evitar',
            'Sombras exageradas, colores saturados, '
                'tipograf\u00edas mezcladas sin criterio, '
                'ornamentos innecesarios y composiciones '
                'recargadas.',
            Icons.remove_circle_outline,
            _stone,
          ),
          SizedBox(height: 22),
          Text(
            'Menos elementos. M\u00e1s intenci\u00f3n.',
            style: TextStyle(
              color: _forest,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 45),
      children: [
        Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: _deep,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IZUMI / VISUAL IDENTITY',
                style: TextStyle(color: _taupe, fontSize: 11, letterSpacing: 3),
              ),
              SizedBox(height: 29),
              Text(
                'El arte de la elegancia discreta.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.3,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Un sistema visual que expresa '
                'clase, minimalismo y naturaleza.',
                style: TextStyle(
                  color: Color(0xFFD5DED0),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        logo(context),
        const SizedBox(height: 18),
        palette(context),
        const SizedBox(height: 18),
        typography(),
        const SizedBox(height: 18),
        photographic(),
        const SizedBox(height: 18),
        packaging(),
        const SizedBox(height: 18),
        rules(),
        const SizedBox(height: 26),
        const Center(
          child: Text(
            'IZUMI / DISE\u00d1O QUE CONTIENE VIDA',
            style: TextStyle(color: _stone, fontSize: 10, letterSpacing: 2),
          ),
        ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(value, style: const TextStyle(color: _forest, fontSize: 11)),
    );
  }
}

class _FontLine extends StatelessWidget {
  const _FontLine({
    required this.index,
    required this.name,
    required this.purpose,
    required this.detail,
    required this.icon,
  });

  final int index;
  final String name;
  final String purpose;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _forest,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purpose,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(
                    color: _stone,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            index.toString().padLeft(2, '0'),
            style: const TextStyle(color: _taupe, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _forest, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _forest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: _stone, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.title, this.description, this.icon, this.color);

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(color: _ink, height: 1.7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
