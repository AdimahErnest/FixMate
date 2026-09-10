import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FixMateApp(),
    ),
  );
}

// ============================================================
// APP STATE
// ============================================================

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  // English or Français
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

  bool get isFrench => language == 'Français';

  List<Product> get catalogProducts => products;

  // ----------------------------------------------------------
  // TRANSLATION
  // ----------------------------------------------------------

  String tr(String key, {Map<String, String>? params}) {
    final Map<String, String> french = {
      // General
      'English': 'English',
      'Français': 'Français',
      'Select': 'Sélectionner',
      'Home': 'Accueil',
      'Shop': 'Boutique',
      'Subscription': 'Abonnement',
      'Profile': 'Profil',
      'Technicians': 'Techniciens',
      'Customer': 'Client',
      'Technician': 'Technicien',
      'Supplier': 'Fournisseur',
      'Admin': 'Administrateur',
      'Dashboard': 'Tableau de bord',
      'Platform overview': 'Vue d’ensemble de la plateforme',
      'Manage platform operations and approvals.': 'Gérez les opérations et validations de la plateforme.',
      'Pending approvals': 'Approbations en attente',
      'Active technicians': 'Techniciens actifs',
      'Monthly revenue': 'Revenu mensuel',
      'Open disputes': 'Litiges ouverts',
      'Review supplier requests': 'Vérifier les demandes fournisseurs',
      'Verify technician profiles': 'Vérifier les profils techniciens',
      'Resolve customer complaints': 'Traiter les plaintes clients',
      'View analytics': 'Voir les statistiques',
      'Recent platform activity': 'Activité récente de la plateforme',
      'New supplier onboarding': 'Nouvelle inscription fournisseur',
      'Technician verification complete': 'Vérification du technicien terminée',
      'Payment dispute escalated': 'Litige de paiement escaladé',
      'Campaign promotion approved': 'Campagne promotionnelle approuvée',
      'Approve': 'Approuver',
      'Quick actions': 'Actions rapides',

      // Login
      'Welcome to FixMate': 'Bienvenue sur FixMate',
      'Your trusted technician marketplace':
          'Votre plateforme de techniciens de confiance',
      'Email, phone number or name':
          'E-mail, numéro de téléphone ou nom',
      'Email': 'E-mail',
      'Phone number': 'Numéro de téléphone',
      'Password': 'Mot de passe',
      'Forgot password?': 'Mot de passe oublié ?',
      'LOG IN': 'SE CONNECTER',
      "Don't have an account?": "Vous n'avez pas de compte ?",
      'Sign up': "S'inscrire",
      'Please enter your email, phone number or name.':
          'Veuillez entrer votre e-mail, numéro de téléphone ou nom.',
      'Please enter your password.':
          'Veuillez entrer votre mot de passe.',
        'Password reset instructions sent.':
          'Instructions de réinitialisation du mot de passe envoyées.',
        'Subscription request received.':
          'Demande d abonnement reçue.',

      // Role selection
      'Select account type': 'Sélectionnez le type de compte',
      'Demo login': 'Connexion de démonstration',
      'Until Firebase authentication is connected, select the type of account you want to test.':
          "En attendant la connexion de Firebase Authentication, sélectionnez le type de compte que vous souhaitez tester.",
      'Find technicians and purchase products.':
          'Trouver des techniciens et acheter des produits.',
      'Offer services and receive customer requests.':
          'Proposer des services et recevoir des demandes de clients.',
      'Sell tools, parts and equipment.':
          'Vendre des outils, pièces et équipements.',
      'Create your account': 'Créez votre compte',
      'I want to register as:': "Je veux m'inscrire en tant que :",
      'Request technicians and purchase products.':
          "Demander l'intervention de techniciens et acheter des produits.",
      'Provide professional repair and maintenance services.':
          'Fournir des services professionnels de réparation et de maintenance.',
      'Sell tools, equipment, spare parts and materials.':
          'Vendre des outils, équipements, pièces détachées et matériaux.',

      // Customer registration
      'Customer Registration': 'Inscription client',
      'Create customer account': 'Créer un compte client',
      'Find trusted technicians and buy products on FixMate.':
          'Trouvez des techniciens de confiance et achetez des produits sur FixMate.',
      'First name': 'Prénom',
      'Last name': 'Nom',
      'Confirm password': 'Confirmer le mot de passe',
      'CREATE CUSTOMER ACCOUNT': 'CRÉER LE COMPTE CLIENT',

      // Technician registration
      'Technician Registration': 'Inscription technicien',
      'Create technician account': 'Créer un compte technicien',
      'Offer your professional services to customers.':
          'Proposez vos services professionnels aux clients.',
      'Services you provide': 'Services que vous proposez',
      'CREATE TECHNICIAN ACCOUNT': 'CRÉER LE COMPTE TECHNICIEN',
      'Please select at least one service.':
          'Veuillez sélectionner au moins un service.',

      // Supplier registration
      'Supplier Registration': 'Inscription fournisseur',
      'Create supplier account': 'Créer un compte fournisseur',
      'Sell tools, equipment, spare parts and materials..':
          'Vendez des outils, équipements, pièces détachées et matériaux..',
      'Company name': "Nom de l'entreprise",
      'Additional phone number': 'Numéro de téléphone supplémentaire',
      'Items you supply': 'Articles que vous fournissez',
      'Location': 'Localisation',
      'Region': 'Région',
      'Town': 'Ville',
      'Business verification documents can be submitted after registration.':
          "Les documents de vérification de l'entreprise peuvent être soumis après l'inscription.",
      'CREATE SUPPLIER ACCOUNT': 'CRÉER LE COMPTE FOURNISSEUR',
      'Please select at least one item category.':
          "Veuillez sélectionner au moins une catégorie d'articles.",

      // Password
      'Passwords do not match.':
          'Les mots de passe ne correspondent pas.',

      // Home
      'Your trusted technician marketplace.':
          'Votre plateforme de techniciens de confiance.',
      'Find technicians, buy tools and equipment, and get your problems solved.':
          'Trouvez des techniciens, achetez des outils et équipements et faites résoudre vos problèmes.',
      'Need a technician?': "Besoin d'un technicien ?",
      'Find a professional near you.':
          'Trouvez un professionnel près de chez vous.',
      'Find a Technician': 'Trouver un technicien',
      'Popular Services': 'Services populaires',
      'Electricity': 'Électricité',
      'Plumbing': 'Plomberie',
      'AC & Refrigeration': 'Climatisation et réfrigération',
      'Phone Repair': 'Réparation de téléphones',
      'Computer Repair': 'Réparation informatique',
      'Solar': 'Solaire',
      'Auto Repair': 'Réparation automobile',
      'Appliances': 'Électroménager',
      'How FixMate works': 'Comment fonctionne FixMate',
      'Find': 'Trouver',
      'Find a technician or product.':
          'Trouvez un technicien ou un produit.',
      'Request': 'Demander',
      'Describe your problem and location.':
          'Décrivez votre problème et votre localisation.',
      'Get it fixed': 'Faites réparer',
      'Your technician comes to you.':
          'Votre technicien vient chez vous.',
      'Rate': 'Évaluer',
      'Rate your experience.':
          'Évaluez votre expérience.',

      // Technician page
      'Search technician': 'Rechercher un technicien',
      'service': 'service',
      'town': 'ville',
      'region': 'région',
      'Service': 'Service',
      'Rating': 'Note',
      'Distance': 'Distance',
      'Sort': 'Trier',
      'Certified': 'Certifié',
      'jobs completed': 'interventions terminées',
      'VIEW PROFILE': 'VOIR LE PROFIL',

      // Shop
      'FixMate Shop': 'Boutique FixMate',
      'Search products': 'Rechercher des produits',
      'tools': 'outils',
      'suppliers': 'fournisseurs',
      'categories': 'catégories',
      'Products & Tools': 'Produits et outils',
      'ADD TO CART': 'AJOUTER AU PANIER',
      'POST PRODUCT': 'PUBLIER UN PRODUIT',
      'No technicians found.': 'Aucun technicien trouvé.',
      'All services': 'Tous les services',
      'Clear filters': 'Effacer les filtres',

      // Products
      'Digital Multimeter': 'Multimètre numérique',
      'Electric Drill': 'Perceuse électrique',
      'Soldering Station': 'Station de soudage',
      'Tool Set': "Jeu d'outils",
      'Voltage Tester': 'Testeur de tension',
      'Solar Controller': 'Régulateur solaire',

      // Cart
      'My Cart': 'Mon panier',
      'Your cart is empty.': 'Votre panier est vide.',
      'Add products from the shop.':
          'Ajoutez des produits depuis la boutique.',
      'Total': 'Total',
      'CHECKOUT': 'PASSER LA COMMANDE',
      'Order placed! Thank you.':
          'Commande passée ! Merci.',

      // Subscription
      'FixMate Subscription': 'Abonnement FixMate',
      'Your technician account includes a 7-day free trial.':
          'Votre compte technicien comprend un essai gratuit de 7 jours.',
      'Choose the plan that works best for your business.':
          'Choisissez le forfait qui convient le mieux à votre activité.',
      'Monthly': 'Mensuel',
      'Flexible monthly subscription.':
          'Abonnement mensuel flexible.',
      'month': 'mois',
      'Annual': 'Annuel',
      'Best value for long-term users.':
          'Meilleur rapport qualité-prix pour une utilisation à long terme.',
      'year': 'an',
      'RECOMMENDED': 'RECOMMANDÉ',
      'Payment methods': 'Modes de paiement',
      'MTN Mobile Money': 'MTN Mobile Money',
      'Orange Money': 'Orange Money',
      'Visa / Card': 'Visa / Carte',
      'Bank': 'Banque',
      'SUBSCRIBE': "S'ABONNER",
      'Please choose a subscription plan.': 'Veuillez choisir un forfait d abonnement.',
      'Please choose a payment method.': 'Veuillez choisir un mode de paiement.',

      // Profile
      'My Profile': 'Mon profil',
      'FixMate User': 'Utilisateur FixMate',
      'Edit Profile': 'Modifier le profil',
      'Phone Numbers': 'Numéros de téléphone',
      'Change Password': 'Modifier le mot de passe',
      'Verification & Documents': 'Vérification et documents',
      'My Ratings': 'Mes évaluations',
      'My Activity': 'Mon activité',
      'LOG OUT': 'SE DÉCONNECTER',
        'Services provided': 'Services proposés',
        'Request this technician': 'Demander ce technicien',
        'Describe the service you need.':
          'Décrivez le service dont vous avez besoin.',
        'Please describe the service you need.':
          'Veuillez décrire le service dont vous avez besoin.',
        'Service request sent successfully.':
          'Demande de service envoyée avec succès.',
        'REQUEST SERVICE': 'DEMANDER LE SERVICE',
        'Choose profile picture': 'Choisir une photo de profil',
        'Choose from device': 'Choisir depuis l appareil',
        'Take a photo': 'Prendre une photo',

      // Language/theme
      'Light mode': 'Mode clair',
      'Dark mode': 'Mode sombre',
      'Language': 'Langue',
      'Search...': 'Rechercher...',

      // Services
      'Refrigeration & Air Conditioning':
          'Réfrigération et climatisation',
      'Phone Repairs': 'Réparation de téléphones',
      'Carpentry': 'Menuiserie',
      'Painting': 'Peinture',
      'Welding': 'Soudure',
      'Masonry': 'Maçonnerie',
      'Tiling': 'Carrelage',
      'Fenestration': 'Fenêtres et portes',
      'Home Appliance Repair':
          "Réparation d'appareils électroménagers",
      'Computer & IT Tools Repair':
          'Réparation informatique et équipements IT',
      'Audio Repair': 'Réparation audio',
      'Electronics Repair': 'Réparation électronique',
      'Solar Maintenance & Repair':
          'Maintenance et réparation solaire',

      // Supplier categories
      'Electrical Materials': 'Matériel électrique',
      'Plumbing Materials': 'Matériel de plomberie',
      'Refrigeration Equipment': 'Équipement de réfrigération',
      'Air Conditioning Equipment': 'Équipement de climatisation',
      'Phone Parts': 'Pièces de téléphone',
      'Carpentry Materials': 'Matériaux de menuiserie',
      'Paint': 'Peinture',
      'Welding Equipment': 'Équipement de soudage',
      'Masonry Materials': 'Matériaux de maçonnerie',
      'Tiles': 'Carrelage',
      'Windows & Doors': 'Fenêtres et portes',
      'Auto Parts': 'Pièces automobiles',
      'Home Appliances': 'Appareils électroménagers',
      'Computers': 'Ordinateurs',
      'IT Equipment': 'Équipement informatique',
      'Audio Equipment': 'Équipement audio',
      'Electronic Components': 'Composants électroniques',
      'Solar Equipment': 'Équipement solaire',
      'Tools': 'Outils',
      'Safety Equipment': 'Équipement de sécurité',
      'Other': 'Autre',

      // Demo technicians
      'Electricity/Solar': 'Électricité/Solaire',
      'Plumbing/Masonry': 'Plomberie/Maçonnerie',
      'Phone Repairs/Electronics':
          'Réparation de téléphones/Électronique',
    };

    String result = language == 'Français'
        ? (french[key] ?? key)
        : key;

    params?.forEach((name, value) {
      result = result.replaceAll('{$name}', value);
    });

    return result;
  }

  // ----------------------------------------------------------
  // SETTINGS
  // ----------------------------------------------------------

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final dark = prefs.getBool('darkMode') ?? false;
    final savedLanguage = prefs.getString('language') ?? 'English';
    final savedRole = prefs.getString('userRole') ?? '';
    final savedIdentifier = prefs.getString('loginIdentifier') ?? '';

    themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    language = savedLanguage;
    userRole = savedRole;
    loginIdentifier = savedIdentifier;
    loggedIn = savedRole.isNotEmpty && savedIdentifier.isNotEmpty;

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'darkMode',
      themeMode == ThemeMode.dark,
    );

    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    language = language == 'English' ? 'Français' : 'English';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);

    notifyListeners();
  }

  // ----------------------------------------------------------
  // AUTH
  // ----------------------------------------------------------

  void login(String role) {
    userRole = role;
    loggedIn = true;
    profileName = role == 'Supplier'
      ? 'FixMate Supplies'
      : role == 'Technician'
        ? 'Jean Michel Mbarga'
        : role == 'Admin'
          ? 'FixMate Admin'
          : 'FixMate User';
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

  // ----------------------------------------------------------
  // CART
  // ----------------------------------------------------------

  int get cartCount {
    return cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  double get cartTotal {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  void addToCart(Product product) {
    final index = cartItems.indexWhere(
      (item) => item.name == product.name,
    );

    if (index >= 0) {
      cartItems[index].quantity++;
    } else {
      cartItems.add(
        CartItem(
          name: product.name,
          price: product.price,
          supplierName: product.supplierName,
        ),
      );
    }

    activities.add('Added ${product.name} from ${product.supplierName} to cart');

    notifyListeners();
  }

  void completePurchase() {
    if (cartItems.isEmpty) return;
    for (final item in cartItems) {
      supplierNotifications.add(
        'New purchase: ${item.quantity} × ${item.name} from ${item.supplierName}',
      );
    }
    activities.add('Purchased ${cartItems.length} product(s)');
    cartItems.clear();
    notifyListeners();
  }

  void publishProduct(Product product) {
    products.add(product);
    activities.add('Posted ${product.name} for sale');
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required String phone,
    required String location,
  }) {
    profileName = name;
    profileEmail = email;
    profilePhone = phone;
    profileLocation = location;
    activities.add('Updated profile information');
    notifyListeners();
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

  void removeFromCart(String name) {
    cartItems.removeWhere(
      (item) => item.name == name,
    );

    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }
}

// ============================================================
// MODELS
// ============================================================

class CartItem {
  final String name;
  final double price;
  final String supplierName;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.supplierName,
    this.quantity = 1,
  });
}

class Product {
  final String name;
  final double price;
  final String supplierName;
  final bool supplierCertified;
  final IconData icon;

  Product({
    required this.name,
    required this.price,
    this.supplierName = 'FixMate Supplies',
    this.supplierCertified = true,
    this.icon = Icons.build,
  });
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

class TechnicianData {
  final String name;
  final List<String> services;
  final String region;
  final String town;
  final double rating;
  final int jobs;
  final bool certified;
  final String imagePath;

  const TechnicianData({
    required this.name,
    required this.services,
    required this.region,
    required this.town,
    required this.rating,
    required this.jobs,
    required this.certified,
    required this.imagePath,
  });
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

// ============================================================
// APP
// ============================================================

class FixMateApp extends StatefulWidget {
  const FixMateApp({super.key});

  @override
  State<FixMateApp> createState() => _FixMateAppState();
}

class _FixMateAppState extends State<FixMateApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'FixMate',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: FixMateTheme.lightTheme,
          darkTheme: FixMateTheme.darkTheme,
          home: const SplashScreen(),
          builder: (context, child) => ConnectivityWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

// ============================================================
// THEME
// ============================================================

class FixMateTheme {
  static const Color gold = Color(0xFFB58A3A);
  static const Color darkGold = Color(0xFF8D6828);
  static const Color darkBackground = Color(0xFF101010);
  static const Color darkCard = Color(0xFF1B1B1B);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8F6F1),
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: darkCard,
      elevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// ============================================================
// SPLASH
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.forward();

    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        final destination = context.read<AppState>().loggedIn
            ? const MainNavigation()
            : const LoginPage();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => destination,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: const FixMateLogo(size: 150),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGO
// ============================================================

class FixMateLogo extends StatelessWidget {
  final double size;

  const FixMateLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return Icon(
          Icons.handyman,
          size: size * .7,
          color: FixMateTheme.gold,
        );
      },
    );
  }
}

// ============================================================
// LANGUAGE BUTTON
// ============================================================

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return TextButton(
      onPressed: state.toggleLanguage,
      child: Text(
        state.language == 'English'
            ? 'EN | FR'
            : 'FR | EN',
        style: const TextStyle(
          color: FixMateTheme.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// THEME BUTTON
// ============================================================

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    final isDark =
        state.themeMode == ThemeMode.dark;

    return IconButton(
      onPressed: state.toggleTheme,
      tooltip: isDark
          ? t('Light mode')
          : t('Dark mode'),
      icon: Icon(
        isDark
            ? Icons.light_mode
            : Icons.dark_mode,
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final identifierController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void demoLogin() {
    final t = context.read<AppState>().tr;

    if (identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Please enter your email, phone number or name.',
            ),
          ),
        ),
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Please enter your password.'),
          ),
        ),
      );
      return;
    }

    context.read<AppState>().loginIdentifier =
      identifierController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RoleSelectionForLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: const [
                  LanguageButton(),
                  ThemeButton(),
                ],
              ),

              const SizedBox(height: 20),

              const FixMateLogo(size: 170),

              const SizedBox(height: 25),

              Text(
                t('Welcome to FixMate'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 10),

              Text(
                t(
                  'Your trusted technician marketplace',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),

              const SizedBox(height: 35),

              TextField(
                controller: identifierController,
                decoration: InputDecoration(
                  labelText: t(
                    'Email, phone number or name',
                  ),
                  prefixIcon:
                      const Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t('Password'),
                  prefixIcon:
                      const Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t('Password reset instructions sent.'),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    t('Forgot password?'),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: demoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        FixMateTheme.gold,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    t('LOG IN'),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    t("Don't have an account?"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SignupRoleSelectionPage(),
                        ),
                      );
                    },
                    child: Text(
                      t('Sign up'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN ROLE SELECTION
// ============================================================

class RoleSelectionForLoginPage
    extends StatelessWidget {
  const RoleSelectionForLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('Select account type'),
        ),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              t('Demo login'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              t(
                'Until Firebase authentication is connected, select the type of account you want to test.',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            RoleCard(
              icon: Icons.person,
              title: t('Customer'),
              description: t(
                'Find technicians and purchase products.',
              ),
              onTap: () {
                state.login('Customer');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.handyman,
              title: t('Technician'),
              description: t(
                'Offer services and receive customer requests.',
              ),
              onTap: () {
                state.login('Technician');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.store,
              title: t('Supplier'),
              description: t(
                'Sell tools, parts and equipment.',
              ),
              onTap: () {
                state.login('Supplier');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MainNavigation(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.shield_outlined,
              title: t('Admin'),
              description: t(
                'Manage platform operations and approvals.',
              ),
              onTap: () {
                state.login('Admin');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigation(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP ROLE SELECTION
// ============================================================

class SignupRoleSelectionPage
    extends StatelessWidget {
  const SignupRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('Create your account'),
        ),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              t('I want to register as:'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            RoleCard(
              icon: Icons.person,
              title: t('Customer'),
              description: t(
                'Request technicians and purchase products.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CustomerSignupPage(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.handyman,
              title: t('Technician'),
              description: t(
                'Provide professional repair and maintenance services.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TechnicianSignupPage(),
                  ),
                );
              },
            ),

            RoleCard(
              icon: Icons.store,
              title: t('Supplier'),
              description: t(
                'Sell tools, equipment, spare parts and materials.',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SupplierSignupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROLE CARD
// ============================================================

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    FixMateTheme.gold.withValues(
                  alpha: .15,
                ),
                child: Icon(
                  icon,
                  color: FixMateTheme.gold,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(description),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP HELPERS
// ============================================================

class SignupScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SignupScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class SignupHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SignupHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FixMateLogo(size: 80),

        const SizedBox(height: 15),

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 25),
      ],
    );
  }
}

class SignupField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const SignupField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;

  const PasswordField({
    super.key,
    required this.label,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.lock_outline),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;

  const DropdownField({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: 'Option',
        decoration: InputDecoration(
          labelText: label,
        ),
        items: [
          DropdownMenuItem(
            value: 'Option',
            child: Text(t('Select')),
          ),
        ],
        onChanged: (_) {},
      ),
    );
  }
}

class SignupButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SignupButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FixMateTheme.gold,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

// ============================================================
// CUSTOMER SIGNUP
// ============================================================

class CustomerSignupPage
    extends StatefulWidget {
  const CustomerSignupPage({super.key});

  @override
  State<CustomerSignupPage> createState() =>
      _CustomerSignupPageState();
}

class _CustomerSignupPageState
    extends State<CustomerSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword =
      TextEditingController();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void register() {
    final state = context.read<AppState>();
    final t = state.tr;

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Passwords do not match.'),
          ),
        ),
      );
      return;
    }

    state.login('Customer');
    state.updateProfile(
      name: '${firstName.text.trim()} ${lastName.text.trim()}'.trim(),
      email: email.text.trim().isEmpty
        ? state.profileEmail
        : email.text.trim(),
      phone: phone.text.trim().isEmpty
        ? state.profilePhone
        : phone.text.trim(),
      location: state.profileLocation,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return SignupScaffold(
      title: t('Customer Registration'),
      children: [
        SignupHeader(
          title: t('Create customer account'),
          subtitle: t(
            'Find trusted technicians and buy products on FixMate.',
          ),
        ),

        SignupField(
          label: t('First name'),
          controller: firstName,
        ),

        SignupField(
          label: t('Last name'),
          controller: lastName,
        ),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType:
              TextInputType.emailAddress,
        ),

        PasswordField(
          label: t('Password'),
          controller: password,
        ),

        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),

        const SizedBox(height: 10),

        SignupButton(
          text: t('CREATE CUSTOMER ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}

// ============================================================
// TECHNICIAN SIGNUP
// ============================================================

class TechnicianSignupPage
    extends StatefulWidget {
  const TechnicianSignupPage({super.key});

  @override
  State<TechnicianSignupPage> createState() =>
      _TechnicianSignupPageState();
}

class _TechnicianSignupPageState
    extends State<TechnicianSignupPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword =
      TextEditingController();

  final Set<String> selectedServices = {};

  final List<String> services = [
    'Electricity',
    'Plumbing',
    'Refrigeration & Air Conditioning',
    'Phone Repairs',
    'Carpentry',
    'Painting',
    'Welding',
    'Masonry',
    'Tiling',
    'Fenestration',
    'Auto Repair',
    'Home Appliance Repair',
    'Computer & IT Tools Repair',
    'Audio Repair',
    'Electronics Repair',
    'Solar Maintenance & Repair',
  ];

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void register() {
    final state = context.read<AppState>();
    final t = state.tr;

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Please select at least one service.'),
          ),
        ),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Passwords do not match.'),
          ),
        ),
      );
      return;
    }

    state.login('Technician');
    state.updateProfile(
      name: '${firstName.text.trim()} ${lastName.text.trim()}'.trim(),
      email: email.text.trim().isEmpty
        ? state.profileEmail
        : email.text.trim(),
      phone: phone.text.trim().isEmpty
        ? state.profilePhone
        : phone.text.trim(),
      location: state.profileLocation,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupScaffold(
      title: t('Technician Registration'),
      children: [
        SignupHeader(
          title: t('Create technician account'),
          subtitle: t(
            'Offer your professional services to customers.',
          ),
        ),

        SignupField(
          label: t('First name'),
          controller: firstName,
        ),

        SignupField(
          label: t('Last name'),
          controller: lastName,
        ),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType:
              TextInputType.emailAddress,
        ),

        PasswordField(
          label: t('Password'),
          controller: password,
        ),

        PasswordField(
          label: t('Confirm password'),
          controller: confirmPassword,
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t('Services you provide'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((service) {
            final selected =
                selectedServices.contains(service);

            return FilterChip(
              label: Text(t(service)),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selectedServices.add(service);
                  } else {
                    selectedServices.remove(service);
                  }
                });
              },
              selectedColor:
                  FixMateTheme.gold.withValues(
                alpha: .25,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        SignupButton(
          text: t('CREATE TECHNICIAN ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}

// ============================================================
// SUPPLIER SIGNUP
// ============================================================

class SupplierSignupPage
    extends StatefulWidget {
  const SupplierSignupPage({super.key});

  @override
  State<SupplierSignupPage> createState() =>
      _SupplierSignupPageState();
}

class _SupplierSignupPageState
    extends State<SupplierSignupPage> {
  final company = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final additionalPhone =
      TextEditingController();

  final Set<String> selectedItems = {};

  final List<String> categories = [
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

  @override
  void dispose() {
    company.dispose();
    email.dispose();
    phone.dispose();
    additionalPhone.dispose();
    super.dispose();
  }

  void register() {
    final state = context.read<AppState>();
    final t = state.tr;

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Please select at least one item category.',
            ),
          ),
        ),
      );
      return;
    }

    state.login('Supplier');
    state.updateProfile(
      name: company.text.trim().isEmpty
        ? state.profileName
        : company.text.trim(),
      email: email.text.trim().isEmpty
        ? state.profileEmail
        : email.text.trim(),
      phone: phone.text.trim().isEmpty
        ? state.profilePhone
        : phone.text.trim(),
      location: state.profileLocation,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SignupScaffold(
      title: t('Supplier Registration'),
      children: [
        SignupHeader(
          title: t('Create supplier account'),
          subtitle: t(
            'Sell tools, equipment, spare parts and materials.',
          ),
        ),

        SignupField(
          label: t('Company name'),
          controller: company,
        ),

        SignupField(
          label: t('Email'),
          controller: email,
          keyboardType:
              TextInputType.emailAddress,
        ),

        SignupField(
          label: t('Phone number'),
          controller: phone,
          keyboardType: TextInputType.phone,
        ),

        SignupField(
          label: t('Additional phone number'),
          controller: additionalPhone,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t('Items you supply'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((item) {
            final selected =
                selectedItems.contains(item);

            return FilterChip(
              label: Text(t(item)),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
              selectedColor:
                  FixMateTheme.gold.withValues(
                alpha: .25,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        DropdownField(
          label: t('Location'),
        ),

        DropdownField(
          label: t('Region'),
        ),

        DropdownField(
          label: t('Town'),
        ),

        const SizedBox(height: 5),

        Text(
          t(
            'Business verification documents can be submitted after registration.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),

        const SizedBox(height: 20),

        SignupButton(
          text: t('CREATE SUPPLIER ACCOUNT'),
          onPressed: register,
        ),
      ],
    );
  }
}

// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isBusinessRole =
        state.userRole == 'Technician' ||
        state.userRole == 'Supplier';
    final isAdmin = state.userRole == 'Admin';

    final pages = isAdmin
        ? const [
            AdminDashboardPage(),
            ProfilePage(),
          ]
        : isBusinessRole
          ? const [
              HomePage(),
              ShopPage(),
              SubscriptionPage(),
              ProfilePage(),
            ]
          : const [
              HomePage(),
              TechniciansPage(),
              ShopPage(),
              ProfilePage(),
            ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: FixMateBottomNavigation(
        currentIndex: currentIndex,
        isBusinessRole: isBusinessRole,
        isAdmin: isAdmin,
        onChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class FixMateBottomNavigation
    extends StatelessWidget {
  final int currentIndex;
  final bool isBusinessRole;
  final bool isAdmin;
  final ValueChanged<int> onChanged;

  const FixMateBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.isBusinessRole,
    required this.isAdmin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    final labels = isAdmin
        ? [
            t('Dashboard'),
            t('Profile'),
          ]
        : isBusinessRole
          ? [
              t('Home'),
              t('Shop'),
              t('Subscription'),
              t('Profile'),
            ]
          : [
              t('Home'),
              t('Technicians'),
              t('Shop'),
              t('Profile'),
            ];

    final icons = isAdmin
        ? [
            Icons.dashboard_outlined,
            Icons.person_outline,
          ]
        : isBusinessRole
          ? [
              Icons.home_outlined,
              Icons.shopping_bag_outlined,
              Icons.card_membership_outlined,
              Icons.person_outline,
            ]
          : [
              Icons.home_outlined,
              Icons.handyman_outlined,
              Icons.shopping_bag_outlined,
              Icons.person_outline,
            ];

    final selectedIcons = isAdmin
        ? [
            Icons.dashboard,
            Icons.person,
          ]
        : isBusinessRole
          ? [
              Icons.home,
              Icons.shopping_bag,
              Icons.card_membership,
              Icons.person,
            ]
          : [
              Icons.home,
              Icons.handyman,
              Icons.shopping_bag,
              Icons.person,
            ];

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      destinations: List.generate(
        labels.length,
        (index) {
          return NavigationDestination(
            icon: Icon(icons[index]),
            selectedIcon: Icon(selectedIcons[index]),
            label: labels[index],
          );
        },
      ),
    );
  }
}

// ============================================================
// APP BAR
// ============================================================

class FixMateAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final List<String> suggestions;

  const FixMateAppBar({
    super.key,
    required this.title,
    this.suggestions = const [],
  });

  @override
  State<FixMateAppBar> createState() =>
      _FixMateAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}

class _FixMateAppBarState
    extends State<FixMateAppBar> {
  bool searchOpen = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return AppBar(
      title: searchOpen
          ? TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.suggestions.isEmpty
                    ? t('Search...')
                    : widget.suggestions
                        .map(t)
                        .join(' • '),
                border: InputBorder.none,
              ),
            )
          : Text(widget.title),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              searchOpen = !searchOpen;
            });
          },
          icon: Icon(
            searchOpen
                ? Icons.close
                : Icons.search,
          ),
        ),
        const LanguageButton(),
        const ThemeButton(),
      ],
    );
  }
}

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    final stats = [
      _StatCard(label: t('Pending approvals'), value: '24', icon: Icons.pending_actions_outlined),
      _StatCard(label: t('Active technicians'), value: '1,248', icon: Icons.handyman_outlined),
      _StatCard(label: t('Monthly revenue'), value: '₣ 4.8M', icon: Icons.attach_money_outlined),
      _StatCard(label: t('Open disputes'), value: '08', icon: Icons.report_problem_outlined),
    ];

    final actions = [
      _QuickActionTile(title: t('Review supplier requests'), icon: Icons.storefront_outlined),
      _QuickActionTile(title: t('Verify technician profiles'), icon: Icons.verified_user_outlined),
      _QuickActionTile(title: t('Resolve customer complaints'), icon: Icons.support_agent_outlined),
      _QuickActionTile(title: t('View analytics'), icon: Icons.analytics_outlined),
    ];

    final activity = [
      t('New supplier onboarding'),
      t('Technician verification complete'),
      t('Payment dispute escalated'),
      t('Campaign promotion approved'),
    ];

    return Scaffold(
      appBar: FixMateAppBar(title: t('Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Platform overview'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                t('Manage platform operations and approvals.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: stats.map((item) => item).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                t('Quick actions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...actions.map(
                (action) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: FixMateTheme.gold.withValues(alpha: 0.15),
                      child: Icon(action.icon, color: FixMateTheme.gold),
                    ),
                    title: Text(action.title),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('Recent platform activity'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...activity.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: FixMateTheme.gold),
                    title: Text(entry),
                    trailing: TextButton(
                      onPressed: () {},
                      child: Text(t('Approve')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FixMateTheme.gold, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile {
  final String title;
  final IconData icon;

  const _QuickActionTile({
    required this.title,
    required this.icon,
  });
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          25,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FixMateLogo(size: 55),
                const Spacer(),
                const LanguageButton(),
                const ThemeButton(),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Text(
                    t(
                      'Your trusted technician marketplace',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    t(
                      'Find technicians, buy tools and equipment, and get your problems solved.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    FixMateTheme.gold,
                    FixMateTheme.darkGold,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Need a technician?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    t(
                      'Find a professional near you.',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TechniciansPage(),
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          FixMateTheme.darkGold,
                    ),
                    child: Text(
                      t('Find a Technician'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              t('Popular Services'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                ServiceTile(
                  icon: Icons.bolt,
                  title: t('Electricity'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TechniciansPage(
                        initialService: 'Electricity',
                      ),
                    ),
                  ),
                ),
                ServiceTile(
                  icon: Icons.water_drop,
                  title: t('Plumbing'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Plumbing'))),
                ),
                ServiceTile(
                  icon: Icons.ac_unit,
                  title:
                      t('AC & Refrigeration'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Refrigeration & Air Conditioning'))),
                ),
                ServiceTile(
                  icon: Icons.phone_android,
                  title: t('Phone Repair'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Phone Repairs'))),
                ),
                ServiceTile(
                  icon: Icons.computer,
                  title: t('Computer Repair'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Computer & IT Tools Repair'))),
                ),
                ServiceTile(
                  icon: Icons.wb_sunny,
                  title: t('Solar'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Solar'))),
                ),
                ServiceTile(
                  icon: Icons.directions_car,
                  title: t('Auto Repair'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Auto Repair'))),
                ),
                ServiceTile(
                  icon: Icons.home_work,
                  title: t('Appliances'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechniciansPage(initialService: 'Home Appliance Repair'))),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              t('How FixMate works'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 15),

            HowItWorksStep(
              number: '1',
              title: t('Find'),
              description: t(
                'Find a technician or product.',
              ),
            ),

            HowItWorksStep(
              number: '2',
              title: t('Request'),
              description: t(
                'Describe your problem and location.',
              ),
            ),

            HowItWorksStep(
              number: '3',
              title: t('Get it fixed'),
              description: t(
                'Your technician comes to you.',
              ),
            ),

            HowItWorksStep(
              number: '4',
              title: t('Rate'),
              description: t(
                'Rate your experience.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SERVICE TILE
// ============================================================

class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: FixMateTheme.gold,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOW IT WORKS
// ============================================================

class HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const HowItWorksStep({
    super.key,
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                FixMateTheme.gold,
            foregroundColor: Colors.white,
            child: Text(number),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TECHNICIANS PAGE
// ============================================================

class TechniciansPage extends StatefulWidget {
  final String? initialService;

  const TechniciansPage({super.key, this.initialService});

  @override
  State<TechniciansPage> createState() => _TechniciansPageState();
}

class _TechniciansPageState extends State<TechniciansPage> {
  String? selectedService;
  String? selectedTown;

  static const regions = <String, List<String>>{
    'Littoral': ['Douala', 'Nkongsamba', 'Edéa'],
    'Centre': ['Yaoundé', 'Mbalmayo', 'Obala'],
    'West': ['Bafoussam', 'Dschang', 'Bamendjou'],
    'Southwest': ['Buea', 'Limbe', 'Kumba'],
    'Northwest': ['Bamenda'],
    'South': ['Ebolowa', 'Kribi'],
    'East': ['Bertoua'],
    'North': ['Garoua', 'Maroua'],
    'Adamawa': ['Ngaoundéré'],
  };

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialService;
  }

  List<TechnicianData> get filteredTechnicians {
    return technicians.where((technician) {
      final serviceMatches = selectedService == null ||
          technician.services.contains(selectedService);
      final locationMatches = selectedTown == null ||
          technician.town == selectedTown;
      return serviceMatches && locationMatches;
    }).toList();
  }

  Future<void> chooseService() async {
    final state = context.read<AppState>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(state.tr('All services')),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...technicians
                .expand((technician) => technician.services)
                .toSet()
                .map(
                  (service) => ListTile(
                    title: Text(state.tr(service)),
                    onTap: () => Navigator.pop(context, service),
                  ),
                ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => selectedService = choice.isEmpty ? null : choice);
  }

  Future<void> chooseLocation() async {
    final region = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: regions.entries
              .map(
                (entry) => ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value
                      .map(
                        (town) => ListTile(
                          title: Text(town),
                          onTap: () => Navigator.pop(context, town),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (!mounted || region == null) return;
    setState(() => selectedTown = region);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final results = filteredTechnicians;

    return Scaffold(
      appBar: FixMateAppBar(title: t('Technicians')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: chooseService,
                  icon: const Icon(Icons.handyman_outlined),
                  label: Text(selectedService == null ? t('Service') : t(selectedService!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: chooseLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(selectedTown ?? t('Location')),
                ),
              ),
            ],
          ),
          if (selectedService != null || selectedTown != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  selectedService = null;
                  selectedTown = null;
                }),
                child: Text(t('Clear filters')),
              ),
            ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text(t('No technicians found.'))),
            )
          else
            ...results.map(
              (technician) => TechnicianCard(
                name: technician.name,
                services: technician.services,
                location: technician.town,
                rating: technician.rating,
                jobs: technician.jobs,
                certified: technician.certified,
                imagePath: technician.imagePath,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER BAR
// ============================================================


// ============================================================
// TECHNICIAN CARD
// ============================================================

class TechnicianCard extends StatelessWidget {
  final String name;
  final List<String> services;
  final String location;
  final double rating;
  final int jobs;
  final bool certified;
  final String imagePath;

  const TechnicianCard({
    super.key,
    required this.name,
    required this.services,
    required this.location,
    required this.rating,
    required this.jobs,
    required this.certified,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(imagePath),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          if (certified)
                            const CertifiedBadge(),
                        ],
                      ),

                      const SizedBox(height: 5),

                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(location),

                const Spacer(),

                const Icon(
                  Icons.star,
                  size: 18,
                  color: FixMateTheme.gold,
                ),

                const SizedBox(width: 4),

                Text(
                  rating.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              services.map(t).join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '$jobs ${t('jobs completed')}',
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicianProfilePage(
                        name: name,
                        services: services,
                        location: location,
                        rating: rating,
                        jobs: jobs,
                        certified: certified,
                        imagePath: imagePath,
                      ),
                    ),
                  );
                },
                child: Text(
                  t('VIEW PROFILE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CertifiedBadge extends StatelessWidget {
  const CertifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Certified',
      child: Icon(
        Icons.verified,
        color: Colors.blue,
        size: 23,
      ),
    );
  }
}

// ============================================================
// TECHNICIAN PROFILE
// ============================================================

class TechnicianProfilePage extends StatefulWidget {
  final String name;
  final List<String> services;
  final String location;
  final double rating;
  final int jobs;
  final bool certified;
  final String imagePath;

  const TechnicianProfilePage({
    super.key,
    required this.name,
    required this.services,
    required this.location,
    required this.rating,
    required this.jobs,
    required this.certified,
    required this.imagePath,
  });

  @override
  State<TechnicianProfilePage> createState() =>
      _TechnicianProfilePageState();
}

class _TechnicianProfilePageState
    extends State<TechnicianProfilePage> {
  late String selectedService;
  final detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedService = widget.services.first;
  }

  @override
  void dispose() {
    detailsController.dispose();
    super.dispose();
  }

  void requestService() {
    final t = context.read<AppState>().tr;

    if (detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Please describe the service you need.'),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${t('Service request sent successfully.')} ${t(selectedService)}',
        ),
      ),
    );
    context.read<AppState>().recordActivity(
          'Requested ${t(selectedService)} from ${widget.name}',
        );
    detailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 46,
                backgroundImage: AssetImage(widget.imagePath),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.certified) ...[
                  const SizedBox(width: 5),
                  const CertifiedBadge(),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${widget.location}  •  ${widget.rating} ★  •  ${widget.jobs} ${t('jobs completed')}',
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.certified) ...[
              const SizedBox(height: 12),
              Center(
                child: Chip(
                  avatar: const Icon(Icons.verified, size: 18),
                  label: Text(t('Certified')),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              t('Services provided'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.services
                  .map((service) => Chip(label: Text(t(service))))
                  .toList(),
            ),
            const SizedBox(height: 28),
            Text(
              t('Request this technician'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedService,
              decoration: InputDecoration(
                labelText: t('Service'),
              ),
              items: widget.services
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(t(service)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedService = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: t('Describe the service you need.'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: requestService,
                icon: const Icon(Icons.send),
                label: Text(t('REQUEST SERVICE')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FixMateTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHOP PAGE
// ============================================================

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: FixMateAppBar(
        title: t('Shop'),
        suggestions: [
          'Search products',
          'tools',
          'suppliers',
          'categories',
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('Products & Tools'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),

                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CartPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                      ),
                    ),

                    if (state.cartCount > 0)
                      Positioned(
                        right: 5,
                        top: 3,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor:
                              FixMateTheme.gold,
                          foregroundColor:
                              Colors.white,
                          child: Text(
                            '${state.cartCount}',
                            style:
                                const TextStyle(
                              fontSize: 10,
                            ),
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
            const SizedBox(height: 12),
            ...state.catalogProducts.map(
              (product) =>
                  ProductCard(product: product),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCT CARD
// ============================================================

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: FixMateTheme.gold
                    .withValues(alpha: .12),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                product.icon,
                color: FixMateTheme.gold,
                size: 35,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    t(product.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

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
                ],
              ),
            ),

            IconButton(
              onPressed: () {
                state.addToCart(product);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '${t(product.name)} - ${t('ADD TO CART')}',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.add_shopping_cart,
              ),
              color: FixMateTheme.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CART PAGE
// ============================================================

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('My Cart')),
        actions: const [
          LanguageButton(),
          ThemeButton(),
        ],
      ),
      body: state.cartItems.isEmpty
          ? Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons
                          .remove_shopping_cart_outlined,
                      size: 70,
                      color: FixMateTheme.gold,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t('Your cart is empty.'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(
                        'Add products from the shop.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        state.cartItems.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                          state.cartItems[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.build,
                            color:
                                FixMateTheme.gold,
                          ),
                          title: Text(
                            t(item.name),
                          ),
                          subtitle: Text(
                            '${item.quantity} × ${formatPrice(item.price)}',
                          ),
                          trailing: Text(
                            formatPrice(
                              item.price *
                                  item.quantity,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            t('Total'),
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatPrice(
                              state.cartTotal,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  FixMateTheme.gold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (state.cartItems
                                .isEmpty) {
                              ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t(
                                      'Your cart is empty.',
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }

                            state.completePurchase();

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  t(
                                    'Order placed! Thank you.',
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton
                              .styleFrom(
                            backgroundColor:
                                FixMateTheme.gold,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            t('CHECKOUT'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// SUBSCRIPTION PAGE
// ============================================================

class SubscriptionPage
    extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? selectedPlan;
  String? selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final isSupplier = state.userRole == 'Supplier';
    final monthlyPrice = isSupplier ? '20,000 FCFA' : '5,000 FCFA';
    final annualPrice = isSupplier ? '200,000 FCFA' : '50,000 FCFA';

    final description =
        state.userRole == 'Technician'
            ? t(
                'Your technician account includes a 7-day free trial.',
              )
            : t(
                'Choose the plan that works best for your business.',
              );

    return Scaffold(
      appBar: FixMateAppBar(
        title: t('FixMate Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              description,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            SubscriptionCard(
              title: t('Monthly'),
              description: t(
                'Flexible monthly subscription.',
              ),
              price: monthlyPrice,
              period: t('month'),
              selected: selectedPlan == 'monthly',
              onTap: () => setState(() => selectedPlan = 'monthly'),
            ),

            SubscriptionCard(
              title: t('Annual'),
              description: t(
                'Best value for long-term users.',
              ),
              price: annualPrice,
              period: t('year'),
              recommended: true,
              selected: selectedPlan == 'annual',
              onTap: () => setState(() => selectedPlan = 'annual'),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t('Payment methods'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in [
                  'MTN Mobile Money',
                  'Orange Money',
                  'Visa / Card',
                  'Bank',
                ])
                  ChoiceChip(
                    label: Text(t(method)),
                    selected: selectedPaymentMethod == method,
                    onSelected: (_) => setState(
                      () => selectedPaymentMethod = method,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedPlan == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('Please choose a subscription plan.')),
                      ),
                    );
                    return;
                  }
                  if (selectedPaymentMethod == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('Please choose a payment method.')),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t('Subscription request received.'),
                      ),
                    ),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      FixMateTheme.gold,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
                child: Text(
                  t('SUBSCRIBE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUBSCRIPTION CARD
// ============================================================

class SubscriptionCard
    extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String period;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? FixMateTheme.gold : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? FixMateTheme.gold : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (recommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          FixMateTheme.gold,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Text(
                      t('RECOMMENDED'),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(description),

            const SizedBox(height: 15),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: FixMateTheme.gold,
                  ),
                ),
                const SizedBox(width: 5),
                Text('/ $period'),
              ],
            ),
            ],
          ),
        ),
      ),
    )
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    final isBusinessRole =
        state.userRole == 'Technician' ||
        state.userRole == 'Supplier';

    return Scaffold(
      appBar: FixMateAppBar(
        title: t('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            state.profileImageBytes == null
                ? const CircleAvatar(
                    radius: 45,
                    backgroundColor: FixMateTheme.gold,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  )
                : CircleAvatar(
                    radius: 45,
                    backgroundImage: MemoryImage(state.profileImageBytes!),
                  ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.profileName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isBusinessRole) ...[
                  const SizedBox(width: 5),
                  const CertifiedBadge(),
                ],
              ],
            ),

            const SizedBox(height: 6),

            Chip(
              label: Text(
                t(state.userRole),
              ),
            ),

            const SizedBox(height: 25),

            AccountDetails(state: state, t: t),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
                icon: const Icon(Icons.edit),
                label: Text(t('Edit Profile')),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityPage()),
                ),
                icon: const Icon(Icons.history),
                label: Text(t('My Activity')),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  state.logout();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginPage(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout,
                ),
                label: Text(
                  t('LOG OUT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountDetails extends StatelessWidget {
  final AppState state;
  final String Function(String) t;

  const AccountDetails({super.key, required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detailRow(Icons.email_outlined, 'Email', state.profileEmail),
            _detailRow(Icons.phone_outlined, 'Tel', state.profilePhone),
            _detailRow(Icons.location_on_outlined, 'Location', state.profileLocation),
            _detailRow(Icons.star_outline, 'My ratings', state.profileRating.toString()),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: FixMateTheme.gold),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;
  final passwordController = TextEditingController();
  bool showPhotoOptions = false;

  Future<void> pickProfileImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
    );
    if (!mounted || image == null) return;
    context.read<AppState>().updateProfileImage(await image.readAsBytes());
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    nameController = TextEditingController(text: state.profileName);
    emailController = TextEditingController(text: state.profileEmail);
    phoneController = TextEditingController(text: state.profilePhone);
    locationController = TextEditingController(text: state.profileLocation);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppState>().tr;
    return Scaffold(
      appBar: AppBar(title: Text(t('Edit Profile'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Consumer<AppState>(
                      builder: (context, state, _) {
                        if (state.profileImageBytes == null) {
                          return const CircleAvatar(
                            radius: 48,
                            child: Icon(Icons.person, size: 48),
                          );
                        }
                        return CircleAvatar(
                          radius: 48,
                          backgroundImage:
                              MemoryImage(state.profileImageBytes!),
                        );
                      },
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: () => setState(
                          () => showPhotoOptions = !showPhotoOptions,
                        ),
                        icon: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
                if (showPhotoOptions) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 230,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .6),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.photo_library_outlined,
                              ),
                              title: Text(t('Choose from device')),
                              onTap: () => pickProfileImage(
                                ImageSource.gallery,
                              ),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.camera_alt_outlined,
                              ),
                              title: Text(t('Take a photo')),
                              onTap: () => pickProfileImage(
                                ImageSource.camera,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: nameController, decoration: InputDecoration(labelText: t('Name'))),
          const SizedBox(height: 14),
          TextField(controller: emailController, decoration: InputDecoration(labelText: t('Email'))),
          const SizedBox(height: 14),
          TextField(controller: phoneController, decoration: InputDecoration(labelText: t('Phone number'))),
          const SizedBox(height: 14),
          TextField(controller: locationController, decoration: InputDecoration(labelText: t('Location'))),
          const SizedBox(height: 14),
          TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: t('Password'))),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              context.read<AppState>().updateProfile(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    location: locationController.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: Text(t('SAVE')),
          ),
        ],
      ),
    );
  }
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = [
      ...state.activities,
      if (state.userRole == 'Supplier') ...state.supplierNotifications,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(state.tr('My Activity'))),
      body: entries.isEmpty
          ? Center(child: Text(state.tr('No activity yet.')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (_, index) => Card(
                child: ListTile(
                  leading: const Icon(Icons.bolt, color: FixMateTheme.gold),
                  title: Text(entries[index]),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// PROFILE OPTION
// ============================================================

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: FixMateTheme.gold,
        ),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// CONNECTIVITY WRAPPER
// ============================================================

class ConnectivityWrapper
    extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState
    extends State<ConnectivityWrapper> {
  StreamSubscription<
          List<ConnectivityResult>>?
      subscription;
  Timer? onlineTimer;

  bool isOffline = false;
  bool showOnline = false;

  @override
  void initState() {
    super.initState();

    _checkConnectivity();

    subscription =
        Connectivity().onConnectivityChanged.listen(
      (results) {
        final nextIsOffline = results.isEmpty ||
            results.every(
              (result) =>
                  result == ConnectivityResult.none,
            );

        setState(() {
          if (nextIsOffline) {
            onlineTimer?.cancel();
            showOnline = false;
          } else if (isOffline) {
            showOnline = true;
            onlineTimer?.cancel();
            onlineTimer = Timer(
              const Duration(seconds: 3),
              () {
                if (mounted) {
                  setState(() => showOnline = false);
                }
              },
            );
          }
          isOffline = nextIsOffline;
        });
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final results =
        await Connectivity().checkConnectivity();

    if (!mounted) return;

    setState(() {
      isOffline = results.isEmpty ||
          results.every(
            (result) =>
                result ==
                ConnectivityResult.none,
          );
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    onlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        Positioned(
          left: 0,
          right: 0,
          top: 12,
          child: Center(
            child: IgnorePointer(
              child: isOffline
                  ? const OfflineBanner()
                  : showOnline
                      ? const OnlineBanner()
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// OFFLINE BANNER
// ============================================================

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController blinkController;

  @override
  void initState() {
    super.initState();
    blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      lowerBound: 0.2,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: blinkController,
      child: const _ConnectivityIcon(
        color: Colors.red,
        icon: Icons.wifi_off,
      ),
    );
  }
}

// ============================================================
// ONLINE BANNER
// ============================================================

class OnlineBanner extends StatelessWidget {
  const OnlineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ConnectivityIcon(
      color: Colors.green,
      icon: Icons.wifi,
    );
  }
}

class _ConnectivityIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ConnectivityIcon({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
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
  final supplierController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final supplier = supplierController.text.trim();
    if (name.isEmpty || price == null || supplier.isEmpty) return;

    context.read<AppState>().publishProduct(
          Product(
            name: name,
            price: price,
            supplierName: supplier,
            supplierCertified: true,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product name')),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
            TextField(controller: supplierController, decoration: const InputDecoration(labelText: 'Supplier name')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: submit, child: const Text('POST')),
      ],
    );
  }
}