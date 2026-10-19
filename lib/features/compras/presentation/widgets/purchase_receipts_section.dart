import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/purchase_receipt_repository.dart';
import '../../data/purchase_receipt_storage.dart';

class PurchaseReceiptsSection extends StatefulWidget {
  const PurchaseReceiptsSection({
    super.key,
    required this.purchaseId,
    required this.repository,
  });

  final int purchaseId;
  final PurchaseReceiptRepository repository;

  @override
  State<PurchaseReceiptsSection> createState() =>
      _PurchaseReceiptsSectionState();
}

class _PurchaseReceiptsSectionState extends State<PurchaseReceiptsSection> {
  final storage = PurchaseReceiptStorage();

  late Future<List<PurchaseReceipt>> receipts;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    receipts = widget.repository.getByPurchase(widget.purchaseId);
    if (mounted) setState(() {});
  }

  void showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> attach() async {
    if (saving) return;

    setState(() => saving = true);

    String? copiedPath;

    try {
      copiedPath = await storage.selectAndCopy(widget.purchaseId);

      if (copiedPath == null) return;

      await widget.repository.attach(
        purchaseId: widget.purchaseId,
        filePath: copiedPath,
      );

      if (!mounted) return;

      refresh();
    } catch (error) {
      if (copiedPath != null) {
        final file = File(copiedPath);

        if (await file.exists()) {
          await file.delete();
        }
      }

      showError(error);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> openReceipt(String path) async {
    try {
      await storage.open(path);
    } catch (error) {
      showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PurchaseReceipt>>(
      future: receipts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final files = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Comprobantes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF284426),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: saving ? null : attach,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Adjuntar'),
                  ),
                ],
              ),
              for (final receipt in files)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(receipt.fileName),
                  trailing: IconButton(
                    tooltip: 'Abrir comprobante',
                    onPressed: () => openReceipt(receipt.filePath),
                    icon: const Icon(Icons.open_in_new),
                  ),
                ),
              if (files.isEmpty) const Text('Sin comprobantes adjuntos.'),
            ],
          ),
        );
      },
    );
  }
}
