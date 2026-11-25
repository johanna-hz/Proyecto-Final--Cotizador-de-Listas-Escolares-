import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/auth_service.dart';
import '../widgets/triates_logo.dart';
import 'quote_form_screen.dart';
import 'quote_detail_screen.dart';
import 'catalog_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String _filterStatus = 'Todos'; // 'Todos', 'Por surtir', 'Surtida / Lista', 'Entregada'
  String _searchQuery = '';

  Widget _getPaymentBadge(QuoteModel quote) {
    String label;
    Color color;
    if (quote.advancePayment <= 0) {
      label = 'Sin abono';
      color = Colors.red;
    } else if (quote.remainingBalance > 0) {
      label = 'Con abono';
      color = Colors.orange;
    } else {
      label = 'Liquidado';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const TriatesLogoWidget(size: 40),
            const SizedBox(width: 12),
            Text('Triates Papelería', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Catálogo de Artículos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CatalogScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips & Search
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente o alumno...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var status in ['Todos', 'Cotización', 'Por surtir', 'Surtida / Lista', 'Entregada'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: _filterStatus == status,
                            onSelected: (selected) {
                              if (selected) setState(() => _filterStatus = status);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quotes').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No hay cotizaciones registradas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuoteFormScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Primera Cotización'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final quote = QuoteModel.fromMap(doc.id, data);

                  bool matchesFilter = _filterStatus == 'Todos' || quote.status == _filterStatus;
                  bool matchesSearch = quote.clientName.toLowerCase().contains(_searchQuery) ||
                      quote.studentOrGrade.toLowerCase().contains(_searchQuery);

                  return matchesFilter && matchesSearch;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No se encontraron listas con los filtros seleccionados.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final quote = QuoteModel.fromMap(docs[index].id, data);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => QuoteDetailScreen(quote: quote)),
                          );
                        },
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(quote.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            _getPaymentBadge(quote),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Alumno/Grado: ${quote.studentOrGrade} | Entrega: ${dateFormat.format(quote.deliveryDate)}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total: ${currencyFormat.format(quote.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(quote.status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    quote.status,
                                    style: TextStyle(color: _getStatusColor(quote.status), fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuoteFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Cotización'),
      ),
    );
  }
}
