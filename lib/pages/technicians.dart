// FixMate — Technicians list, card, and profile/request page
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class TechniciansPage extends StatefulWidget {
  final String? initialService;

  const TechniciansPage({super.key, this.initialService});

  @override
  State<TechniciansPage> createState() => _TechniciansPageState();
}

class _TechniciansPageState extends State<TechniciansPage> {
  String? selectedService;
  String? selectedTown;
  
    String query = '';

  bool matchesQuery(TechnicianData technician) {
    final words = query.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return true;
    final tr = context.read<AppState>().tr;
    final haystack = normalizeSearch([
      technician.name,
      technician.town,
      technician.region,
      ...technician.services,
      ...technician.services.map(tr),
    ].join(' '));
    return words.every((word) => haystack.contains(word));
  }

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadTechnicians();
    });
  }

  List<TechnicianData> filterTechnicians(List<TechnicianData> all) {
    final wanted = selectedService?.toLowerCase();
    return all.where((technician) {
      final serviceMatches = wanted == null ||
          technician.services.any((s) => s.toLowerCase().contains(wanted));
      final locationMatches =
          selectedTown == null || technician.town == selectedTown;
            if (!serviceMatches || !locationMatches) return false;
      return matchesQuery(technician);
    }).toList();
  }

  Future<void> chooseService() async {
    final state = context.read<AppState>();
    final allServices = state.technicianList
        .expand((technician) => technician.services)
        .toSet()
        .toList()
      ..sort();

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
            ...allServices.map(
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
    final town = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: cameroonRegions.entries
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
    if (!mounted || town == null) return;
    setState(() => selectedTown = town);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final results = filterTechnicians(state.technicianList);
    final firstLoad = state.techniciansLoading && state.technicianList.isEmpty;

    return Scaffold(
            appBar: FixMateAppBar(
        title: t('Technicians'),
        suggestions: const ['Search technician'],
        onSearchChanged: (value) => setState(() => query = value),
      ),
      body: RefreshIndicator(
        onRefresh: state.loadTechnicians,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: chooseService,
                    icon: const Icon(Icons.handyman_outlined),
                    label: Text(
                      selectedService == null ? t('Service') : t(selectedService!),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            if (state.showingDemoTechnicians)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t('Showing demo technicians. Real technicians appear here once they sign up.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (firstLoad)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Center(child: Text(t('No technicians found.'))),
              )
            else
              ...results.map(
                (technician) => TechnicianCard(technician: technician),
              ),
          ],
        ),
      ),
    );
  }
}



class TechnicianCard extends StatelessWidget {
  final TechnicianData technician;

  const TechnicianCard({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    final image = technician.image;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: image,
                  child: image == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    technician.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (technician.certified) const CertifiedBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(technician.town),
                const Spacer(),
                const Icon(Icons.star, size: 18, color: FixMateTheme.gold),
                const SizedBox(width: 4),
                Text(
                  technician.rating > 0 ? technician.rating.toString() : t('New'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (technician.services.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                technician.services.map(t).join(' • '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text('${technician.jobs} ${t('jobs completed')}'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicianProfilePage(technician: technician),
                    ),
                  );
                },
                child: Text(t('VIEW PROFILE')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 

class TechnicianProfilePage extends StatefulWidget {
  final TechnicianData technician;

  const TechnicianProfilePage({super.key, required this.technician});

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  late String selectedService;
  final detailsController = TextEditingController();
  bool sending = false;

  TechnicianData get tech => widget.technician;

  List<String> get serviceOptions =>
      tech.services.isEmpty ? const ['General'] : tech.services;

  @override
  void initState() {
    super.initState();
    selectedService = serviceOptions.first;
  }

  @override
  void dispose() {
    detailsController.dispose();
    super.dispose();
  }

  Future<void> requestService() async {
    final state = context.read<AppState>();
    final t = state.tr;
    final messenger = ScaffoldMessenger.of(context);

    final technicianId = tech.id;
    if (technicianId == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(t('This is a demo profile. Requests can only be sent to real technicians.')),
      ));
      return;
    }

    final details = detailsController.text.trim();
    if (details.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(t('Please describe the service you need.'))),
      );
      return;
    }

    setState(() => sending = true);
    final ok = await state.createServiceRequestSupabase(
      technicianId: technicianId,
      service: selectedService,
      description: details,
    );
    if (!mounted) return;
    setState(() => sending = false);

    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text('${t('Service request sent successfully.')} ${t(selectedService)}'),
      ));
      detailsController.clear();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(t('Could not send your request. Please try again.')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().tr;
    final image = tech.image;
    final ratingText = tech.rating > 0 ? '${tech.rating} ★' : t('New');

    return Scaffold(
      appBar: AppBar(
        title: Text(tech.name),
        actions: const [LanguageButton(), ThemeButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 46,
                backgroundImage: image,
                child: image == null ? const Icon(Icons.person, size: 46) : null,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    tech.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (tech.certified) ...[
                  const SizedBox(width: 5),
                  const CertifiedBadge(),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${tech.town}  •  $ratingText  •  ${tech.jobs} ${t('jobs completed')}',
                textAlign: TextAlign.center,
              ),
            ),
            if (tech.certified) ...[
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
              children: serviceOptions
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
              decoration: InputDecoration(labelText: t('Service')),
              items: serviceOptions
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(t(service)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedService = value);
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
                onPressed: sending ? null : requestService,
                icon: sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
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
