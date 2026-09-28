// FixMate — Profile, edit profile, and activity log
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login.dart';
import 'requests.dart';
import 'supplier_orders.dart';
import 'my_orders.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    return Scaffold(
      appBar: FixMateAppBar(
        title: t('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            state.profileImageBytes == null ?
                CircleAvatar(
  radius: 45,
  backgroundColor: FixMateTheme.gold,
  backgroundImage: state.profileImage,
  child: state.profileImage == null
      ? const Icon(Icons.person, size: 48, color: Colors.white)
      : null,
): 
             CircleAvatar(
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
             if (state.userRole == 'Customer' || state.userRole == 'Technician') ...[
  SizedBox(
    width: double.infinity,
    child: FilledButton.tonalIcon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RequestsPage()),
      ),
      icon: const Icon(Icons.assignment_outlined),
      label: Text(t('My Requests')),
    ),
  ),
  const SizedBox(height: 10),
],

if (state.userRole == 'Supplier') ...[
  SizedBox(
    width: double.infinity,
    child: FilledButton.tonalIcon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupplierOrdersPage()),
      ),
      icon: const Icon(Icons.inventory_2_outlined),
      label: Text(t('Orders received')),
    ),
  ),
  const SizedBox(height: 10),
],

if (state.userRole != 'Admin') ...[
  SizedBox(
    width: double.infinity,
    child: FilledButton.tonalIcon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersPage()),
      ),
      icon: const Icon(Icons.receipt_long_outlined),
      label: Text(t('My Orders')),
    ),
  ),
  const SizedBox(height: 10),
],

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
              onPressed: () async {
  await state.signOutSupabase();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
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
  bool saving = false;

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

  Future<void> pickProfileImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (!mounted || image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() => showPhotoOptions = false);
    await context.read<AppState>().uploadProfileImageSupabase(bytes);
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> save() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final newPassword = passwordController.text;

    if (newPassword.isNotEmpty && newPassword.length < 6) {
      showMessage(t('Password must be at least 6 characters.'));
      return;
    }

    setState(() => saving = true);

    final ok = await state.updateProfile(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      location: locationController.text.trim(),
    );

    var passwordOk = true;
    if (ok && newPassword.isNotEmpty) {
      passwordOk = await state.changePassword(newPassword);
    }

    if (!mounted) return;
    setState(() => saving = false);

    if (!ok) {
      showMessage(t('Could not save your changes.'));
      return;
    }
    if (!passwordOk) {
      showMessage(t('Profile saved, but the password could not be changed.'));
      return;
    }
    showMessage(t('Profile updated successfully.'));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;

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
                      builder: (context, state, _) => CircleAvatar(
                        radius: 48,
                        backgroundImage: state.profileImage,
                        child: state.profileImage == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
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
                              leading: const Icon(Icons.photo_library_outlined),
                              title: Text(t('Choose from device')),
                              onTap: () => pickProfileImage(ImageSource.gallery),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.camera_alt_outlined),
                              title: Text(t('Take a photo')),
                              onTap: () => pickProfileImage(ImageSource.camera),
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
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: t('Name')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: t('Email'),
              suffixIcon: const Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t('Phone number')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: locationController,
            decoration: InputDecoration(labelText: t('Location')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: t('New password (optional)')),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: saving ? null : save,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('SAVE')),
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
