import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CollectionReference _articlesRef = FirebaseFirestore.instance.collection('articles');

  void _showAddEditDialog({ArticleModel? article}) {
    final nameController = TextEditingController(text: article?.name ?? '');
    final brandController = TextEditingController(text: article?.brand ?? '');
    final classificationController = TextEditingController(text: article?.classification ?? '');
    final priceController = TextEditingController(text: article != null ? article.price.toString() : '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article == null ? 'Nuevo Artículo' : 'Editar Artículo'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del artículo'),
                  validator: (val) => val == null || val.isEmpty ? 'Ingrese el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Marca (ej. Scribe, Norma, Dixon)'),
                  validator: (val) => val == null || val.isEmpty ? 'Ingrese la marca' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: classificationController,
                  decoration: const InputDecoration(labelText: 'Clasificación (ej. Archivo o empaque, Escritura)'),
                  validator: (val) => val == null || val.isEmpty ? 'Ingrese la clasificación' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio (\$)'),
                  validator: (val) => double.tryParse(val ?? '') == null ? 'Ingrese un precio válido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = nameController.text.trim();
              final brand = brandController.text.trim();
              final classification = classificationController.text.trim();
              final price = double.parse(priceController.text);

              if (article == null) {
                await _articlesRef.add({
                  'name': name,
                  'brand': brand,
                  'classification': classification,
                  'price': price,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await _articlesRef.doc(article.id).update({
                  'name': name,
                  'brand': brand,
                  'classification': classification,
                  'price': price,
                });
              }

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArticle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Artículo'),
        content: const Text('¿Está seguro de eliminar este artículo del catálogo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _articlesRef.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Artículos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _articlesRef.orderBy('classification').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay artículos en el catálogo.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primer Artículo'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final article = ArticleModel.fromMap(docs[index].id, data);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(article.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Clasif: ${article.classification} | Marca: ${article.brand} | Precio: \$${article.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(article: article),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteArticle(article.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Agregar Artículo',
      ),
    );
  }
}
