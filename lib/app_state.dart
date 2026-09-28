// FixMate — app-wide state, data models, and demo data
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  String language = 'English';
  String userRole = '';
  bool loggedIn = false;
  String loginIdentifier = '';
  List<CartItem> cartItems = [];
  List<Product> products = List<Product>.from(shopProducts);
  List<String> activities = [];
  List<String> supplierNotifications = [];
  String profileName = 'FixMate User';
  String profileEmail = 'example@gmail.com';
  String profilePhone = '+237 6XX XXX XXX';
  String profileLocation = 'Douala';
  double profileRating = 4.8;
  Uint8List? profileImageBytes;
  String? profileImageUrl;

  bool get isFrench => language == 'Français';
  ImageProvider? get profileImage {
  if (profileImageBytes != null) return MemoryImage(profileImageBytes!);
  final url = profileImageUrl;
  if (url != null && url.isNotEmpty) return NetworkImage(url);
  return null;
}
  List<Product> get catalogProducts => products;


List<TechnicianData> technicianList = [];
bool techniciansLoading = false;
bool showingDemoTechnicians = false;

Future<void> loadTechnicians() async {
  techniciansLoading = true;
  notifyListeners();
  try {
    final rows = await supabase
        .from('technician_directory')
        .select()
        .order('rating', ascending: false);

    final loaded = <TechnicianData>[];
    for (final row in rows) {
      loaded.add(TechnicianData(
        id: row['id'] as String?,
        name: (row['name'] as String?) ?? 'Technician',
        services: List<String>.from(row['services'] ?? const []),
        region: (row['region'] as String?) ?? '',
        town: (row['town'] as String?) ?? '',
        rating: (row['rating'] as num?)?.toDouble() ?? 0,
        jobs: (row['jobs'] as num?)?.toInt() ?? 0,
        certified: (row['certified'] as bool?) ?? false,
        imagePath: '',
        imageUrl: row['image_url'] as String?,
      ));
    }

    showingDemoTechnicians = loaded.isEmpty;
    technicianList = loaded.isEmpty ? List<TechnicianData>.from(technicians) : loaded;
  } catch (e) {
    debugPrint('Load technicians error: $e');
    if (technicianList.isEmpty) {
      showingDemoTechnicians = true;
      technicianList = List<TechnicianData>.from(technicians);
    }
  }
  techniciansLoading = false;
  notifyListeners();
}

List<ServiceRequestData> serviceRequests = [];
bool requestsLoading = false;
bool requestsFailed = false;

Future<void> loadServiceRequests() async {
  requestsLoading = true;
  requestsFailed = false;
  notifyListeners();
  try {
    final rows = await supabase
        .from('service_request_details')
        .select()
        .order('created_at', ascending: false);
    serviceRequests = [for (final row in rows) ServiceRequestData.fromRow(row)];
  } catch (e) {
    debugPrint('Load requests error: $e');
    requestsFailed = true;
  }
  requestsLoading = false;
  notifyListeners();
}

Future<bool> updateRequestStatus(String id, String status) async {
  try {
    final rows = await supabase
        .from('service_requests')
        .update({'status': status})
        .eq('id', id)
        .select('id');
    // An empty result means the database refused the change
    if (rows.isEmpty) return false;

    final index = serviceRequests.indexWhere((r) => r.id == id);
    if (index >= 0) serviceRequests[index].status = status;
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Update request error: $e');
    return false;
  }
}

bool productsLoading = false;
bool productsLoaded = false;
bool showingDemoProducts = false;

Future<void> loadProducts() async {
  productsLoading = true;
  notifyListeners();
  try {
    final rows = await supabase
        .from('product_catalog')
        .select()
        .order('created_at', ascending: false);

    final loaded = <Product>[];
    for (final row in rows) {
      final category = (row['category'] as String?) ?? '';
      loaded.add(Product(
        id: row['id'] as String?,
        supplierId: row['supplier_id'] as String?,
        name: (row['name'] as String?) ?? '',
        price: double.tryParse('${row['price']}') ?? 0,
        supplierName: (row['supplier_name'] as String?) ?? 'Supplier',
        supplierCertified: (row['supplier_certified'] as bool?) ?? false,
        category: category,
        description: (row['description'] as String?) ?? '',
        inStock: (row['in_stock'] as bool?) ?? true,
        icon: iconForCategory(category),
      ));
    }

    showingDemoProducts = loaded.isEmpty;
    products = loaded.isEmpty ? List<Product>.from(shopProducts) : loaded;
  } catch (e) {
    debugPrint('Load products error: $e');
    if (products.isEmpty) products = List<Product>.from(shopProducts);
    showingDemoProducts = true;
  }
  productsLoading = false;
  productsLoaded = true;
  notifyListeners();
}

Future<bool> publishProduct({
  required String name,
  required double price,
  required String category,
  String description = '',
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    await supabase.from('products').insert({
      'supplier_id': user.id,
      'name': name,
      'price': price,
      'category': category.isEmpty ? null : category,
      'description': description.isEmpty ? null : description,
    });
    activities.add('Posted $name for sale');
    await loadProducts();
    return true;
  } catch (e) {
    debugPrint('Publish product error: $e');
    return false;
  }
}

Future<bool> deleteProduct(String id) async {
  try {
    final rows = await supabase.from('products').delete().eq('id', id).select('id');
    if (rows.isEmpty) return false; // the database refused
    await loadProducts();
    return true;
  } catch (e) {
    debugPrint('Delete product error: $e');
    return false;
  }
}

List<SupplierOrderItem> supplierOrders = [];
bool supplierOrdersLoading = false;
bool supplierOrdersFailed = false;

Future<void> loadSupplierOrders() async {
  supplierOrdersLoading = true;
  supplierOrdersFailed = false;
  notifyListeners();
  try {
    final rows = await supabase
        .from('supplier_order_items')
        .select()
        .order('created_at', ascending: false);
    supplierOrders = [for (final row in rows) SupplierOrderItem.fromRow(row)];
  } catch (e) {
    debugPrint('Load supplier orders error: $e');
    supplierOrdersFailed = true;
  }
  supplierOrdersLoading = false;
  notifyListeners();
}

Future<bool> updateOrderItemStatus(String id, String status) async {
  try {
    final rows = await supabase
        .from('order_items')
        .update({'fulfillment_status': status})
        .eq('id', id)
        .select('id');
    // An empty result means the database refused the change
    if (rows.isEmpty) return false;

    final index = supplierOrders.indexWhere((o) => o.id == id);
    if (index >= 0) supplierOrders[index].status = status;
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Update order item error: $e');
    return false;
  }
}

List<CustomerOrder> customerOrders = [];
bool customerOrdersLoading = false;
bool customerOrdersFailed = false;

Future<void> loadCustomerOrders() async {
  customerOrdersLoading = true;
  customerOrdersFailed = false;
  notifyListeners();
  try {
    final rows = await supabase
        .from('customer_order_items')
        .select()
        .order('order_created_at', ascending: false);

    final byOrder = <String, CustomerOrder>{};
    for (final row in rows) {
      final orderId = row['order_id'] as String;
      final order = byOrder.putIfAbsent(
        orderId,
        () => CustomerOrder(
          id: orderId,
          createdAt: DateTime.tryParse('${row['order_created_at']}')?.toLocal() ??
              DateTime.now(),
          total: double.tryParse('${row['total_amount']}') ?? 0,
          paymentStatus: (row['payment_status'] as String?) ?? 'unpaid',
          items: [],
        ),
      );
      order.items.add(CustomerOrderItem(
        id: row['id'] as String,
        productName: (row['product_name'] as String?) ?? '',
        quantity: (row['quantity'] as num?)?.toInt() ?? 1,
        price: double.tryParse('${row['price']}') ?? 0,
        status: (row['fulfillment_status'] as String?) ?? 'pending',
        supplierName: (row['supplier_name'] as String?) ?? '',
        supplierPhone: (row['supplier_phone'] as String?) ?? '',
      ));
    }
    customerOrders = byOrder.values.toList();
  } catch (e) {
    debugPrint('Load customer orders error: $e');
    customerOrdersFailed = true;
  }
  customerOrdersLoading = false;
  notifyListeners();
}

String authError = '';

String _friendlyAuthError(Object e) {
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox.';
    }
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('password') && (msg.contains('at least') || msg.contains('weak'))) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return 'Please enter a valid email address.';
    }
    return e.message;
  }
  final text = e.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('network')) {
    return 'No internet connection. Please check your network.';
  }
  return 'Something went wrong. Please try again.';
}

Future<void> _applyProfile(String userId, String email) async {
  final profile = await supabase.from('profiles').select().eq('id', userId).single();
  userRole = profile['role'] ?? 'Customer';
  profileName = profile['full_name'] ?? 'FixMate User';
  profileEmail = profile['email'] ?? email;
  profilePhone = profile['phone'] ?? '';
  profileLocation = profile['location'] ?? 'Douala';
  profileImageUrl = profile['profile_image_url'];
  loginIdentifier = email;
  loggedIn = true;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userRole', userRole);
  await prefs.setString('loginIdentifier', loginIdentifier);
}

Future<bool> signInSupabase(String email, String password) async {
  authError = '';
  try {
    final response = await supabase.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) {
      authError = 'Incorrect email or password.';
      return false;
    }
    await _applyProfile(user.id, email);
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Sign in error: $e');
    authError = _friendlyAuthError(e);
    return false;
  }
}

Future<bool> restoreSession() async {
  final prefs = await SharedPreferences.getInstance();
  final user = supabase.auth.currentUser;

  if (user == null) {
    userRole = '';
    loggedIn = false;
    loginIdentifier = '';
    await prefs.remove('userRole');
    await prefs.remove('loginIdentifier');
    notifyListeners();
    return false;
  }

  try {
    await _applyProfile(user.id, user.email ?? '');
  } catch (e) {
    // Probably offline: fall back to the last saved role
    debugPrint('Restore session error: $e');
    final cachedRole = prefs.getString('userRole') ?? '';
    if (cachedRole.isEmpty) return false;
    userRole = cachedRole;
    loginIdentifier = user.email ?? '';
    loggedIn = true;
  }
  notifyListeners();
  return loggedIn;
}

Future<bool> signUpSupabase({
  required String email,
  required String password,
  required String role,
  required String fullName,
  String? phone,
  List<String>? services,
}) async {
  authError = '';
  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'role': role, 'full_name': fullName},
    );
    final user = response.user;
    if (user == null) {
      authError = 'Signup failed. Please try again.';
      return false;
    }

    if (response.session == null) {
      authError = 'Account created! Please confirm your email, then log in.';
      return false;
    }

    await supabase
        .from('profiles')
        .update({'phone': phone, 'location': 'Douala'})
        .eq('id', user.id);
    if (role == 'Technician') {
      await supabase.from('technicians').insert({
        'id': user.id,
        'services': services ?? <String>[],
      });
    }
    if (role == 'Supplier') {
      await supabase.from('suppliers').insert({'id': user.id});
    }

    userRole = role;
    profileName = fullName;
    profileEmail = email;
    profilePhone = phone ?? '';
    profileLocation = 'Douala';
    loginIdentifier = email;
    loggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', userRole);
    await prefs.setString('loginIdentifier', loginIdentifier);

    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Sign up error: $e');
    authError = _friendlyAuthError(e);
    return false;
  }
}

Future<bool> sendPasswordResetCode(String email) async {
  authError = '';
  try {
    await supabase.auth.resetPasswordForEmail(email);
    return true;
  } catch (e) {
    debugPrint('Reset email error: $e');
    authError = _friendlyAuthError(e);
    return false;
  }
}

Future<bool> resetPasswordWithCode({
  required String email,
  required String code,
  required String newPassword,
}) async {
  authError = '';
  try {
    await supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  } catch (e) {
    debugPrint('Reset password error: $e');
    final text = e.toString().toLowerCase();
    if (e is AuthException &&
        (text.contains('expired') || text.contains('invalid') || text.contains('token'))) {
      authError = 'The code is invalid or has expired.';
    } else {
      authError = _friendlyAuthError(e);
    }
    return false;
  } finally {
    // verifyOTP signs the user in, so sign out and make them log in normally
    try {
      await supabase.auth.signOut();
    } catch (_) {}
  }
}
 Future<void> signOutSupabase() async {
  await supabase.auth.signOut();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole');
  await prefs.remove('loginIdentifier');
  userRole = '';
  loggedIn = false;
  loginIdentifier = '';
  cartItems.clear();
  profileName = 'FixMate User';
profileEmail = 'example@gmail.com';
profilePhone = '+237 6XX XXX XXX';
profileImageBytes = null;
profileImageUrl = null;
activities.clear();
serviceRequests = [];
supplierOrders = [];
customerOrders = [];
  notifyListeners();
}

  Future<void> uploadProfileImageSupabase(Uint8List bytes) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final path = '${user.id}/profile.jpg';
      await supabase.storage.from('profile-images').upload(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('profile-images').getPublicUrl(path);
      await supabase.from('profiles').update({'profile_image_url': url}).eq('id', user.id);
      profileImageUrl = url;
      profileImageBytes = bytes;
      notifyListeners();
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }

Future<bool> createServiceRequestSupabase({
  required String technicianId,
  required String service,
  required String description,
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    await supabase.from('service_requests').insert({
      'customer_id': user.id,
      'technician_id': technicianId,
      'service_type': service,
      'description': description,
      'status': 'pending',
    });
    activities.add('Requested $service');
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Service request error: $e');
    return false;
  }
}

 Future<bool> completePurchaseSupabase() async {
  if (cartItems.isEmpty) return false;
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final order = await supabase.from('orders').insert({
      'customer_id': user.id,
      'total_amount': cartTotal,
      'status': 'pending',
      'payment_status': 'unpaid',
    }).select().single();

    await supabase.from('order_items').insert([
      for (final item in cartItems)
        {
          'order_id': order['id'],
          'product_id': item.productId,
          'product_name': item.name,
          'quantity': item.quantity,
          'price': item.price,
        },
    ]);

    for (final item in cartItems) {
      supplierNotifications.add(
        'New purchase: ${item.quantity} × ${item.name} from ${item.supplierName}',
      );
    }
    activities.add('Purchased ${cartItems.length} product(s)');
    cartItems.clear();
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Purchase error: $e');
    return false;
  }
} 

  // ----------------------------------------------------------
  // ORIGINAL METHODS (KEPT INTACT FOR UI COMPATIBILITY)
  // ----------------------------------------------------------
  String tr(String key, {Map<String, String>? params}) {
    final Map<String, String> french = {
      'English': 'English', 'Français': 'Français', 'Select': 'Sélectionner', 'Home': 'Accueil', 'Shop': 'Boutique',
      'Subscription': 'Abonnement', 'Profile': 'Profil', 'Technicians': 'Techniciens', 'Customer': 'Client',
      'Technician': 'Technicien', 'Supplier': 'Fournisseur', 'Admin': 'Administrateur', 'Dashboard': 'Tableau de bord',
      'Platform overview': 'Vue d’ensemble de la plateforme', 'Manage platform operations and approvals.': 'Gérez les opérations et validations de la plateforme.',
      'Pending approvals': 'Approbations en attente', 'Active technicians': 'Techniciens actifs', 'Monthly revenue': 'Revenu mensuel',
      'Open disputes': 'Litiges ouverts', 'Review supplier requests': 'Vérifier les demandes fournisseurs', 'Verify technician profiles': 'Vérifier les profils techniciens',
      'Resolve customer complaints': 'Traiter les plaintes clients', 'View analytics': 'Voir les statistiques', 'Recent platform activity': 'Activité récente de la plateforme',
      'New supplier onboarding': 'Nouvelle inscription fournisseur', 'Technician verification complete': 'Vérification du technicien terminée',
      'Payment dispute escalated': 'Litige de paiement escaladé', 'Campaign promotion approved': 'Campagne promotionnelle approuvée', 'Approve': 'Approuver',
      'Quick actions': 'Actions rapides', 'Welcome to FixMate': 'Bienvenue sur FixMate', 'Your trusted technician marketplace': 'Votre plateforme de techniciens de confiance',
      'Email, phone number or name': 'E-mail, numéro de téléphone ou nom', 'Email': 'E-mail', 'Phone number': 'Numéro de téléphone', 'Password': 'Mot de passe',
      'Forgot password?': 'Mot de passe oublié ?', 'LOG IN': 'SE CONNECTER', "Don't have an account?": "Vous n'avez pas de compte ?", 'Sign up': "S'inscrire",
      'Please enter your email, phone number or name.': 'Veuillez entrer votre e-mail, numéro de téléphone ou nom.', 'Please enter your password.': 'Veuillez entrer votre mot de passe.',
      'Password reset instructions sent.': 'Instructions de réinitialisation du mot de passe envoyées.', 'Subscription request received.': 'Demande d abonnement reçue.',
      'Select account type': 'Sélectionnez le type de compte',
      'Until Firebase authentication is connected, select the type of account you want to test.': "En attendant la connexion de Firebase Authentication, sélectionnez le type de compte que vous souhaitez tester.",
      'Find technicians and purchase products.': 'Trouver des techniciens et acheter des produits.', 'Offer services and receive customer requests.': 'Proposer des services et recevoir des demandes de clients.',
      'Sell tools, parts and equipment.': 'Vendre des outils, pièces et équipements.', 'Create your account': 'Créez votre compte', 'I want to register as:': "Je veux m'inscrire en tant que :",
      'Request technicians and purchase products.': "Demander l'intervention de techniciens et acheter des produits.", 'Provide professional repair and maintenance services.': 'Fournir des services professionnels de réparation et de maintenance.',
      'Sell tools, equipment, spare parts and materials.': 'Vendre des outils, équipements, pièces détachées et matériaux.', 'Customer Registration': 'Inscription client',
      'Create customer account': 'Créer un compte client', 'Find trusted technicians and buy products on FixMate.': 'Trouvez des techniciens de confiance et achetez des produits sur FixMate.',
      'First name': 'Prénom', 'Last name': 'Nom', 'Confirm password': 'Confirmer le mot de passe', 'CREATE CUSTOMER ACCOUNT': 'CRÉER LE COMPTE CLIENT',
      'Technician Registration': 'Inscription technicien', 'Create technician account': 'Créer un compte technicien', 'Offer your professional services to customers.': 'Proposez vos services professionnels aux clients.',
      'Services you provide': 'Services que vous proposez', 'CREATE TECHNICIAN ACCOUNT': 'CRÉER LE COMPTE TECHNICIEN', 'Please select at least one service.': 'Veuillez sélectionner au moins un service.',
      'Supplier Registration': 'Inscription fournisseur', 'Create supplier account': 'Créer un compte fournisseur', 'Sell tools, equipment, spare parts and materials..': 'Vendez des outils, équipements, pièces détachées et matériaux..',
      'Company name': "Nom de l'entreprise", 'Additional phone number': 'Numéro de téléphone supplémentaire', 'Items you supply': 'Articles que vous fournissez', 'Location': 'Localisation',
      'Region': 'Région', 'Town': 'Ville', 'Business verification documents can be submitted after registration.': "Les documents de vérification de l'entreprise peuvent être soumis après l'inscription.",
      'CREATE SUPPLIER ACCOUNT': 'CRÉER LE COMPTE FOURNISSEUR', 'Please select at least one item category.': "Veuillez sélectionner au moins une catégorie d'articles.",
      'Passwords do not match.': 'Les mots de passe ne correspondent pas.', 'Your trusted technician marketplace.': 'Votre plateforme de techniciens de confiance.',
      'Find technicians, buy tools and equipment, and get your problems solved.': 'Trouvez des techniciens, achetez des outils et équipements et faites résoudre vos problèmes.',
      'Need a technician?': "Besoin d'un technicien ?", 'Find a professional near you.': 'Trouvez un professionnel près de chez vous.', 'Find a Technician': 'Trouver un technicien',
      'Popular Services': 'Services populaires', 'Electricity': 'Électricité', 'Plumbing': 'Plomberie', 'AC & Refrigeration': 'Climatisation et réfrigération',
      'Phone Repair': 'Réparation de téléphones', 'Computer Repair': 'Réparation informatique', 'Solar': 'Solaire', 'Auto Repair': 'Réparation automobile', 'Appliances': 'Électroménager',
      'How FixMate works': 'Comment fonctionne FixMate', 'Find': 'Trouver', 'Find a technician or product.': 'Trouvez un technicien ou un produit.', 'Request': 'Demander',
      'Describe your problem and location.': 'Décrivez votre problème et votre localisation.', 'Get it fixed': 'Faites réparer', 'Your technician comes to you.': 'Votre technicien vient chez vous.',
      'Rate': 'Évaluer', 'Rate your experience.': 'Évaluez votre expérience.', 'Search technician': 'Rechercher un technicien', 'service': 'service', 'town': 'ville', 'region': 'région',
      'Service': 'Service', 'Rating': 'Note', 'Distance': 'Distance', 'Sort': 'Trier', 'Certified': 'Certifié', 'jobs completed': 'interventions terminées', 'VIEW PROFILE': 'VOIR LE PROFIL',
      'FixMate Shop': 'Boutique FixMate', 'Search products': 'Rechercher des produits', 'tools': 'outils', 'suppliers': 'fournisseurs', 'categories': 'catégories', 'Products & Tools': 'Produits et outils',
      'ADD TO CART': 'AJOUTER AU PANIER', 'POST PRODUCT': 'PUBLIER UN PRODUIT', 'No technicians found.': 'Aucun technicien trouvé.', 'All services': 'Tous les services', 'Clear filters': 'Effacer les filtres',
      'Digital Multimeter': 'Multimètre numérique', 'Electric Drill': 'Perceuse électrique', 'Soldering Station': 'Station de soudage', 'Tool Set': "Jeu d'outils", 'Voltage Tester': 'Testeur de tension',
      'Solar Controller': 'Régulateur solaire', 'My Cart': 'Mon panier', 'Your cart is empty.': 'Votre panier est vide.', 'Add products from the shop.': 'Ajoutez des produits depuis la boutique.',
      'Total': 'Total', 'CHECKOUT': 'PASSER LA COMMANDE', 'Order placed! Thank you.': 'Commande passée ! Merci.', 'FixMate Subscription': 'Abonnement FixMate',
      'Your technician account includes a 7-day free trial.': 'Votre compte technicien comprend un essai gratuit de 7 jours.', 'Choose the plan that works best for your business.': 'Choisissez le forfait qui convient le mieux à votre activité.',
      'Monthly': 'Mensuel', 'Flexible monthly subscription.': 'Abonnement mensuel flexible.', 'month': 'mois', 'Annual': 'Annuel', 'Best value for long-term users.': 'Meilleur rapport qualité-prix pour une utilisation à long terme.',
      'year': 'an', 'RECOMMENDED': 'RECOMMANDÉ', 'Payment methods': 'Modes de paiement', 'MTN Mobile Money': 'MTN Mobile Money', 'Orange Money': 'Orange Money', 'Visa / Card': 'Visa / Carte',
      'Bank': 'Banque', 'SUBSCRIBE': "S'ABONNER", 'Please choose a subscription plan.': 'Veuillez choisir un forfait d abonnement.', 'Please choose a payment method.': 'Veuillez choisir un mode de paiement.',
      'My Profile': 'Mon profil', 'FixMate User': 'Utilisateur FixMate', 'Edit Profile': 'Modifier le profil', 'Phone Numbers': 'Numéros de téléphone', 'Change Password': 'Modifier le mot de passe',
      'Verification & Documents': 'Vérification et documents', 'My Ratings': 'Mes évaluations', 'My Activity': 'Mon activité', 'LOG OUT': 'SE DÉCONNECTER', 'Services provided': 'Services proposés',
      'Request this technician': 'Demander ce technicien', 'Describe the service you need.': 'Décrivez le service dont vous avez besoin.', 'Please describe the service you need.': 'Veuillez décrire le service dont vous avez besoin.',
      'Service request sent successfully.': 'Demande de service envoyée avec succès.', 'REQUEST SERVICE': 'DEMANDER LE SERVICE', 'Choose profile picture': 'Choisir une photo de profil',
      'Choose from device': 'Choisir depuis l appareil', 'Take a photo': 'Prendre une photo', 'Light mode': 'Mode clair', 'Dark mode': 'Mode sombre', 'Language': 'Langue', 'Search...': 'Rechercher...',
      'Refrigeration & Air Conditioning': 'Réfrigération et climatisation', 'Phone Repairs': 'Réparation de téléphones', 'Carpentry': 'Menuiserie', 'Painting': 'Peinture', 'Welding': 'Soudure',
      'Masonry': 'Maçonnerie', 'Tiling': 'Carrelage', 'Fenestration': 'Fenêtres et portes', 'Home Appliance Repair': "Réparation d'appareils électroménagers", 'Computer & IT Tools Repair': 'Réparation informatique et équipements IT',
      'Audio Repair': 'Réparation audio', 'Electronics Repair': 'Réparation électronique', 'Solar Maintenance & Repair': 'Maintenance et réparation solaire', 'Electrical Materials': 'Matériel électrique',
      'Plumbing Materials': 'Matériel de plomberie', 'Refrigeration Equipment': 'Équipement de réfrigération', 'Air Conditioning Equipment': 'Équipement de climatisation', 'Phone Parts': 'Pièces de téléphone',
      'Carpentry Materials': 'Matériaux de menuiserie', 'Paint': 'Peinture', 'Welding Equipment': 'Équipement de soudage', 'Masonry Materials': 'Matériaux de maçonnerie', 'Tiles': 'Carrelage',
      'Windows & Doors': 'Fenêtres et portes', 'Auto Parts': 'Pièces automobiles', 'Home Appliances': 'Appareils électroménagers', 'Computers': 'Ordinateurs', 'IT Equipment': 'Équipement informatique',
      'Audio Equipment': 'Équipement audio', 'Electronic Components': 'Composants électroniques', 'Solar Equipment': 'Équipement solaire', 'Tools': 'Outils', 'Safety Equipment': 'Équipement de sécurité',
      'Other': 'Autre',
       'No products found.': 'Aucun produit trouvé.', 'My Orders': 'Mes commandes',
'Sold by': 'Vendu par',
'Your orders will appear here after checkout.': 'Vos commandes apparaîtront ici après le paiement.', 'General': 'Général', 'My Requests': 'Mes demandes', 'Orders received': 'Commandes reçues',
'No orders yet.': 'Aucune commande pour le moment.',
'Confirmed': 'Confirmée',
'Shipped': 'Expédiée',
'Delivered': 'Livrée',
'Confirm': 'Confirmer',
'Mark as shipped': 'Marquer comme expédiée',
'Mark as delivered': 'Marquer comme livrée',
'Decline this item?': 'Refuser cet article ?',
'Item updated.': 'Article mis à jour.',
'Could not update the item.': "Impossible de mettre à jour l'article.",
'Could not load orders.': 'Impossible de charger les commandes.',
'Payment': 'Paiement',
'Unpaid': 'Non payé',
'Paid': 'Payé',
'Refunded': 'Remboursé',
'No requests yet.': 'Aucune demande pour le moment.', 'Delete this product?': 'Supprimer ce produit ?',
'Product deleted.': 'Produit supprimé.',
'Could not delete the product.': 'Impossible de supprimer le produit.',
'Product posted.': 'Produit publié.',
'Could not post the product. Please try again.': "Impossible de publier le produit. Veuillez réessayer.",
'Enter a product name and a valid price.': 'Entrez un nom de produit et un prix valide.',
'Please choose a category.': 'Veuillez choisir une catégorie.',
'Product name': 'Nom du produit',
'Price (FCFA)': 'Prix (FCFA)',
'Category': 'Catégorie',
'Description (optional)': 'Description (facultatif)',
'Post product': 'Publier un produit',
'Cancel': 'Annuler',
'POST': 'PUBLIER',
'Out of stock': 'Rupture de stock',
'Your product': 'Votre produit',
'Showing demo products. Real products appear once suppliers post them.': 'Produits de démonstration affichés. Les vrais produits apparaîtront dès que les fournisseurs en publieront.',
'Pending': 'En attente',
'Accepted': 'Acceptée',
'Declined': 'Refusée',
'Completed': 'Terminée',
'Cancelled': 'Annulée',
'Accept': 'Accepter',
'Decline': 'Refuser',
'Mark as completed': 'Marquer comme terminée',
'Cancel request': 'Annuler la demande',
'Decline this request?': 'Refuser cette demande ?',
'Cancel this request?': 'Annuler cette demande ?',
'Request updated.': 'Demande mise à jour.',
'Could not update the request.': 'Impossible de mettre à jour la demande.',
'Could not load your requests.': 'Impossible de charger vos demandes.',
'Retry': 'Réessayer',
'Yes': 'Oui',
'No': 'Non',
'New': 'Nouveau',
'Showing demo technicians. Real technicians appear here once they sign up.': 'Techniciens de démonstration affichés. Les vrais techniciens apparaîtront ici après leur inscription.',
'This is a demo profile. Requests can only be sent to real technicians.': 'Ceci est un profil de démonstration. Les demandes ne peuvent être envoyées qu’à de vrais techniciens.',
'Could not send your request. Please try again.': "Impossible d'envoyer votre demande. Veuillez réessayer.",'Removed from cart': 'Retiré du panier',
'UNDO': 'ANNULER',
'Increase': 'Augmenter',
'Decrease': 'Diminuer',
'Remove': 'Retirer',
'Could not place your order. Please try again.': "Impossible de passer votre commande. Veuillez réessayer.",'Reset password': 'Réinitialiser le mot de passe',
'Enter your email and we will send you a code.': 'Entrez votre e-mail et nous vous enverrons un code.',
'SEND CODE': 'ENVOYER LE CODE',
'Resend code': 'Renvoyer le code',
'Code from your email': 'Code reçu par e-mail',
'New password': 'Nouveau mot de passe',
'RESET PASSWORD': 'RÉINITIALISER',
'Please enter the code from your email.': 'Veuillez entrer le code reçu par e-mail.',
'If an account exists for this email, a code has been sent.': 'Si un compte existe pour cet e-mail, un code a été envoyé.',
'The code is invalid or has expired.': 'Le code est invalide ou a expiré.',
'Password changed. Please log in.': 'Mot de passe modifié. Veuillez vous connecter.',
'Password must be at least 6 characters.': 'Le mot de passe doit contenir au moins 6 caractères.', 'Name': 'Nom','Please enter your email and password.': 'Veuillez entrer votre e-mail et votre mot de passe.',
'Incorrect email or password.': 'E-mail ou mot de passe incorrect.',
'Please confirm your email first. Check your inbox.': 'Veuillez d’abord confirmer votre e-mail. Vérifiez votre boîte de réception.',
'An account with this email already exists.': 'Un compte avec cet e-mail existe déjà.',
'Password is too weak. Use at least 6 characters.': 'Mot de passe trop faible. Utilisez au moins 6 caractères.',
'Too many attempts. Please wait a moment and try again.': 'Trop de tentatives. Veuillez patienter un instant et réessayer.',
'Please enter a valid email address.': 'Veuillez entrer une adresse e-mail valide.',
'No internet connection. Please check your network.': 'Pas de connexion internet. Vérifiez votre réseau.',
'Something went wrong. Please try again.': 'Une erreur est survenue. Veuillez réessayer.',
'Signup failed. Please try again.': "L'inscription a échoué. Veuillez réessayer.",
'Account created! Please confirm your email, then log in.': 'Compte créé ! Veuillez confirmer votre e-mail, puis vous connecter.',
'SAVE': 'ENREGISTRER',
'No activity yet.': 'Aucune activité pour le moment.',
'New password (optional)': 'Nouveau mot de passe (facultatif)',
'Profile updated successfully.': 'Profil mis à jour avec succès.',
'Could not save your changes.': "Impossible d'enregistrer vos modifications.",
'Password must be at least 6 characters. ': 'Le mot de passe doit contenir au moins 6 caractères.',
'Profile saved, but the password could not be changed.': "Profil enregistré, mais le mot de passe n'a pas pu être modifié.", 'Electricity/Solar': 'Électricité/Solaire', 'Plumbing/Masonry': 'Plomberie/Maçonnerie', 'Phone Repairs/Electronics': 'Réparation de téléphones/Électronique',
    };
    String result = language == 'Français' ? (french[key] ?? key) : key;
    params?.forEach((name, value) { result = result.replaceAll('{$name}', value); });
    return result;
  }

  Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  themeMode = (prefs.getBool('darkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
  language = prefs.getString('language') ?? 'English';
  notifyListeners();
}

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    language = language == 'English' ? 'Français' : 'English';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  void login(String role) {
    userRole = role;
    loggedIn = true;
    profileName = role == 'Supplier' ? 'FixMate Supplies' : role == 'Technician' ? 'Jean Michel Mbarga' : role == 'Admin' ? 'FixMate Admin' : 'FixMate User';
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('userRole', userRole);
      await prefs.setString('loginIdentifier', loginIdentifier);
    });
    notifyListeners();
  }

  void logout() {
    userRole = '';
    loggedIn = false;
    loginIdentifier = '';
    cartItems.clear();
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.remove('userRole');
      await prefs.remove('loginIdentifier');
    });
    notifyListeners();
  }

  int get cartCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  
  void completePurchase() {
    if (cartItems.isEmpty) return;
    for (final item in cartItems) {
      supplierNotifications.add('New purchase: ${item.quantity} × ${item.name} from ${item.supplierName}');
    }
    activities.add('Purchased ${cartItems.length} product(s)');
    cartItems.clear();
    notifyListeners();
  }



  Future<bool> updateProfile({
  required String name,
  required String phone,
  required String location,
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    await supabase.from('profiles').update({
      'full_name': name,
      'phone': phone,
      'location': location,
    }).eq('id', user.id);

    profileName = name;
    profilePhone = phone;
    profileLocation = location;
    activities.add('Updated profile information');
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Update profile error: $e');
    return false;
  }
}

Future<bool> changePassword(String newPassword) async {
  try {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
    activities.add('Changed password');
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Change password error: $e');
    return false;
  }
}

  void updateProfileImage(Uint8List bytes) {
    profileImageBytes = bytes;
    activities.add('Updated profile picture');
    notifyListeners();
  }

  void recordActivity(String activity) {
    activities.add(activity);
    notifyListeners();
  }

 void addToCart(Product product) {
  final key = product.id ?? product.name;
  final index = cartItems.indexWhere((item) => item.key == key);
  if (index >= 0) {
    cartItems[index].quantity++;
  } else {
    cartItems.add(CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      supplierName: product.supplierName,
    ));
  }
  activities.add('Added ${product.name} from ${product.supplierName} to cart');
  notifyListeners();
}

void removeFromCart(String key) {
  cartItems.removeWhere((item) => item.key == key);
  notifyListeners();
}

void increaseQuantity(String key) {
  final index = cartItems.indexWhere((item) => item.key == key);
  if (index < 0) return;
  cartItems[index].quantity++;
  notifyListeners();
}

void decreaseQuantity(String key) {
  final index = cartItems.indexWhere((item) => item.key == key);
  if (index < 0) return;
  if (cartItems[index].quantity > 1) {
    cartItems[index].quantity--;
  } else {
    cartItems.removeAt(index);
  }
  notifyListeners();
}

void restoreCartItem(CartItem item, int index) {
  if (cartItems.any((existing) => existing.key == item.key)) return;
  final position = index > cartItems.length ? cartItems.length : index;
  cartItems.insert(position, item);
  notifyListeners();
}

}

class CartItem {
  final String? productId;
  final String name;
  final double price;
  final String supplierName;
  int quantity;

  CartItem({
    this.productId,
    required this.name,
    required this.price,
    required this.supplierName,
    this.quantity = 1,
  });

  // Unique identity in the cart: two suppliers can sell a product with the same name
  String get key => productId ?? name;
}

class Product {
  final String? id;
  final String? supplierId;
  final String name;
  final double price;
  final String supplierName;
  final bool supplierCertified;
  final String category;
  final String description;
  final bool inStock;
  final IconData icon;

  Product({
    this.id,
    this.supplierId,
    required this.name,
    required this.price,
    this.supplierName = 'FixMate Supplies',
    this.supplierCertified = true,
    this.category = '',
    this.description = '',
    this.inStock = true,
    this.icon = Icons.build,
  });
}

const List<String> productCategories = [
  'Electrical Materials',
  'Plumbing Materials',
  'Refrigeration Equipment',
  'Air Conditioning Equipment',
  'Phone Parts',
  'Carpentry Materials',
  'Paint',
  'Welding Equipment',
  'Masonry Materials',
  'Tiles',
  'Windows & Doors',
  'Auto Parts',
  'Home Appliances',
  'Computers',
  'IT Equipment',
  'Audio Equipment',
  'Electronic Components',
  'Solar Equipment',
  'Tools',
  'Safety Equipment',
  'Other',
];

IconData iconForCategory(String category) {
  switch (category) {
    case 'Electrical Materials':
    case 'Electronic Components':
      return Icons.electrical_services;
    case 'Plumbing Materials':
      return Icons.plumbing;
    case 'Refrigeration Equipment':
    case 'Air Conditioning Equipment':
      return Icons.ac_unit;
    case 'Phone Parts':
      return Icons.phone_android;
    case 'Carpentry Materials':
      return Icons.carpenter;
    case 'Paint':
      return Icons.format_paint;
    case 'Welding Equipment':
      return Icons.precision_manufacturing;
    case 'Masonry Materials':
      return Icons.foundation;
    case 'Tiles':
      return Icons.grid_view;
    case 'Windows & Doors':
      return Icons.door_front_door;
    case 'Auto Parts':
      return Icons.directions_car;
    case 'Home Appliances':
      return Icons.kitchen;
    case 'Computers':
    case 'IT Equipment':
      return Icons.computer;
    case 'Audio Equipment':
      return Icons.speaker;
    case 'Solar Equipment':
      return Icons.solar_power;
    case 'Tools':
      return Icons.handyman;
    case 'Safety Equipment':
      return Icons.health_and_safety;
    default:
      return Icons.build;
  }
}
final List<Product> shopProducts = [
  Product(
    name: 'Digital Multimeter',
    price: 18500,
    supplierName: 'ElectroPro Cameroon',
    icon: Icons.electrical_services,
  ),
  Product(
    name: 'Electric Drill',
    price: 45000,
    supplierName: 'BuildRight Tools',
    icon: Icons.handyman,
  ),
  Product(
    name: 'Soldering Station',
    price: 25000,
    supplierName: 'ElectroPro Cameroon',
    icon: Icons.precision_manufacturing,
  ),
  Product(
    name: 'Tool Set',
    price: 35000,
    supplierName: 'BuildRight Tools',
    icon: Icons.handyman_outlined,
  ),
  Product(
    name: 'Voltage Tester',
    price: 8500,
    supplierName: 'TechParts Douala',
    icon: Icons.bolt,
  ),
  Product(
    name: 'Solar Controller',
    price: 28000,
    supplierName: 'Solar Solutions CM',
    icon: Icons.solar_power,
  ),
  Product(
    name: 'Pipe Wrench',
    price: 12000,
    supplierName: 'BuildRight Tools',
    icon: Icons.plumbing,
  ),
  Product(
    name: 'Cordless Screwdriver',
    price: 32000,
    supplierName: 'ElectroPro Cameroon',
    icon: Icons.power,
  ),
  Product(
    name: 'Refrigerant Gauge Set',
    price: 42000,
    supplierName: 'CoolTech Supplies',
    icon: Icons.ac_unit,
  ),
  Product(
    name: 'Network Cable Tester',
    price: 15000,
    supplierName: 'TechParts Douala',
    icon: Icons.router,
  ),
  Product(
    name: 'Automotive Diagnostic Scanner',
    price: 65000,
    supplierName: 'AutoPro Cameroon',
    icon: Icons.directions_car,
  ),
  Product(
    name: 'Solar Installation Kit',
    price: 78000,
    supplierName: 'Solar Solutions CM',
    icon: Icons.wb_sunny,
  ), 
  Product(
    name: 'Safety Helmet',
    price: 9000,
    supplierName: 'SafeWork Supplies',
    icon: Icons.health_and_safety,
  ),
];

class ServiceRequestData {
  final String id;
  final String customerId;
  final String technicianId;
  final String serviceType;
  final String description;
  String status;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String technicianName;
  final String technicianPhone;

  ServiceRequestData({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.technicianName,
    required this.technicianPhone,
  });

  factory ServiceRequestData.fromRow(Map<String, dynamic> row) {
    return ServiceRequestData(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      technicianId: row['technician_id'] as String,
      serviceType: (row['service_type'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      status: (row['status'] as String?) ?? 'pending',
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      customerName: (row['customer_name'] as String?) ?? '',
      customerPhone: (row['customer_phone'] as String?) ?? '',
      technicianName: (row['technician_name'] as String?) ?? '',
      technicianPhone: (row['technician_phone'] as String?) ?? '',
    );
  }
}

class SupplierOrderItem {
  final String id;
  final String orderId;
  final String productName;
  final int quantity;
  final double price;
  String status;
  final String paymentStatus;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;

  SupplierOrderItem({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
  });

  double get subtotal => price * quantity;

  factory SupplierOrderItem.fromRow(Map<String, dynamic> row) {
    return SupplierOrderItem(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      productName: (row['product_name'] as String?) ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      price: double.tryParse('${row['price']}') ?? 0,
      status: (row['fulfillment_status'] as String?) ?? 'pending',
      paymentStatus: (row['payment_status'] as String?) ?? 'unpaid',
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      customerName: (row['customer_name'] as String?) ?? '',
      customerPhone: (row['customer_phone'] as String?) ?? '',
    );
  }
}

class CustomerOrderItem {
  final String id;
  final String productName;
  final int quantity;
  final double price;
  final String status;
  final String supplierName;
  final String supplierPhone;

  CustomerOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.status,
    required this.supplierName,
    required this.supplierPhone,
  });

  double get subtotal => price * quantity;
}

class CustomerOrder {
  final String id;
  final DateTime createdAt;
  final double total;
  final String paymentStatus;
  final List<CustomerOrderItem> items;

  CustomerOrder({
    required this.id,
    required this.createdAt,
    required this.total,
    required this.paymentStatus,
    required this.items,
  });
}

class TechnicianData {
  final String? id;
  final String name;
  final List<String> services;
  final String region;
  final String town;
  final double rating;
  final int jobs;
  final bool certified;
  final String imagePath;
  final String? imageUrl;

  const TechnicianData({
    this.id,
    required this.name,
    required this.services,
    required this.region,
    required this.town,
    required this.rating,
    required this.jobs,
    required this.certified,
    required this.imagePath,
    this.imageUrl,
  });

  ImageProvider? get image {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    if (imagePath.isNotEmpty) return AssetImage(imagePath);
    return null;
  }
}

final List<TechnicianData> technicians = [
  const TechnicianData(name: 'Jean Michel Mbarga', services: ['Electricity', 'Solar', 'Electronics Repair'], region: 'Littoral', town: 'Douala', rating: 4.8, jobs: 132, certified: true, imagePath: 'assets/images/images (2).jpg'),
  const TechnicianData(name: 'Philippe Njoya', services: ['Plumbing', 'Masonry'], region: 'Centre', town: 'Yaoundé', rating: 4.6, jobs: 87, certified: true, imagePath: 'assets/images/images (29).jpg'),
  const TechnicianData(name: 'Armand Tchoumi', services: ['Phone Repairs', 'Electronics'], region: 'Southwest', town: 'Buea', rating: 4.7, jobs: 64, certified: false, imagePath: 'assets/images/images (4).jpg'),
  const TechnicianData(name: 'Claude Essomba', services: ['Refrigeration & Air Conditioning'], region: 'Littoral', town: 'Douala', rating: 4.9, jobs: 151, certified: true, imagePath: 'assets/images/images (5).jpg'),
  const TechnicianData(name: 'Boris Fongang', services: ['Carpentry', 'Tiling', 'Painting'], region: 'West', town: 'Bafoussam', rating: 4.5, jobs: 73, certified: false, imagePath: 'assets/images/images (6).jpg'),
  const TechnicianData(name: 'Nicolas Mballa', services: ['Computer & IT Tools Repair'], region: 'Centre', town: 'Yaoundé', rating: 4.8, jobs: 96, certified: true, imagePath: 'assets/images/images (7).jpg'),
  const TechnicianData(name: 'Emmanuel Tabi', services: ['Auto Repair'], region: 'Southwest', town: 'Limbe', rating: 4.4, jobs: 58, certified: false, imagePath: 'assets/images/images (21).jpg'),
  const TechnicianData(name: 'Romain Abena', services: ['Painting', 'Masonry'], region: 'Centre', town: 'Mbalmayo', rating: 4.6, jobs: 49, certified: false, imagePath: 'assets/images/images (9).jpg'),
  const TechnicianData(name: 'Patrick Kouassi', services: ['Welding'], region: 'Littoral', town: 'Nkongsamba', rating: 4.7, jobs: 81, certified: true, imagePath: 'assets/images/images (10).jpg'),
  const TechnicianData(name: 'Mathurin Talla', services: ['Home Appliance Repair'], region: 'West', town: 'Dschang', rating: 4.5, jobs: 62, certified: false, imagePath: 'assets/images/images (11).jpg'),
  const TechnicianData(name: 'Serge Mvondo', services: ['Electricity', 'Electronics'], region: 'East', town: 'Bertoua', rating: 4.3, jobs: 44, certified: false, imagePath: 'assets/images/images (12).jpg'),
  const TechnicianData(name: 'Etienne Ngono', services: ['Solar', 'Electricity'], region: 'North', town: 'Garoua', rating: 4.8, jobs: 104, certified: true, imagePath: 'assets/images/images (13).jpg'),
  const TechnicianData(name: 'Lucien Fon', services: ['Plumbing'], region: 'Northwest', town: 'Bamenda', rating: 4.6, jobs: 71, certified: true, imagePath: 'assets/images/images (15).jpg'),
  const TechnicianData(name: 'Aline Mengue', services: ['Phone Repairs'], region: 'South', town: 'Ebolowa', rating: 4.4, jobs: 38, certified: false, imagePath: 'assets/images/images (14).jpg'),
  const TechnicianData(name: 'Didier Atem', services: ['Carpentry'], region: 'Southwest', town: 'Kumba', rating: 4.5, jobs: 67, certified: false, imagePath: 'assets/images/images (16).jpg'),
  const TechnicianData(name: 'Grace Nono', services: ['Tiling', 'Painting', 'Masonry'], region: 'Littoral', town: 'Douala', rating: 4.7, jobs: 91, certified: true, imagePath: 'assets/images/images (17).jpg'),
  const TechnicianData(name: 'Hervé Ngassa', services: ['Refrigeration & Air Conditioning'], region: 'Littoral', town: 'Edéa', rating: 4.6, jobs: 77, certified: false, imagePath: 'assets/images/images (30).jpg'),
  const TechnicianData(name: 'Marie Fotsa', services: ['Masonry'], region: 'West', town: 'Bafoussam', rating: 4.2, jobs: 35, certified: false, imagePath: 'assets/images/images (18).jpg'),
  const TechnicianData(name: 'Alain Owona', services: ['Computer & IT Tools Repair', 'Electronics', 'Audio Repair'], region: 'Centre', town: 'Yaoundé', rating: 4.9, jobs: 118, certified: true, imagePath: 'assets/images/images (19).jpg'),
  const TechnicianData(name: 'Solange Bika', services: ['Auto Repair'], region: 'Littoral', town: 'Douala', rating: 4.5, jobs: 83, certified: false, imagePath: 'assets/images/images (20).jpg'),
  const TechnicianData(name: 'Fabrice Nkem', services: ['Welding', 'Carpentry'], region: 'Adamawa', town: 'Ngaoundéré', rating: 4.3, jobs: 47, certified: false, imagePath: 'assets/images/images (24).jpg'),
  const TechnicianData(name: 'Chantal Yondo', services: ['Electricity'], region: 'South', town: 'Kribi', rating: 4.7, jobs: 69, certified: true, imagePath: 'assets/images/images (22).jpg'),
  const TechnicianData(name: 'André Biloa', services: ['Plumbing'], region: 'East', town: 'Bertoua', rating: 4.4, jobs: 55, certified: false, imagePath: 'assets/images/images (25).jpg'),
  const TechnicianData(name: 'Florence Tchinda', services: ['Solar'], region: 'North', town: 'Maroua', rating: 4.8, jobs: 88, certified: true, imagePath: 'assets/images/images (23).jpg'),
  const TechnicianData(name: 'Seraphin Etoa', services: ['Masonry', 'Tiling'], region: 'Centre', town: 'Obala', rating: 4.1, jobs: 29, certified: false, imagePath: 'assets/images/images (26).jpg'),
  const TechnicianData(name: 'Rebecca Manka', services: ['Home Appliance Repair'], region: 'Northwest', town: 'Bamenda', rating: 4.6, jobs: 74, certified: true, imagePath: 'assets/images/images (3).jpg'),
  const TechnicianData(name: 'Michel Ndongo', services: ['Painting'], region: 'Littoral', town: 'Douala', rating: 4.2, jobs: 41, certified: false, imagePath: 'assets/images/images (31).jpg'),
  const TechnicianData(name: 'Joséphine Ewane', services: ['Electronics'], region: 'Southwest', town: 'Buea', rating: 4.7, jobs: 63, certified: true, imagePath: 'assets/images/images (8).jpg'),
  const TechnicianData(name: 'Thomas Wamba', services: ['Auto Repair', 'Welding'], region: 'West', town: 'Bamendjou', rating: 4.5, jobs: 57, certified: false, imagePath: 'assets/images/images (28).jpg'),
  const TechnicianData(name: 'Hélène Abanda', services: ['Refrigeration & Air Conditioning', 'Electricity', 'Solar'], region: 'Centre', town: 'Yaoundé', rating: 4.8, jobs: 109, certified: true, imagePath: 'assets/images/images (18).jpg'),
];
