import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/inventory.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  Future<void> _adjustStock(Product product, int delta) async {
    try {
      await ref.read(inventoryRepositoryProvider).addStockMovement(
            productId: product.id,
            movementType: delta > 0 ? 'IN' : 'OUT',
            quantity: delta.abs(),
            reason: delta > 0 ? 'Restock' : 'Manual adjustment',
          );
      ref.invalidate(productsListProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Failed to update stock';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showAddProductDialog(List<ProductCategory> categories) async {
    if (categories.isEmpty) {
      final created = await _showAddCategoryDialog();
      if (created == null) return;
      categories = [created];
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    String selectedCategoryId = categories.first.id;
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add Product', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => selectedCategoryId = val ?? selectedCategoryId,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Product name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Price (₹)'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Starting stock quantity'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ref.read(inventoryRepositoryProvider).createProduct(
                              categoryId: selectedCategoryId,
                              name: nameController.text.trim(),
                              price: double.parse(priceController.text),
                              stockQty: int.tryParse(stockController.text) ?? 0,
                            );
                        ref.invalidate(productsListProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (context.mounted) {
                          final message = e is ApiException ? e.message : 'Failed to add product';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ProductCategory?> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    return showDialog<ProductCategory>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Create a product category first', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'e.g. Hair Care, Styling Tools'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                final category = await ref.read(inventoryRepositoryProvider).createCategory(controller.text.trim());
                ref.invalidate(productCategoriesProvider);
                if (context.mounted) Navigator.pop(context, category);
              } catch (e) {
                if (context.mounted) {
                  final message = e is ApiException ? e.message : 'Failed to create category';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(categoriesAsync.value ?? []),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (error, _) => Center(
          child: Text('Could not load inventory: $error', style: const TextStyle(color: Colors.blueGrey)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No products yet. Tap + to add your first one.', style: TextStyle(color: Colors.blueGrey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(productsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildProductCard(products[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final lowStock = product.stockQty <= 5;
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  if (product.categoryName != null)
                    Text(product.categoryName!, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stockQty} in stock',
                  style: TextStyle(color: lowStock ? Colors.amber : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                      onPressed: product.stockQty > 0 ? () => _adjustStock(product, -1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                      onPressed: () => _adjustStock(product, 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
