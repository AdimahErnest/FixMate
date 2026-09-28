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
