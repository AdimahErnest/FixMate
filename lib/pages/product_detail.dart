import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int imageIndex = 0;

  Future<void> reportProduct() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Report this product')),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(labelText: t('Tell us what is wrong')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(t('Submit report')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().length < 3 || !mounted) return;
    try {
      await state.reportProduct(widget.product.id!, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('Thank you. The product was reported.'))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final product = widget.product;
    final t = state.tr;
    final images = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : product.imageUrl == null
        ? <String>[]
        : [product.imageUrl!];
    final isMine = product.supplierId == supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(product.name)),
        actions: [
          if (state.userRole == 'Customer' && !isMine)
            IconButton(
              tooltip: t('Report this product'),
              onPressed: product.id == null ? null : reportProduct,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 320,
            child: images.isEmpty
                ? ColoredBox(
                    color: FixMateTheme.gold.withValues(alpha: .12),
                    child: Icon(product.icon, size: 90, color: FixMateTheme.gold),
                  )
                : PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) => setState(() => imageIndex = index),
                    itemBuilder: (context, index) => Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: FixMateTheme.gold.withValues(alpha: .12),
                        child: Icon(
                          product.icon,
                          size: 90,
                          color: FixMateTheme.gold,
                        ),
                      ),
                    ),
                  ),
          ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: index == imageIndex ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == imageIndex
                          ? FixMateTheme.gold
                          : FixMateTheme.gold.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(product.name),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: FixMateTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.category.isNotEmpty)
                      Chip(label: Text(t(product.category))),
                    Chip(
                      avatar: Icon(
                        product.stockQuantity > 0
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        product.stockQuantity > 0
                            ? '${t('In stock')}: ${product.stockQuantity}'
                            : t('Out of stock'),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  t('Description'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description.isEmpty
                      ? t('No description provided.')
                      : product.description,
                ),
                const Divider(height: 28),
                Text(
                  t('Supplier'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: FixMateTheme.gold),
                    const SizedBox(width: 8),
                    Expanded(child: Text(product.supplierName)),
                    if (product.supplierRatingCount > 0)
                      Text(
                        '${product.supplierRating.toStringAsFixed(1)} ★ (${product.supplierRatingCount})',
                      ),
                  ],
                ),
                if (!isMine && product.stockQuantity > 0) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        state.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('Added to cart.')),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(t('ADD TO CART')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
