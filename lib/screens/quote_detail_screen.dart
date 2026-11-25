import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/pdf_service.dart';
import 'quote_form_screen.dart';
import 'package:intl/intl.dart';

class QuoteDetailScreen extends StatefulWidget {
  final QuoteModel quote;

  const QuoteDetailScreen({super.key, required this.quote});

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late QuoteModel _quote;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
  }

  Future<void> _refreshQuote() async {
    final doc = await FirebaseFirestore.instance.collection('quotes').doc(_quote.id).get();
    if (doc.exists) {
      setState(() {
        _quote = QuoteModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      });
    }
  }

  Future<void> _toggleItemSorted(int index, bool? value) async {
    setState(() {
      _quote.items[index].isSorted = value ?? false;
    });

    await FirebaseFirestore.instance.collection('quotes').doc(_quote.id).update({
      'items': _quote.items.map((i) => i.toJson()).toList(),
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('quotes').doc(_quote.id).update({
      'status': newStatus,
    });
    await _refreshQuote();
  }

  Future<void> _addAbonoDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Abono / Anticipo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto del abono (\$)'),
            validator: (val) {
              double? amount = double.tryParse(val ?? '');
              if (amount == null || amount <= 0) return 'Ingrese un monto válido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              double addedAmount = double.parse(controller.text);
              double newAdvance = _quote.advancePayment + addedAmount;
              double newRemaining = _quote.total - newAdvance;
              if (newRemaining < 0) newRemaining = 0;

              await FirebaseFirestore.instance.collection('quotes').doc(_quote.id).update({
                'advancePayment': newAdvance,
                'remainingBalance': newRemaining,
              });

              Navigator.pop(context);
              await _refreshQuote();
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Cotización':
        return Colors.blue;
      case 'Por surtir':
        return Colors.orange;
      case 'Surtida / Lista':
        return Colors.purple;
      case 'Entregada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getPaymentBadge() {
    String label;
    Color color;
    if (_quote.advancePayment <= 0) {
      label = 'Sin abono';
      color = Colors.red;
    } else if (_quote.remainingBalance > 0) {
      label = 'Con abono';
      color = Colors.orange;
    } else {
      label = 'Liquidado';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Lista: ${_quote.clientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuoteFormScreen(existingQuote: _quote)),
              );
              await _refreshQuote();
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Duplicar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuoteFormScreen(existingQuote: _quote, isDuplicating: true)),
              );
              await _refreshQuote();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Generar / Compartir PDF',
            onPressed: () => PdfService.printOrSharePdf(_quote),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_quote.clientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      _getPaymentBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Teléfono: ${_quote.clientPhone.isEmpty ? "N/D" : _quote.clientPhone}'),
                  Text('Alumno / Grado: ${_quote.studentOrGrade}'),
                  Text('Fecha de entrega: ${dateFormat.format(_quote.deliveryDate)}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(_quote.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: _getStatusColor(_quote.status),
                      ),
                      PopupMenuButton<String>(
                        onSelected: _updateStatus,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'Cotización', child: Text('Estado: Cotización')),
                          PopupMenuItem(value: 'Por surtir', child: Text('Estado: Por surtir')),
                          PopupMenuItem(value: 'Surtida / Lista', child: Text('Estado: Surtida / Lista')),
                          PopupMenuItem(value: 'Entregada', child: Text('Estado: Entregada')),
                        ],
                        child: const Chip(
                          label: Text('Cambiar Estado ▾'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Surtido Checklist Section (Módulo 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Checklist de Surtido Operativo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${_quote.items.where((i) => i.isSorted).length} / ${_quote.items.length} surtidos',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quote.items.length,
            itemBuilder: (context, index) {
              final item = _quote.items[index];
              return CheckboxListTile(
                title: Text(item.name, style: TextStyle(decoration: item.isSorted ? TextDecoration.lineThrough : null)),
                subtitle: Text('Marca: ${item.brand} | Cant: ${item.quantity} | Subtotal: ${currencyFormat.format(item.unitPrice * item.quantity)}'),
                value: item.isSorted,
                onChanged: (val) => _toggleItemSorted(index, val),
              );
            },
          ),
          const SizedBox(height: 16),

          // Balances and Payments Section (Módulo 2)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Subtotal:'), Text(currencyFormat.format(_quote.subtotal))],
                  ),
                  if (_quote.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Descuento (10%):'), Text('- ${currencyFormat.format(_quote.discount)}', style: const TextStyle(color: Colors.red))],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Total Neto:', style: TextStyle(fontWeight: FontWeight.bold)), Text(currencyFormat.format(_quote.total), style: const TextStyle(fontWeight: FontWeight.bold))],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Abono / Anticipo:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Text(currencyFormat.format(_quote.advancePayment), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo Pendiente:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currencyFormat.format(_remainingBalance), style: TextStyle(color: _quote.remainingBalance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _addAbonoDialog,
                    icon: const Icon(Icons.add_card),
                    label: const Text('Registrar Abono / Anticipo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => PdfService.printOrSharePdf(_quote),
            icon: const Icon(Icons.share),
            label: const Text('Enviar Comprobante por WhatsApp / PDF', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  double get _remainingBalance => _quote.remainingBalance;
}
