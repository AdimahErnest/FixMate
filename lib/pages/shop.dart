// FixMate — Shop tab, product card, and the post-product dialog
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'cart.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
    String query = '';

  List<Product> filterProducts(AppState state) {
    final words = query.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return state.catalogProducts;
    return state.catalogProducts.where((product) {
      final haystack = normalizeSearch([
        product.name,
        state.tr(product.name),
        product.category,
        state.tr(product.category),
        product.supplierName,
        product.description,
      ].join(' '));
      return words.every((word) => haystack.contains(word));
    }).toList();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final firstLoad = !state.productsLoaded;
    final visible = filterProducts(state);

    return Scaffold(
          appBar: FixMateAppBar(
        title: t('Shop'),
        suggestions: const ['Search products'],
        onSearchChanged: (value) => setState(() => query = value),
      ),
      body: RefreshIndicator(
        onRefresh: state.loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('Products & Tools'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    if (state.cartCount > 0)
                      Positioned(
                        right: 5,
                        top: 3,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: FixMateTheme.gold,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${state.cartCount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (state.userRole == 'Supplier')
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AddProductDialog(),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(t('POST PRODUCT')),
                ),
              ),
            if (state.showingDemoProducts)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t('Showing demo products. Real products appear once suppliers post them.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (firstLoad)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
                      else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(child: Text(t('No products found.'))),
              )
            else
              ...visible.map(
                (product) => ProductCard(product: product),
              ),
          ],
        ),
      ),
    );
  }
}


class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  Future<void> confirmDelete(BuildContext context) async {
    final state = context.read<AppState>();
    final t = state.tr;
    final messenger = ScaffoldMessenger.of(context);
    final id = product.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(t('Delete this product?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('No')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('Yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await state.deleteProduct(id);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? t('Product deleted.') : t('Could not delete the product.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final myId = supabase.auth.currentUser?.id;
    final isMine = product.supplierId != null && product.supplierId == myId;

    Widget trailing;
    if (isMine) {
      trailing = IconButton(
        tooltip: t('Remove'),
        onPressed: () => confirmDelete(context),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
      );
    } else if (!product.inStock) {
      trailing = Text(
        t('Out of stock'),
        style: const TextStyle(color: Colors.red, fontSize: 12),
      );
    } else {
      trailing = IconButton(
        onPressed: () {
          state.addToCart(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t(product.name)} - ${t('ADD TO CART')}')),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        color: FixMateTheme.gold,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: FixMateTheme.gold.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(product.icon, color: FixMateTheme.gold, size: 35),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(product.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (product.category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      t(product.category),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(child: Text(product.supplierName)),
                      if (product.supplierCertified) ...[
                        const SizedBox(width: 4),
                        const CertifiedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(
                      color: FixMateTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(height: 4),
                    Text(
                      t('Your product'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  String? category;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim().replaceAll(',', '.'));

    if (name.isEmpty || price == null || price <= 0) {
      setState(() => error = t('Enter a product name and a valid price.'));
      return;
    }
    if (category == null) {
      setState(() => error = t('Please choose a category.'));
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    final ok = await state.publishProduct(
      name: name,
      price: price,
      category: category!,
      description: descriptionController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(t('Product posted.'))));
    } else {
      setState(() {
        saving = false;
        error = t('Could not post the product. Please try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return AlertDialog(
      title: Text(t('Post product')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: t('Product name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t('Price (FCFA)')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(labelText: t('Category')),
              items: productCategories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(t(c), overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => category = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t('Description (optional)'),
                alignLabelWithHint: true,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(t('Cancel')),
        ),
        FilledButton(
          onPressed: saving ? null : submit,
          child: saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t('POST')),
        ),
      ],
    );
  }
}
