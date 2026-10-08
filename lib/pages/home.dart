// FixMate — Home tab

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'technicians.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final theme = Theme.of(context);

    final services = [
      ServiceTile(
        icon: Icons.bolt,
        title: t('Electricity'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TechniciansPage(initialService: 'Electricity'),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.water_drop,
        title: t('Plumbing'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TechniciansPage(initialService: 'Plumbing'),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.ac_unit,
        title: t('AC & Refrigeration'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TechniciansPage(
              initialService: 'Refrigeration & Air Conditioning',
            ),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.phone_android,
        title: t('Phone Repair'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TechniciansPage(initialService: 'Phone Repairs'),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.computer,
        title: t('Computer Repair'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TechniciansPage(
              initialService: 'Computer & IT Tools Repair',
            ),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.wb_sunny,
        title: t('Solar'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TechniciansPage(initialService: 'Solar'),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.directions_car,
        title: t('Auto Repair'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TechniciansPage(initialService: 'Auto Repair'),
          ),
        ),
      ),
      ServiceTile(
        icon: Icons.home_work,
        title: t('Appliances'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TechniciansPage(initialService: 'Home Appliance Repair'),
          ),
        ),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FixMateLogo(size: 55),
                      const Spacer(),
                      const LanguageButton(),
                      const SizedBox(width: 4),
                      const ThemeButton(),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        children: [
                          Text(
                            t('Your trusted technician marketplace'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              'Find technicians, buy tools and equipment, and get your problems solved.',
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 620;
                      final button = ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TechniciansPage(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: FixMateTheme.darkGold,
                          minimumSize: const Size(48, 54),
                        ),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(t('Find a Technician')),
                      );

                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isWide ? 30 : 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [FixMateTheme.gold, FixMateTheme.darkGold],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: FixMateTheme.darkGold.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(child: _CallToActionCopy(t: t)),
                                  const SizedBox(width: 24),
                                  button,
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CallToActionCopy(t: t),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    width: double.infinity,
                                    child: button,
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 38),
                  _SectionHeading(title: t('Popular Services')),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 860
                          ? 4
                          : constraints.maxWidth >= 560
                          ? 3
                          : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: columns == 2 ? 1.22 : 1.28,
                        children: services,
                      );
                    },
                  ),
                  const SizedBox(height: 38),
                  _SectionHeading(title: t('How FixMate works')),
                  const SizedBox(height: 16),
                  HowItWorksStep(
                    number: '1',
                    title: t('Find'),
                    description: t('Find a technician or product.'),
                  ),
                  HowItWorksStep(
                    number: '2',
                    title: t('Request'),
                    description: t('Describe your problem and location.'),
                  ),
                  HowItWorksStep(
                    number: '3',
                    title: t('Get it fixed'),
                    description: t('Your technician comes to you.'),
                  ),
                  HowItWorksStep(
                    number: '4',
                    title: t('Rate'),
                    description: t('Rate your experience.'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallToActionCopy extends StatelessWidget {
  const _CallToActionCopy({required this.t});

  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Need a technician?'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t('Find a professional near you.'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 27, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HowItWorksStep extends StatelessWidget {
  const HowItWorksStep({
    super.key,
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
