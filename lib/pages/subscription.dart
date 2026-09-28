// FixMate — Subscription page (technicians/suppliers)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
