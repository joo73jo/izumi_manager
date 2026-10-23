import 'roadmap_page.dart';
import 'visual_identity_page.dart';
import 'corporate_identity_page.dart';
import 'business_plan_page.dart';
import 'essence_page.dart';

import 'package:flutter/material.dart';

import 'collections_page.dart';

class IzumiStudioPage extends StatefulWidget {
  const IzumiStudioPage({super.key});

  @override
  State<IzumiStudioPage> createState() => _IzumiStudioPageState();
}

class _IzumiStudioPageState extends State<IzumiStudioPage> {
  static const green = Color(0xFF284426);

  bool showCollections = false;
  bool showEssence = false;
  bool showRoadmap = false;
  bool showVisualIdentity = false;
  bool showCorporateIdentity = false;
  bool showBusinessPlan = false;

  static const sections = [
    (
      'Esencia de Izumi',
      'Filosofía, misión, visión y valores',
      Icons.auto_awesome_outlined,
    ),
    (
      'Plan de negocio',
      'Estrategia y dirección empresarial',
      Icons.business_center_outlined,
    ),
    (
      'Identidad visual',
      'Colores, tipografías y logotipos',
      Icons.palette_outlined,
    ),
    (
      'Identidad corporativa',
      'Correos, redes y datos empresariales',
      Icons.contact_mail_outlined,
    ),
    ('Colecciones', 'Conceptos y líneas de diseño', Icons.layers_outlined),
    ('Hoja de ruta', 'Objetivos y crecimiento', Icons.route_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    if (showBusinessPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => showBusinessPlan = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 15),
          const Expanded(child: BusinessPlanPage()),
        ],
      );
    }

    if (showCorporateIdentity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => showCorporateIdentity = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 12),
          const Expanded(child: CorporateIdentityPage()),
        ],
      );
    }

    if (showVisualIdentity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => showVisualIdentity = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 12),
          const Expanded(child: VisualIdentityPage()),
        ],
      );
    }

    if (showRoadmap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => showRoadmap = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 12),
          const Expanded(child: RoadmapPage()),
        ],
      );
    }

    if (showEssence) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => showEssence = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 15),
          const Expanded(child: EssencePage()),
        ],
      );
    }

    if (showCollections) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() => showCollections = false);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Izumi Studio'),
          ),
          const SizedBox(height: 15),
          const Expanded(child: CollectionsPage()),
        ],
      );
    }

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IZUMI STUDIO',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Construyendo nuestra identidad.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 27,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'El espacio estratégico y creativo de Izumi.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Áreas de desarrollo',
          style: TextStyle(
            fontSize: 22,
            color: green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 750 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 3 ? 1.45 : 1.3,
              ),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final item = sections[index];

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFDFE6DD)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (index == 0) {
                        setState(() => showEssence = true);
                      } else if (index == 1) {
                        setState(() => showBusinessPlan = true);
                      } else if (index == 3) {
                        setState(() => showCorporateIdentity = true);
                      } else if (index == 2) {
                        setState(() => showVisualIdentity = true);
                      } else if (index == 4) {
                        setState(() => showCollections = true);
                      } else if (index == 5) {
                        setState(() => showRoadmap = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.$1}: próximamente.')),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3, color: green, size: 30),
                          const Spacer(),
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
