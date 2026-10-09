// FixMate — Shop tab, product card, and the post-product dialog
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'cart.dart';
import 'product_detail.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String query = '';
  String? categoryFilter;
  bool onlyAvailable = false;
  double minimumRating = 0;
  RangeValues? priceRange;

  List<Product> filterProducts(AppState state) {
    final words = query.split(' ').where((w) => w.isNotEmpty).toList();
    return state.catalogProducts.where((product) {
      final haystack = normalizeSearch(
        [
          product.name,
          state.tr(product.name),
          product.category,
          state.tr(product.category),
          product.supplierName,
          product.description,
        ].join(' '),
      );
      final textMatches = words.every((word) => haystack.contains(word));
      final categoryMatches =
          categoryFilter == null || product.category == categoryFilter;
      final stockMatches = !onlyAvailable || product.stockQuantity > 0;
      final ratingMatches = product.supplierRating >= minimumRating;
      final selectedRange = priceRange;
      final priceMatches =
          selectedRange == null ||
          (product.price >= selectedRange.start &&
              product.price <= selectedRange.end);
      return textMatches &&
          categoryMatches &&
          stockMatches &&
          ratingMatches &&
          priceMatches;
    }).toList();
  }

  Future<void> openFilters(List<Product> products) async {
    final state = context.read<AppState>();
    final t = state.tr;
    final prices = products.map((product) => product.price).toList();
    final minimum = prices.isEmpty
        ? 0.0
        : prices.reduce((a, b) => a < b ? a : b);
    final maximum = prices.isEmpty
        ? 100000.0
        : prices.reduce((a, b) => a > b ? a : b);
    var draftCategory = categoryFilter;
    var draftAvailable = onlyAvailable;
    var draftRating = minimumRating;
    var draftRange =
        priceRange ??
        RangeValues(minimum, maximum == minimum ? minimum + 1 : maximum);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('Filter products'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    initialValue: draftCategory,
                    decoration: InputDecoration(labelText: t('Category')),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(t('All categories')),
                      ),
                      ...productCategories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category,
                          child: Text(t(category)),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => draftCategory = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('In stock only')),
                    value: draftAvailable,
                    onChanged: (value) =>
                        setSheetState(() => draftAvailable = value),
                  ),
                  DropdownButtonFormField<double>(
                    initialValue: draftRating,
                    decoration: InputDecoration(
                      labelText: t('Minimum supplier rating'),
                    ),
                    items: [0.0, 3.0, 4.0, 4.5]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value == 0
                                  ? t('Any rating')
                                  : '${value.toStringAsFixed(1)}+',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => draftRating = value ?? 0),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${t('Price range')}: ${draftRange.start.round()} – ${draftRange.end.round()} FCFA',
                  ),
                  RangeSlider(
                    min: minimum,
                    max: maximum == minimum ? minimum + 1 : maximum,
                    values: draftRange,
                    onChanged: (value) =>
                        setSheetState(() => draftRange = value),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            categoryFilter = null;
                            onlyAvailable = false;
                            minimumRating = 0;
                            priceRange = null;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: Text(t('Clear filters')),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            categoryFilter = draftCategory;
                            onlyAvailable = draftAvailable;
                            minimumRating = draftRating;
                            priceRange =
                                draftRange.start <= minimum &&
                                    draftRange.end >= maximum
                                ? null
                                : draftRange;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: Text(t('Apply')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    final activeFilters =
        (categoryFilter != null ? 1 : 0) +
        (onlyAvailable ? 1 : 0) +
        (minimumRating > 0 ? 1 : 0) +
        (priceRange != null ? 1 : 0);

    return Scaffold(
      appBar: FixMateAppBar(title: t('Shop')),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                          backgroundColor: FixMateTheme.buttonGold,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: t('Search products'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => openFilters(state.catalogProducts),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    activeFilters == 0
                        ? t('Filters')
                        : '${t('Filters')} ($activeFilters)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.userRole == 'Supplier')
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: state.hasActiveBusinessSubscription
                      ? () => showDialog(
                          context: context,
                          builder: (_) => const AddProductDialog(),
                        )
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(
                    state.hasActiveBusinessSubscription
                        ? t('POST PRODUCT')
                        : 'Active subscription required to post products',
                  ),
                ),
              ),
            if (state.showingDemoProducts)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t(
                      'Showing demo products. Real products appear once suppliers post them.',
                    ),
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
              ...visible.map((product) => ProductCard(product: product)),
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? t('Product deleted.') : t('Could not delete the product.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final myId = supabase.auth.currentUser?.id;
    final isMine = product.supplierId != null && product.supplierId == myId;

    Widget trailing;
    if (isMine) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: t('Edit product'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddProductDialog(product: product),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: t('Remove'),
            onPressed: () => confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
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

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: product.imageUrl == null
                      ? ColoredBox(
                          color: FixMateTheme.gold.withValues(alpha: .12),
                          child: Icon(
                            product.icon,
                            color: FixMateTheme.gold,
                            size: 35,
                          ),
                        )
                      : Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: FixMateTheme.gold.withValues(alpha: .12),
                                child: Icon(
                                  product.icon,
                                  color: FixMateTheme.gold,
                                  size: 35,
                                ),
                              ),
                        ),
                ),
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
                    if (product.supplierRatingCount > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: FixMateTheme.gold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.supplierRating.toStringAsFixed(1)} (${product.supplierRatingCount})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
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
                        product.isListed
                            ? t('Your product')
                            : '${t('Your product')} · ${t('Listing hidden')}',
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
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final Product? product;

  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController(text: '1');
  final descriptionController = TextEditingController();
  final List<XFile> selectedImages = [];
  final Set<String> removedImageUrls = {};
  String? category;
  bool isListed = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(0);
      stockController.text = product.stockQuantity.toString();
      descriptionController.text = product.description;
      category = product.category.isEmpty ? null : product.category;
      isListed = product.isListed;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final name = nameController.text.trim();
    final price = double.tryParse(
      priceController.text.trim().replaceAll(',', '.'),
    );
    final stockQuantity = int.tryParse(stockController.text.trim());

    if (name.isEmpty ||
        price == null ||
        price <= 0 ||
        stockQuantity == null ||
        stockQuantity < 0) {
      setState(
        () => error = t(
          'Enter a product name, a valid price, and a stock quantity of zero or more.',
        ),
      );
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

    var ok = true;
    try {
      final existing = widget.product;
      if (existing == null) {
        ok = await state.publishProduct(
          name: name,
          price: price,
          category: category!,
          description: descriptionController.text.trim(),
          stockQuantity: stockQuantity,
          images: selectedImages,
        );
      } else {
        await state.updateSupplierProduct(
          product: existing,
          name: name,
          price: price,
          category: category!,
          description: descriptionController.text.trim(),
          stockQuantity: stockQuantity,
          isListed: isListed,
          newImages: selectedImages,
          removedImageUrls: removedImageUrls.toList(),
        );
      }
    } catch (e) {
      ok = false;
      debugPrint('Save product listing failed: $e');
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t(widget.product == null ? 'Product posted.' : 'Product updated.'),
          ),
        ),
      );
    } else {
      setState(() {
        saving = false;
        error = t('Could not post the product. Please try again.');
      });
    }
  }

  Future<void> chooseImages() async {
    final t = context.read<AppState>().tr;
    try {
      final existingCount =
          (widget.product?.imageUrls.length ?? 0) - removedImageUrls.length;
      final remainingSlots = 5 - existingCount - selectedImages.length;
      if (remainingSlots <= 0) {
        setState(
          () => error = t('A product can have no more than five photos.'),
        );
        return;
      }
      final images = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        limit: remainingSlots,
      );
      if (images.isEmpty || !mounted) return;
      for (final image in images) {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
          setState(() => error = t('Choose images smaller than 5 MB each.'));
          return;
        }
      }
      if (selectedImages.length + images.length > remainingSlots) {
        setState(
          () => error = t('A product can have no more than five photos.'),
        );
        return;
      }
      setState(() {
        selectedImages.addAll(images);
        error = null;
      });
    } catch (e) {
      debugPrint('Product image selection failed: $e');
      if (mounted) {
        setState(
          () => error = t('Could not select that image. Please try again.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return AlertDialog(
      title: Text(t(widget.product == null ? 'Post product' : 'Edit product')),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: t('Price (FCFA)')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('Stock quantity')),
            ),
            const SizedBox(height: 12),
            if (widget.product?.imageUrls.isNotEmpty == true)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.product!.imageUrls.map((url) {
                  final removed = removedImageUrls.contains(url);
                  return Stack(
                    children: [
                      Opacity(
                        opacity: removed ? 0.3 : 1,
                        child: Image.network(
                          url,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          onPressed: saving
                              ? null
                              : () => setState(() {
                                  if (removed) {
                                    removedImageUrls.remove(url);
                                  } else {
                                    removedImageUrls.add(url);
                                  }
                                }),
                          icon: Icon(
                            removed ? Icons.undo : Icons.close,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            if (selectedImages.isNotEmpty)
              ...selectedImages.asMap().entries.map(
                (entry) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.image_outlined),
                  title: Text(entry.value.name),
                  trailing: IconButton(
                    onPressed: saving
                        ? null
                        : () => setState(
                            () => selectedImages.removeAt(entry.key),
                          ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: saving ? null : chooseImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                t(
                  selectedImages.isEmpty &&
                          (widget.product?.imageUrls.isEmpty ?? true)
                      ? 'Add product photo'
                      : 'Add more product photos',
                ),
              ),
            ),
            if (widget.product != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isListed,
                title: Text(t('Listing visible in shop')),
                onChanged: saving
                    ? null
                    : (value) => setState(() => isListed = value),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: category,
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
              : Text(t(widget.product == null ? 'POST' : 'Save changes')),
        ),
      ],
    );
  }
}
