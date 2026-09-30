import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/fapshi_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final FapshiService _fapshiService = FapshiService();
  String _selectedPlan = 'monthly'; // 'monthly' or 'yearly'
  String _selectedMedium = 'mobile money'; // 'mobile money' (MTN) or 'orange money'
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showPaymentSheet(int amount, String planName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900], // Match your dark theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complete Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              
              // Phone Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number (e.g., 67XXXXXXX)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Network Selection
              const Text('Select Network:', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('MTN Mobile Money', style: TextStyle(color: Colors.white)),
                      selected: _selectedMedium == 'mobile money',
                      selectedColor: Colors.yellow[700],
                      backgroundColor: Colors.grey[800],
                      onSelected: (selected) {
                        setState(() => _selectedMedium = 'mobile money');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Orange Money', style: TextStyle(color: Colors.white)),
                      selected: _selectedMedium == 'orange money',
                      selectedColor: Colors.orange,
                      backgroundColor: Colors.grey[800],
                      onSelected: (selected) {
                        setState(() => _selectedMedium = 'orange money');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _processDirectPayment(amount, planName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text('Pay $amount FCFA', style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processDirectPayment(int amount, String planName) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid phone number')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _fapshiService.directPayment(
      amount: amount,
      phone: phone,
      medium: _selectedMedium,
      externalId: 'SUB_${DateTime.now().millisecondsSinceEpoch}',
      message: '$planName Subscription - FixMate',
    );
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment prompt sent to $phone. Please check your phone to complete the $planName subscription.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initiate payment. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSupplier = state.userRole == 'Supplier';
    
    // Define prices based on role
    final monthlyPrice = isSupplier ? 20000 : 5000;
    final yearlyPrice = isSupplier ? 200000 : 50000;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isSupplier ? 'Supplier Account Pricing' : 'Technician Account Pricing',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 30),

            // Monthly Plan Card
            _buildPlanCard(
              title: 'Monthly Plan',
              price: monthlyPrice,
              duration: '/month',
              isSelected: _selectedPlan == 'monthly',
              onTap: () => setState(() => _selectedPlan = 'monthly'),
            ),
            const SizedBox(height: 20),

            // Yearly Plan Card
            _buildPlanCard(
              title: 'Yearly Plan',
              price: yearlyPrice,
              duration: '/year',
              isSelected: _selectedPlan == 'yearly',
              onTap: () => setState(() => _selectedPlan = 'yearly'),
              badge: 'Save 17%',
            ),
            const Spacer(),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = _selectedPlan == 'monthly' ? monthlyPrice : yearlyPrice;
                  _showPaymentSheet(amount, _selectedPlan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required int price,
    required String duration,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (badge != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ],
            ),
            Text(
              '$price FCFA$duration',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}