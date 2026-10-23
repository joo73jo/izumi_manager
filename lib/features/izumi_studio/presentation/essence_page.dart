import 'package:flutter/material.dart';

const _forest = Color(0xFF284426);
const _deep = Color(0xFF182B1A);
const _cream = Color(0xFFF7F6F1);
const _sage = Color(0xFFE9EEE5);
const _ink = Color(0xFF292F27);
const _muted = Color(0xFF73786E);
const _line = Color(0xFFDFE4D9);
const _gold = Color(0xFFAA9168);

class EssencePage extends StatelessWidget {
  const EssencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 42),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Cover(),
                  const SizedBox(height: 28),
                  const _Manifesto(),
                  const SizedBox(height: 28),
                  _IdentityPair(wide: constraints.maxWidth > 780),
                  const SizedBox(height: 28),
                  const _Vision(),
                  const SizedBox(height: 28),
                  const _Values(),
                  const SizedBox(height: 28),
                  const _DesignPhilosophy(),
                  const SizedBox(height: 28),
                  const _BrandPersonality(),
                  const SizedBox(height: 34),
                  const Center(
                    child: Text(
                      'IZUMI  /  DISE\u00d1O QUE CONTIENE VIDA',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 390),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_forest, _deep],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -120,
            child: Container(
              height: 340,
              width: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 45,
                ),
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -100,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'E S E N C I A   D E   M A R C A',
                style: TextStyle(
                  letterSpacing: 3,
                  fontSize: 10,
                  color: Color(0xFFCBD7C6),
                ),
              ),
              const SizedBox(height: 45),
              const Text(
                'IZUMI',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 10,
                  fontSize: 53,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 55,
                child: Divider(color: _gold, thickness: 2),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dise\u00f1o que contiene vida.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 530),
                child: const Text(
                  'Una expresi\u00f3n de clase, calma y '
                  'sofisticaci\u00f3n. Objetos que no necesitan '
                  'ocupar mucho espacio para transformarlo.',
                  style: TextStyle(
                    color: Color(0xFFD1DBCF),
                    fontSize: 15,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag('ELEGANCIA'),
                  _Tag('VIDA'),
                  _Tag('MINIMALISMO'),
                  _Tag('EXCLUSIVIDAD ACCESIBLE'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          letterSpacing: 1.3,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Manifesto extends StatelessWidget {
  const _Manifesto();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: _cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('01  /  MANIFIESTO'),
          const SizedBox(height: 22),
          const Text(
            'No vendemos simplemente macetas.',
            style: TextStyle(
              fontSize: 27,
              height: 1.3,
              fontWeight: FontWeight.w300,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vendemos vida, clase y dise\u00f1o.',
            style: TextStyle(
              fontSize: 27,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: _forest,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Creemos que la sofisticaci\u00f3n no depende '
            'de la cantidad de objetos que poseemos. '
            'Una pieza bien elegida puede dar car\u00e1cter '
            'a un espacio, transmitir serenidad y '
            'convertirse en un gesto de afecto memorable.',
            style: TextStyle(fontSize: 15, height: 1.8, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _IdentityPair extends StatelessWidget {
  const _IdentityPair({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    const purpose = _IdentityCard(
      number: '02',
      title: 'Prop\u00f3sito',
      icon: Icons.spa_outlined,
      text:
          'Transformar la manera en que las personas '
          'decoran sus espacios y expresan afecto, '
          'haciendo accesible la sofisticaci\u00f3n mediante '
          'piezas exclusivas que contienen vida.\n\n'
          'Una sola pieza cuidadosamente elegida puede '
          'aportar clase, distinci\u00f3n y serenidad.',
    );

    const mission = _IdentityCard(
      number: '03',
      title: 'Misi\u00f3n',
      icon: Icons.local_florist_outlined,
      text:
          'Crear piezas decorativas exclusivas que '
          'integren naturaleza, minimalismo y dise\u00f1o '
          'contempor\u00e1neo, destinadas a transformar '
          'peque\u00f1os espacios y convertirse en regalos '
          'sofisticados y memorables.\n\n'
          'Ofrecer una experiencia de compra elegante '
          'y accesible, donde cada producto represente '
          'una forma diferente de regalar vida.',
    );

    if (!wide) {
      return const Column(children: [purpose, SizedBox(height: 18), mission]);
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: purpose),
        SizedBox(width: 18),
        Expanded(child: mission),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.text,
  });

  final String number;
  final String title;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('$number  /  IDENTIDAD'),
          const SizedBox(height: 20),
          Icon(icon, color: _forest, size: 33),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontSize: 27,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: _ink, fontSize: 14, height: 1.85),
          ),
        ],
      ),
    );
  }
}

class _Vision extends StatelessWidget {
  const _Vision();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: _sage,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('04  /  NUESTRO FUTURO'),
          SizedBox(height: 18),
          Text(
            'Visi\u00f3n',
            style: TextStyle(
              color: _forest,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Convertir a Izumi en una marca digital '
            'reconocida por sus colecciones exclusivas, '
            'su elegancia minimalista y una propuesta '
            'que une dise\u00f1o y naturaleza.\n\n'
            'Construir una empresa rentable, con '
            'procesos eficientes y progresivamente '
            'automatizados, capaz de ofrecer una '
            'experiencia premium sin depender de una '
            'estructura empresarial grande.',
            style: TextStyle(color: _ink, fontSize: 15, height: 1.8),
          ),
        ],
      ),
    );
  }
}

class _Values extends StatelessWidget {
  const _Values();

  static const entries = [
    (
      Icons.diamond_outlined,
      'Clase y sofisticaci\u00f3n',
      'Elegancia discreta, buen gusto y distinci\u00f3n '
          'sin necesidad de ostentaci\u00f3n.',
    ),
    (
      Icons.spa_outlined,
      'Vida',
      'La naturaleza es el centro de cada pieza. '
          'Regalamos vida y promovemos su cuidado.',
    ),
    (
      Icons.eco_outlined,
      'Zero Waste',
      'Un compromiso con el consumo consciente, '
          'la reducci\u00f3n de residuos y el uso responsable '
          'de los recursos.',
    ),
    (
      Icons.auto_awesome_outlined,
      'Exclusividad accesible',
      'Experiencias sofisticadas y dise\u00f1os '
          'singulares sin precios inalcanzables.',
    ),
    (
      Icons.interests_outlined,
      'Creatividad',
      'Originalidad y colecciones reconocibles '
          'dentro de una identidad coherente.',
    ),
    (
      Icons.favorite_border,
      'Cuidado',
      'La experiencia del cliente contin\u00faa '
          'despu\u00e9s de recibir su producto.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('05  /  LO QUE NOS DEFINE'),
          const SizedBox(height: 14),
          const Text(
            'Nuestros valores',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: _forest,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Principios que expresan la personalidad '
            'y el compromiso de Izumi.',
            style: TextStyle(color: _muted, height: 1.6),
          ),
          const SizedBox(height: 25),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 650;
              final width = wide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: _ValueTile(
                        icon: entry.$1,
                        title: entry.$2,
                        description: entry.$3,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _forest, size: 27),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _forest,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: _muted, height: 1.65, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DesignPhilosophy extends StatelessWidget {
  const _DesignPhilosophy();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: _deep,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '06  /  FILOSOF\u00cdA DE DISE\u00d1O',
            style: TextStyle(
              letterSpacing: 2,
              fontSize: 10,
              color: Color(0xFFC9D5C3),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'La verdadera elegancia\nno necesita excesos.',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w300,
              height: 1.35,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'Una pieza. Un espacio. Vida.',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFFD9C6A5),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Dise\u00f1amos piezas de est\u00e9tica '
            'minimalista, formas cuidadosamente '
            'seleccionadas y colores sobrios. '
            'Objetos capaces de convertirse en '
            'protagonistas sin saturar el entorno.\n\n'
            'La impresi\u00f3n 3D es nuestra herramienta '
            'de fabricaci\u00f3n, no nuestra identidad '
            'visual. La tecnolog\u00eda existe al '
            'servicio del dise\u00f1o.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFDAE3D8),
              height: 1.9,
            ),
          ),
          SizedBox(height: 28),
          Divider(color: Colors.white24),
          SizedBox(height: 22),
          Text(
            'Si parece un producto de impresi\u00f3n 3D, '
            'fallamos. Si parece una pieza de dise\u00f1o '
            'que adem\u00e1s contiene vida, acertamos.',
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPersonality extends StatelessWidget {
  const _BrandPersonality();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      background: _cream,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow('07  /  PERSONALIDAD DE MARCA'),
          SizedBox(height: 18),
          Text(
            'Sofisticada. Serena. Segura.',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w300,
              color: _forest,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Izumi es reservada, moderna y creativa. '
            'Su elegancia no necesita exageraciones. '
            'Se identifica con espacios despejados, '
            'colores sobrios, materiales de apariencia '
            'natural y objetos cuidadosamente elegidos.\n\n'
            'Su lenguaje es cercano, preciso y sereno. '
            'Tiene sentido del humor, pero nunca pierde '
            'su clase. Prefiere una pieza excepcional '
            'antes que una acumulaci\u00f3n de objetos.',
            style: TextStyle(color: _ink, fontSize: 15, height: 1.85),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _gold,
        letterSpacing: 2.5,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(29),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: background == Colors.white ? _line : Colors.transparent,
        ),
      ),
      child: child,
    );
  }
}
