import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'navigation.dart';
import 'login.dart';

class BusinessVerificationPage extends StatefulWidget {
  final bool allowSkip;

  const BusinessVerificationPage({super.key, this.allowSkip = false});

  @override
  State<BusinessVerificationPage> createState() =>
      _BusinessVerificationPageState();
}

class _BusinessVerificationPageState extends State<BusinessVerificationPage> {
  final Map<String, VerificationDocumentFile> selectedFiles = {};
  final taxIdentificationController = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    taxIdentificationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final existing = context.read<AppState>().businessTaxIdentificationNumber;
    if (existing != null && taxIdentificationController.text.isEmpty) {
      taxIdentificationController.text = existing;
    }
  }

  List<_DocumentRequirement> requirements(AppState state) {
    if (state.userRole == 'Supplier') {
      return const [
        _DocumentRequirement(
          key: 'registration_certificate',
          type: 'registration_certificate',
          title: 'Certificate of registration',
        ),
        _DocumentRequirement(
          key: 'location_plan',
          type: 'location_plan',
          title: 'Business location plan',
        ),
      ];
    }
    return [
      for (final service in state.verificationRequiredServices)
        _DocumentRequirement(
          key: 'technician_license|$service',
          type: 'technician_license',
          title: 'Certificate or license: $service',
          serviceName: service,
        ),
      const _DocumentRequirement(
        key: 'criminal_record',
        type: 'criminal_record',
        title: 'Criminal record document',
      ),
      const _DocumentRequirement(
        key: 'government_id_front',
        type: 'government_id_front',
        title: 'Government ID card (front)',
      ),
      const _DocumentRequirement(
        key: 'government_id_back',
        type: 'government_id_back',
        title: 'Government ID card (back)',
      ),
      const _DocumentRequirement(
        key: 'government_id_holding',
        type: 'government_id_holding',
        title: 'Photo of you holding your government ID',
      ),
      const _DocumentRequirement(
        key: 'location_plan',
        type: 'location_plan',
        title: 'Location plan',
      ),
    ];
  }

  Future<void> chooseFile(_DocumentRequirement requirement) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (!mounted || file == null) return;
      final size = await file.length();
      if (size == null) {
        _showMessage('Could not determine the selected file size.');
        return;
      }
      if (size > 15 * 1024 * 1024) {
        _showMessage('Each verification file must be 15 MB or smaller.');
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        selectedFiles[requirement.key] = VerificationDocumentFile(
          documentKey: requirement.key,
          documentType: requirement.type,
          serviceName: requirement.serviceName,
          fileName: file.name,
          bytes: bytes,
        );
      });
    } catch (error) {
      _showMessage('Could not select the file: $error');
    }
  }

  Future<void> submit(AppState state) async {
    final required = requirements(state);
    if (required.isEmpty) {
      _showMessage(
        'Your registered services could not be loaded. Please contact support.',
      );
      return;
    }
    final taxIdentificationNumber = taxIdentificationController.text.trim();
    if (state.userRole == 'Supplier' && taxIdentificationNumber.isEmpty) {
      _showMessage('Enter your company tax identification number.');
      return;
    }
    final missing = required
        .where(
          (document) =>
              !state.businessVerificationDocuments.containsKey(document.key) &&
              !selectedFiles.containsKey(document.key),
        )
        .toList();
    if (missing.isNotEmpty) {
      _showMessage('Please provide every required document.');
      return;
    }

    setState(() => submitting = true);
    final success = await state.submitBusinessVerification(
      selectedFiles.values.toList(),
      taxIdentificationNumber: state.userRole == 'Supplier'
          ? taxIdentificationNumber
          : null,
    );
    if (!mounted) return;
    setState(() => submitting = false);
    if (!success) {
      _showMessage(state.tr(state.authError));
      return;
    }
    if (state.userRole == 'Supplier') {
      _showMessage(
        'Documents submitted. Admin review may take up to 24 hours.',
      );
    } else {
      _showMessage(
        'Documents submitted. Your blue verified badge appears after approval and an active subscription.',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> signOut(AppState state) async {
    await state.signOutSupabase();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSupplier = state.userRole == 'Supplier';
    final status = state.businessVerificationStatus;
    final isPending = status == 'submitted';
    final isApproved = status == 'approved';
    final canUpload = !isPending && !isApproved;
    final docs = requirements(state);

    return PopScope(
      canPop: widget.allowSkip || isApproved,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isSupplier ? 'Company verification' : 'Get verified'),
          automaticallyImplyLeading: widget.allowSkip || isApproved,
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => signOut(state),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: state.businessVerificationLoading
            ? const Center(child: CircularProgressIndicator())
            : state.businessVerificationLoadFailed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load your verification status.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.loadBusinessVerification,
                        child: const Text('Retry'),
                      ),
                      if (widget.allowSkip &&
                          state.userRole == 'Technician')
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(),
                            ),
                          ),
                          child: const Text('Skip for now'),
                        ),
                    ],
                  ),
                ),
              )
            : isPending
            ? _statusPanel(
                icon: Icons.hourglass_top,
                title: 'Documents under review',
                message: isSupplier
                    ? 'Your documents were submitted. Please allow up to 24 hours for admin review. You can use the app after your company is approved.'
                    : 'Your documents are being reviewed. You can use the app, but the verified badge appears only after approval and an active subscription.',
                action: isSupplier
                    ? OutlinedButton(
                        onPressed: state.loadBusinessVerification,
                        child: const Text('Check review status'),
                      )
                    : null,
              )
            : isApproved
            ? _statusPanel(
                icon: Icons.verified,
                title: 'Documents approved',
                message: state.hasActiveBusinessSubscription
                    ? 'Your business is verified.'
                    : 'Your documents are approved. Subscribe to display your verified blue badge.',
                action: isSupplier
                    ? FilledButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(),
                          ),
                        ),
                        child: const Text('Continue into FixMate'),
                      )
                    : null,
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    isSupplier
                        ? 'Submit your company documents to access supplier features. Admin review takes up to 24 hours.'
                        : 'Documents are optional for now. Submit every item below for admin review and a verified badge when your subscription is active.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (status == 'rejected' &&
                      state.businessVerificationReviewNote != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Please correct and resubmit: ${state.businessVerificationReviewNote}',
                        ),
                      ),
                    ),
                  ],
                  if (state.userRole == 'Technician' && docs.isEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'No registered services were found. Please sign out and contact support before submitting documents.',
                    ),
                  ],
                  if (isSupplier) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: taxIdentificationController,
                      decoration: const InputDecoration(
                        labelText: 'Company tax identification number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final document in docs)
                    _documentTile(state, document, canUpload: canUpload),
                  const SizedBox(height: 12),
                  if (canUpload)
                    FilledButton.icon(
                      onPressed: submitting ? null : () => submit(state),
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline),
                      label: Text(
                        submitting
                            ? 'Uploading securely…'
                            : 'Submit for review',
                      ),
                    ),
                  if (widget.allowSkip) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: submitting
                          ? null
                          : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigation(),
                              ),
                            ),
                      child: const Text('Skip for now'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _documentTile(
    AppState state,
    _DocumentRequirement document, {
    required bool canUpload,
  }) {
    final selected = selectedFiles[document.key];
    final exists = state.businessVerificationDocuments.containsKey(
      document.key,
    );
    final label =
        selected?.fileName ?? (exists ? 'Previously uploaded' : 'Required');
    return Card(
      child: ListTile(
        leading: Icon(
          selected != null || exists
              ? Icons.check_circle
              : Icons.upload_file_outlined,
          color: selected != null || exists
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(document.title),
        subtitle: Text(label),
        trailing: canUpload
            ? IconButton(
                tooltip: 'Choose document',
                onPressed: () => chooseFile(document),
                icon: const Icon(Icons.attach_file),
              )
            : null,
      ),
    );
  }

  Widget _statusPanel({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

class _DocumentRequirement {
  final String key;
  final String type;
  final String title;
  final String? serviceName;

  const _DocumentRequirement({
    required this.key,
    required this.type,
    required this.title,
    this.serviceName,
  });
}
