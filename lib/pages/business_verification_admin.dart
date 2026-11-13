import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';

class BusinessVerificationAdminPage extends StatefulWidget {
  const BusinessVerificationAdminPage({super.key});

  @override
  State<BusinessVerificationAdminPage> createState() =>
      _BusinessVerificationAdminPageState();
}

class _BusinessVerificationAdminPageState
    extends State<BusinessVerificationAdminPage> {
  List<Map<String, dynamic>> applications = [];
  List<Map<String, dynamic>> auditEvents = [];
  bool loading = true;
  String? error;
  final Set<String> busy = {};

  String documentLabel(Map<String, dynamic> document) {
    final type = document['document_type'] as String? ?? 'Document';
    final serviceName = document['service_name'] as String?;
    if (type == 'technician_license' && serviceName != null) {
      return 'Certificate or license — $serviceName';
    }
    return switch (type) {
      'criminal_record' => 'Criminal record document',
      'government_id_front' => 'Government ID card (front)',
      'government_id_back' => 'Government ID card (back)',
      'government_id_holding' => 'Photo holding government ID',
      'location_plan' => 'Location plan',
      'registration_certificate' => 'Certificate of registration',
      'tax_identification' => 'Tax identification document',
      _ => type.replaceAll('_', ' '),
    };
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final appState = context.read<AppState>();
      final result = await appState.adminLoadBusinessVerifications();
      final audit = await appState.adminLoadBusinessVerificationAudit();
      if (!mounted) return;
      setState(() {
        applications = result;
        auditEvents = audit;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> openDocument(String path) async {
    try {
      final url = await context
          .read<AppState>()
          .adminCreateVerificationDocumentUrl(path);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _message('Could not open this private document.');
      }
    } catch (e) {
      if (mounted) _message('Could not open this private document: $e');
    }
  }

  Future<String?> askForRejectionNote() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request changes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Explain what needs correction',
            helperText:
                'Name each document and describe the correction needed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    controller.dispose();
    return note;
  }

  Future<void> review(String userId, String decision, {String? note}) async {
    setState(() => busy.add(userId));
    try {
      await context.read<AppState>().adminReviewBusinessVerification(
        userId,
        decision,
        note: note,
      );
      await refresh();
      if (mounted) {
        _message(
          decision == 'approved'
              ? 'Business documents approved.'
              : 'Changes requested.',
        );
      }
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => busy.remove(userId));
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business document reviews'),
        actions: [
          IconButton(
            onPressed: loading ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : applications.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: Text('No business documents need review.')),
                _auditLog(),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Identity and criminal-record documents are private. Review them only for verification and do not share or download them unnecessarily.',
                    ),
                  ),
                ),
                for (final application in applications)
                  _applicationCard(application),
                _auditLog(),
              ],
            ),
    );
  }

  Widget _auditLog() => Card(
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent verification audit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (auditEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No verification audit events yet.'),
            )
          else
            for (final event in auditEvents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '${event['event_type']}${event['document_key'] is String ? ' · ${event['document_key']}' : ''}',
                ),
                subtitle: Text(
                  '${event['target_name'] ?? 'Business account'}'
                  ' · ${event['actor_name'] ?? 'System'}'
                  ' · ${event['created_at'] ?? ''}',
                ),
              ),
        ],
      ),
    ),
  );

  Widget _applicationCard(Map<String, dynamic> application) {
    final userId = application['user_id'] as String;
    final isBusy = busy.contains(userId);
    final isSubmitted = application['status'] == 'submitted';
    final documents = (application['documents'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application['full_name'] as String? ?? 'Business account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${application['role'] ?? ''} · ${application['email'] ?? ''}',
            ),
            Text(
              'Status: ${application['status'] ?? 'submitted'}'
              '${application['submitted_at'] is String ? ' · Submitted ${application['submitted_at']}' : ''}',
            ),
            if (application['tax_identification_number'] is String) ...[
              const SizedBox(height: 4),
              Text(
                'Tax identification number: ${application['tax_identification_number']}',
              ),
            ],
            if (application['review_note'] is String) ...[
              const SizedBox(height: 4),
              Text('Previous note: ${application['review_note']}'),
            ],
            const SizedBox(height: 10),
            if (!isSubmitted)
              const Text(
                'Waiting for the provider to resubmit corrected documents. Review actions are disabled until then.',
              ),
            for (final document in documents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(documentLabel(document)),
                trailing: IconButton(
                  tooltip: 'Open secure document',
                  onPressed: () =>
                      openDocument(document['storage_path'] as String),
                  icon: const Icon(Icons.open_in_new),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: isBusy || !isSubmitted
                      ? null
                      : () async {
                          final note = await askForRejectionNote();
                          if (note == null || note.isEmpty || !mounted) return;
                          await review(userId, 'rejected', note: note);
                        },
                  child: const Text('Request changes'),
                ),
                FilledButton(
                  onPressed: isBusy || !isSubmitted
                      ? null
                      : () => review(userId, 'approved'),
                  child: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve documents'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
