import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';

class CustomerOnboardingScreen extends ConsumerStatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  ConsumerState<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends ConsumerState<CustomerOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 3: Basic Profile
  final _dobCtrl = TextEditingController();
  String _selectedGender = 'PREFER_NOT_TO_SAY';

  // Step 4 & 6: Permissions
  bool _locationAllowed = false;
  bool _notificationsAllowed = false;

  // Step 5: Interests
  final List<String> _availableInterests = [
    'Haircut', 'Spa', 'Massage', 'Facial', 'Makeup', 'Nails', 'Tattoo', 'Barber'
  ];
  final List<String> _selectedInterests = [];

  // Step 7: Referral
  final _referralCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _dobCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _skipStep() {
    _nextStep();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    final data = {
      'dateOfBirth': _dobCtrl.text.isNotEmpty ? _dobCtrl.text : null,
      'gender': _selectedGender,
      'locationAllowed': _locationAllowed,
      'notificationsAllowed': _notificationsAllowed,
      'interests': _selectedInterests,
      'referralCode': _referralCtrl.text.trim().isNotEmpty ? _referralCtrl.text.trim() : null,
    }..removeWhere((_, v) => v == null);

    final success = await ref.read(authControllerProvider.notifier).completeOnboarding(data);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final message = ref.read(authControllerProvider).errorMessage ?? 'Failed to complete onboarding';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
    // The router will automatically redirect to /home since onboardingComplete is now true.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(onPressed: _skipStep, child: const Text('Skip')),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentStep = idx),
        children: [
          _buildBasicProfile(theme),
          _buildLocationPermission(theme),
          _buildInterests(theme),
          _buildNotificationPermission(theme),
          _buildReferral(theme),
          _buildWelcomeOffer(theme),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_currentStep == 5 ? 'Start Exploring' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicProfile(ThemeData theme) {
    final user = ref.watch(authControllerProvider).user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi ${user?.displayName ?? ''}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text('Tell us a bit more about yourself to help us personalize your experience.', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Male')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              DropdownMenuItem(value: 'PREFER_NOT_TO_SAY', child: Text('Prefer not to say')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobCtrl,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                final m = picked.month.toString().padLeft(2, '0');
                final d = picked.day.toString().padLeft(2, '0');
                _dobCtrl.text = '${picked.year}-$m-$d';
              }
            },
            decoration: InputDecoration(
              labelText: 'Date of Birth (YYYY-MM-DD)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermission(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Find Salons Near You', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Allow GPS to see the best premium salons in your area.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 48),
          SwitchListTile(
            title: const Text('Enable Location'),
            value: _locationAllowed,
            onChanged: (v) => setState(() => _locationAllowed = v),
          )
        ],
      ),
    );
  }

  Widget _buildInterests(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you looking for?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select services you usually book.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPermission(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_active, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Stay Updated', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Get booking reminders, status updates, and exclusive discounts.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 48),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsAllowed,
            onChanged: (v) => setState(() => _notificationsAllowed = v),
          )
        ],
      ),
    );
  }

  Widget _buildReferral(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Have a Referral Code?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Enter a friend\'s code to get bonus wallet credits on your first booking.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 48),
          TextFormField(
            controller: _referralCtrl,
            decoration: InputDecoration(
              labelText: 'Referral Code (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.group_add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeOffer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_offer, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text('WELCOME OFFER', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Flat ₹100 Off', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('On your first premium booking', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Your discount will be automatically applied at checkout.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
