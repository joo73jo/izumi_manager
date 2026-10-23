import 'package:flutter/material.dart';

const forest = Color(0xFF284426);
const dark = Color(0xFF192B1D);
const cream = Color(0xFFF7F6F1);
const sage = Color(0xFFEAF0E8);
const gold = Color(0xFFB5A07B);
const ink = Color(0xFF30362F);

class BusinessPlanPage extends StatelessWidget {
  const BusinessPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _hero(),
        const SizedBox(height: 22),
        _panel(
          '01 / RESUMEN EJECUTIVO',
          'Una nueva forma de regalar vida',
          'Izumi es una marca ecuatoriana de dise\u00f1o de autor '
              'accesible. Crea piezas decorativas minimalistas '
              'que contienen plantas vivas.\n\n'
              'Su propuesta combina clase, exclusividad, '
              'dise\u00f1o contempor\u00e1neo y una experiencia '
              'premium accesible.\n\n'
              'El objetivo empresarial es un negocio digital, '
              'rentable, de estructura peque\u00f1a y con '
              'procesos progresivamente automatizados.',
        ),
        const SizedBox(height: 18),
        _panel(
          '02 / POSICIONAMIENTO',
          'Dise\u00f1o de autor accesible',
          'Izumi compite por la originalidad de sus dise\u00f1os, '
              'una identidad reconocible y una experiencia '
              'de compra elegante.\n\n'
              'No busca ser la maceta m\u00e1s barata del mercado '
              'ni competir como un vivero convencional.\n\n'
              'Categor\u00eda: decoraci\u00f3n viva y regalos elegantes.\n'
              'Canal: completamente digital.\n'
              'Est\u00e9tica: minimalista, sofisticada y moderna.',
        ),
        const SizedBox(height: 18),
        _panel(
          '03 / CLIENTES',
          'Joss y Erico',
          'Nuestros perfiles ideales valoran la elegancia '
              'discreta, los colores sobrios, los espacios '
              'despejados y los objetos seleccionados '
              'cuidadosamente.\n\n'
              'Dos ocasiones principales de compra:\n'
              '\u2022 Decorar peque\u00f1os espacios del hogar.\n'
              '\u2022 Regalar algo elegante, distinto y con vida.\n\n'
              'Izumi propone transformar un espacio o expresar '
              'afecto mediante una pieza de dise\u00f1o vivo.',
        ),
        const SizedBox(height: 18),
        _panel(
          '04 / DIFERENCIACI\u00d3N',
          'No solamente una maceta',
          'El principal diferenciador es el dise\u00f1o '
              'exclusivo y reconocible.\n\n'
              'La experiencia incluye una presentaci\u00f3n '
              'editorial sofisticada, packaging premium '
              'accesible y acompa\u00f1amiento posterior '
              'a la compra.\n\n'
              'Cada maceta incluye una reposici\u00f3n gratuita '
              'de planta, por una sola ocasi\u00f3n, '
              'con costo de env\u00edo a cargo del cliente.',
        ),
        const SizedBox(height: 18),
        _panel(
          '05 / MODELO OPERATIVO',
          'Digital, peque\u00f1o y eficiente',
          'La operaci\u00f3n ser\u00e1 completamente en l\u00ednea.\n\n'
              'Producci\u00f3n h\u00edbrida:\n'
              '\u2022 Inventario listo para modelos de alta rotaci\u00f3n.\n'
              '\u2022 Fabricaci\u00f3n bajo pedido para '
              'personalizaciones y referencias especiales.\n\n'
              'Las colecciones mantendr\u00e1n una est\u00e9tica '
              'coherente, con dise\u00f1os permanentes '
              'y ediciones limitadas.\n\n'
              'Izumi Manager centralizar\u00e1 la gesti\u00f3n '
              'operativa y financiera.',
        ),
        const SizedBox(height: 18),
        _panel(
          '06 / ESTRATEGIA FINANCIERA',
          'Rentabilidad primero',
          'El negocio priorizar\u00e1 la disciplina '
              'financiera y el uso eficiente de recursos.\n\n'
              'Para el costeo interno de impresi\u00f3n '
              'se registra el filamento consumido. '
              'Electricidad, mantenimiento y desgaste '
              'se administran mediante la reserva '
              'general del negocio.\n\n'
              'El esquema acordado contempla reservar '
              'la mitad del margen para el negocio. '
              'La ganancia distribuible restante '
              'se reparte 65 % y 35 % entre los socios.\n\n'
              'Las ventas no se confundir\u00e1n '
              'con utilidades.',
        ),
        const SizedBox(height: 18),
        _panel(
          '07 / MARCA',
          'Clase, calma y vida',
          'Izumi comunica elegancia, sofisticaci\u00f3n '
              'discreta, admiraci\u00f3n y cuidado.\n\n'
              'Su est\u00e9tica se inspira en el minimalismo, '
              'los tonos sobrios y el estilo old money.\n\n'
              'El compromiso Zero Waste forma parte '
              'de sus principios, orientado a la '
              'reducci\u00f3n y aprovechamiento responsable '
              'de recursos.\n\n'
              'Mensaje central:\n'
              'Izumi. Dise\u00f1o que contiene vida.',
        ),
        const SizedBox(height: 18),
        _books(),
        const SizedBox(height: 18),
        _next(),
        const SizedBox(height: 30),
        const Center(
          child: Text(
            'IZUMI / ESTRATEGIA DE NEGOCIO',
            style: TextStyle(color: forest, fontSize: 11, letterSpacing: 3),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IZUMI / PLAN DE NEGOCIO 2026',
            style: TextStyle(color: gold, fontSize: 11, letterSpacing: 2.5),
          ),
          SizedBox(height: 35),
          Text(
            'La estrategia detr\u00e1s de la elegancia.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.25,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Dise\u00f1o de autor accesible. '
            'Vida presentada con clase.',
            style: TextStyle(
              color: Color(0xFFD0DBCE),
              fontSize: 16,
              height: 1.7,
            ),
          ),
          SizedBox(height: 30),
          Divider(color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'VERSI\u00d3N ESTRAT\u00c9GICA 1.0',
            style: TextStyle(
              color: Color(0xFFBAC8B8),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String number, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDFE4D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: gold,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              color: forest,
              fontSize: 27,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: const TextStyle(color: ink, height: 1.9, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _books() {
    const books = [
      ('La vaca p\u00farpura', 'Diferenciaci\u00f3n'),
      ('El m\u00e9todo Lean Startup', 'Validaci\u00f3n'),
      ('De cero a uno', 'Ventaja competitiva'),
      ('Building a StoryBrand', 'Comunicaci\u00f3n'),
      ('Profit First', 'Rentabilidad'),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '08 / FUNDAMENTOS',
            style: TextStyle(color: forest, letterSpacing: 2, fontSize: 11),
          ),
          const SizedBox(height: 15),
          const Text(
            'Nuestra biblioteca estrat\u00e9gica',
            style: TextStyle(
              color: forest,
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          for (final book in books)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: forest, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book.$1,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    book.$2,
                    style: const TextStyle(color: forest, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Referentes empresariales: Marcus Dantus, '
            'Arturo El\u00edas Ayub y Rodrigo Herrera.',
            style: TextStyle(color: ink, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _next() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '09 / SIGUIENTE FASE',
            style: TextStyle(color: forest, fontSize: 11, letterSpacing: 2),
          ),
          SizedBox(height: 12),
          Text(
            'Del concepto al producto',
            style: TextStyle(color: forest, fontSize: 25),
          ),
          SizedBox(height: 15),
          Text(
            'La selecci\u00f3n inicial de modelos '
            'y la fijaci\u00f3n de precios se realizar\u00e1n '
            'en la etapa final, mediante referencias '
            'visuales y evaluaci\u00f3n econ\u00f3mica.\n\n'
            'La demanda, la disposici\u00f3n de pago '
            'y la rentabilidad comercial '
            'se validar\u00e1n mediante ventas reales.',
            style: TextStyle(color: ink, height: 1.8),
          ),
        ],
      ),
    );
  }
}
