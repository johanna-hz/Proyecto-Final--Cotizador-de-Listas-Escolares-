import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';
import '../models/quote_model.dart';
import 'package:intl/intl.dart';

class QuoteFormScreen extends StatefulWidget {
  final QuoteModel? existingQuote; // Para edición o duplicado
  final bool isDuplicating;

  const QuoteFormScreen({super.key, this.existingQuote, this.isDuplicating = false});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _studentOrGradeController = TextEditingController();
  final _discountController = TextEditingController(text: '0.0');
  final _advanceController = TextEditingController(text: '0.0');

  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 3));
  List<QuoteItem> _quoteItems = [];
  String _status = 'Cotización';

  List<ArticleModel> _catalogArticles = [];
  bool _isLoadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();

    if (widget.existingQuote != null) {
      final q = widget.existingQuote!;
      if (!widget.isDuplicating) {
        _clientNameController.text = q.clientName;
        _clientPhoneController.text = q.clientPhone;
        _studentOrGradeController.text = q.studentOrGrade;
        _status = q.status;
        _discountController.text = q.discount.toString();
        _advanceController.text = q.advancePayment.toString();
      } else {
        _clientNameController.text = '${q.clientName} (Copia)';
        _clientPhoneController.text = q.clientPhone;
        _studentOrGradeController.text = q.studentOrGrade;
        _status = 'Cotización';
        _advanceController.text = '0.0';
      }
      _deliveryDate = q.deliveryDate;
      _quoteItems = q.items.map((i) => QuoteItem(
            articleId: i.articleId,
            name: i.name,
            brand: i.brand,
            unitPrice: i.unitPrice,
            quantity: i.quantity,
            isSorted: widget.isDuplicating ? false : i.isSorted,
          )).toList();
    }
  }

  Future<void> _loadCatalog() async {
    final snapshot = await FirebaseFirestore.instance.collection('articles').get();
    setState(() {
      _catalogArticles = snapshot.docs.map((d) => ArticleModel.fromMap(d.id, d.data())).toList();
      _isLoadingCatalog = false;
    });
  }

  double get _subtotal {
    return _quoteItems.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  void _applyDefaultDiscount() {
    // 10% de descuento automático
    double defaultDisc = _subtotal * 0.10;
    _discountController.text = defaultDisc.toStringAsFixed(2);
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _total {
    double t = _subtotal - _discount;
    return t < 0 ? 0.0 : t;
  }

  double get _advance {
    return double.tryParse(_advanceController.text) ?? 0.0;
  }

  double get _remaining {
    double r = _total - _advance;
    return r < 0 ? 0.0 : r;
  }

  void _addArticleDialog() {
    ArticleModel? selectedArticle;
    final qtyController = TextEditingController(text: '1');
    final searchController = TextEditingController();
    String selectedClassification = 'Todas';

    final customNameController = TextEditingController();
    final customBrandController = TextEditingController();
    final customPriceController = TextEditingController();
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          List<String> classifications = ['Todas', ..._catalogArticles.map((a) => a.classification).toSet()];

          List<ArticleModel> filteredArticles = _catalogArticles.where((art) {
            bool matchesClass = selectedClassification == 'Todas' || art.classification == selectedClassification;
            String query = searchController.text.toLowerCase();
            bool matchesQuery = art.name.toLowerCase().contains(query) || art.brand.toLowerCase().contains(query);
            return matchesClass && matchesQuery;
          }).toList();

          return AlertDialog(
            title: const Text('Agregar Artículo'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      title: const Text('Artículo Especial / Manual'),
                      value: isCustom,
                      onChanged: (val) => setDialogState(() => isCustom = val),
                    ),
                    const SizedBox(height: 8),
                    if (!isCustom) ...[
                      DropdownButtonFormField<String>(
                        value: selectedClassification,
                        decoration: const InputDecoration(labelText: 'Filtrar por Clasificación (Tipo)', border: OutlineInputBorder(), isDense: true),
                        items: classifications.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setDialogState(() => selectedClassification = val ?? 'Todas'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Escribir para buscar artículo o marca...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: filteredArticles.isEmpty
                            ? const Center(child: Text('No se encontraron artículos', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: filteredArticles.length,
                                itemBuilder: (context, index) {
                                  final art = filteredArticles[index];
                                  final isSelected = selectedArticle?.id == art.id;
                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                                    title: Text(art.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text('Marca: ${art.brand} | Clasif: ${art.classification}', style: const TextStyle(fontSize: 12)),
                                    trailing: Text('\$${art.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    onTap: () => setDialogState(() => selectedArticle = art),
                                  );
                                },
                              ),
                      ),
                      if (selectedArticle != null) ...[
                        const SizedBox(height: 8),
                        Text('Seleccionado: ${selectedArticle!.name} (${selectedArticle!.brand}) - \$${selectedArticle!.price}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ] else ...[
                      TextField(
                        controller: customNameController,
                        decoration: const InputDecoration(labelText: 'Nombre del artículo', border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customBrandController,
                        decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio Unitario (\$)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  int qty = int.tryParse(qtyController.text) ?? 1;
                  if (qty <= 0) qty = 1;

                  if (!isCustom) {
                    if (selectedArticle == null) return;
                    setState(() {
                      _quoteItems.add(QuoteItem(
                        articleId: selectedArticle!.id,
                        name: selectedArticle!.name,
                        brand: selectedArticle!.brand,
                        unitPrice: selectedArticle!.price,
                        quantity: qty,
                      ));
                      _applyDefaultDiscount();
                    });
                  } else {
                    String name = customNameController.text.trim();
                    String brand = customBrandController.text.trim();
                    double price = double.tryParse(customPriceController.text) ?? 0.0;
                    if (name.isEmpty) return;
                    setState(() {
                      _quoteItems.add(QuoteItem(
                        articleId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        brand: brand.isEmpty ? 'Especial' : brand,
                        unitPrice: price,
                        quantity: qty,
                      ));
                      _applyDefaultDiscount();
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Agregar a Lista'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quoteItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un artículo a la lista.')),
      );
      return;
    }

    final quoteData = QuoteModel(
      id: widget.existingQuote != null && !widget.isDuplicating ? widget.existingQuote!.id : '',
      clientName: _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      studentOrGrade: _studentOrGradeController.text.trim(),
      deliveryDate: _deliveryDate,
      items: _quoteItems,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      advancePayment: _advance,
      remainingBalance: _remaining,
      status: _status,
      createdAt: widget.existingQuote != null && !widget.isDuplicating ? widget.existingQuote!.createdAt : DateTime.now(),
    );

    final collection = FirebaseFirestore.instance.collection('quotes');

    if (widget.existingQuote != null && !widget.isDuplicating) {
      await collection.doc(widget.existingQuote!.id).update(quoteData.toJson());
    } else {
      await collection.add(quoteData.toJson());
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuote == null
            ? 'Nueva Cotización / Lista'
            : widget.isDuplicating
                ? 'Duplicar Cotización'
                : 'Editar Cotización'),
      ),
      body: _isLoadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Datos del Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Cliente *', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Ingrese el nombre del cliente' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clientPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _studentOrGradeController,
                          decoration: const InputDecoration(labelText: 'Alumno o Grado Escolar *', border: OutlineInputBorder()),
                          validator: (val) => val == null || val.isEmpty ? 'Ingrese alumno o grado' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Fecha estimada de entrega', border: OutlineInputBorder()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateFormat.format(_deliveryDate)),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _deliveryDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setState(() => _deliveryDate = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Estado Operativo', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Cotización', child: Text('Cotización')),
                            DropdownMenuItem(value: 'Por surtir', child: Text('Por surtir')),
                            DropdownMenuItem(value: 'Surtida / Lista', child: Text('Surtida / Lista')),
                            DropdownMenuItem(value: 'Entregada', child: Text('Entregada')),
                          ],
                          onChanged: (val) => setState(() => _status = val ?? 'Cotización'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Artículos de la Lista (${_quoteItems.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      FilledButton.icon(
                        onPressed: _addArticleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Artículo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _quoteItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('No hay artículos agregados.', style: TextStyle(color: Colors.grey))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _quoteItems.length,
                          itemBuilder: (context, index) {
                            final item = _quoteItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Marca: ${item.brand} | Cant: ${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currencyFormat.format(item.unitPrice * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => setState(() {
                                        _quoteItems.removeAt(index);
                                        _applyDefaultDiscount();
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const Divider(height: 32),
                  // Totals and Payments
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(currencyFormat.format(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Descuento 10% (MXN):'),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL NETO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(currencyFormat.format(_total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Text('Anticipo / Abono (MXN):'),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _advanceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SALDO PENDIENTE:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(currencyFormat.format(_remaining), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _remaining > 0 ? Colors.red : Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saveQuote,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cotización / Lista', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
