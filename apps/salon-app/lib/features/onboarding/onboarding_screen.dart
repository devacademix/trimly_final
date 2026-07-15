import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final _formKeys = <GlobalKey<FormState>>[
    GlobalKey<FormState>(), // welcome
    GlobalKey<FormState>(), // mobile
    GlobalKey<FormState>(), // basic info
    GlobalKey<FormState>(), // location
    GlobalKey<FormState>(), // details
    GlobalKey<FormState>(), // timing
    GlobalKey<FormState>(), // photos
    GlobalKey<FormState>(), // services
    GlobalKey<FormState>(), // staff
    GlobalKey<FormState>(), // bank
    GlobalKey<FormState>(), // kyc
    GlobalKey<FormState>(), // subscription
    GlobalKey<FormState>(), // tour
    GlobalKey<FormState>(), // completed
  ];

  // Controllers
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _salonNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _businessCategory = 'SALON';
  final _countryCtrl = TextEditingController(text: 'India');
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double? _lat, _lng;
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _logoUrl, _coverUrl;
  List<Map<String, String>> _gallery = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _staffList = [];
  final _accHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accNumCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  Map<String, bool> _kycUploaded = {'PAN': false, 'AADHAAR': false, 'GST': false, 'CANCELED_CHEQUE': false, 'PASSBOOK': false};
  List<dynamic> _plans = [];
  String? _selectedPlanId;
  bool _otpSent = false;
  bool _isFetchingLocation = false;
  final List<Map<String, dynamic>> _schedules = List.generate(7, (i) => {
    'dayOfWeek': i,
    'openTime': '09:00',
    'closeTime': '20:00',
    'isOpen': true,
  });

  final _picker = ImagePicker();

  static const _bgColor = Color(0xFF0F172A);
  static const _cardColor = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _initOnboarding();
  }

  Future<void> _initOnboarding() async {
    try {
      await ref.read(onboardingControllerProvider.notifier).fetchStatus();
      await ref.read(onboardingControllerProvider.notifier).fetchPlans();
    } catch (_) {}

    final initialStep = ref.read(onboardingControllerProvider).currentStep;
    final initialIndex = OnboardingStep.values.indexOf(initialStep);
    _pageController = PageController(initialPage: initialIndex);

    if (mounted) {
      setState(() {
        _loadingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final key in _formKeys) { key.currentState?.dispose(); }
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _ownerNameCtrl.dispose();
    _salonNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _regNoCtrl.dispose();
    _descCtrl.dispose();
    _accHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    final step = ref.read(onboardingControllerProvider).currentStep;
    final idx = OnboardingStep.values.indexOf(step);
    if (_formKeys[idx].currentState?.validate() ?? true) {
      ref.read(onboardingControllerProvider.notifier).nextStep();
    }
  }

  void _goBack() {
    ref.read(onboardingControllerProvider.notifier).previousStep();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      } 

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          if (place.country != null) _countryCtrl.text = place.country!;
          if (place.administrativeArea != null) _stateCtrl.text = place.administrativeArea!;
          if (place.locality != null) _cityCtrl.text = place.locality!;
          if (place.subLocality != null) _areaCtrl.text = place.subLocality!;
          _addressCtrl.text = [place.street, place.subLocality, place.locality, place.administrativeArea, place.postalCode].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  String _formatTime12h(String time24) {
    if (time24.isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int h = int.tryParse(parts[0]) ?? 0;
    int m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime(int dayIndex, bool isOpenTime) async {
    final currentStr = _schedules[dayIndex][isOpenTime ? 'openTime' : 'closeTime'] as String;
    final parts = currentStr.split(':');
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    if (parts.length == 2) {
      initialTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _schedules[dayIndex][isOpenTime ? 'openTime' : 'closeTime'] = '$h:$m';
      });
    }
  }

  Widget _buildProgressBar() {
    final step = ref.watch(onboardingControllerProvider).currentStep;
    final total = OnboardingStep.values.length;
    final current = OnboardingStep.values.indexOf(step);
    return LinearProgressIndicator(
      value: (current + 1) / total,
      backgroundColor: _border,
      valueColor: const AlwaysStoppedAnimation(_accent),
      minHeight: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStatus) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    final state = ref.watch(onboardingControllerProvider);
    final isWelcome = state.currentStep == OnboardingStep.welcome;
    final isComplete = state.currentStep == OnboardingStep.completed;

    ref.listen(onboardingControllerProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        final targetIndex = OnboardingStep.values.indexOf(next.currentStep);
        if (_pageController.hasClients && _pageController.page?.round() != targetIndex) {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return PopScope(
      canPop: isWelcome || isComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
        child: Column(
          children: [
            if (!isWelcome && !isComplete) _buildProgressBar(),
            if (!isWelcome && !isComplete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: _goBack,
                    ),
                    const Spacer(),
                    Text(
                      'Step ${OnboardingStep.values.indexOf(state.currentStep) + 1} of ${OnboardingStep.values.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(),
                  _buildMobileStep(),
                  _buildBasicInfoStep(),
                  _buildLocationStep(),
                  _buildDetailsStep(),
                  _buildTimingStep(),
                  _buildPhotosStep(),
                  _buildServicesStep(),
                  _buildStaffStep(),
                  _buildBankStep(),
                  _buildKycStep(),
                  _buildSubscriptionStep(),
                  _buildTourStep(),
                  _buildCompletedStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(text, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: obscure ? 1 : (maxLines ?? 1),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.blueGrey),
          prefixIcon: prefixIcon,
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent)),
          labelStyle: const TextStyle(color: Colors.blueGrey),
        ),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _actionButton(String text, {VoidCallback? onPressed, bool loading = false, Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _skipButton() {
    return TextButton(
      onPressed: () => ref.read(onboardingControllerProvider.notifier).nextStep(),
      child: const Text('Skip for now', style: TextStyle(color: Colors.blueGrey)),
    );
  }

  Widget _errorBanner() {
    final err = ref.watch(onboardingControllerProvider).errorMessage;
    if (err == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(err, style: const TextStyle(color: Colors.white, fontSize: 13))),
          GestureDetector(
            onTap: () => ref.read(onboardingControllerProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ WELCOME STEP ═══════════════════
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.store, color: _accent, size: 44),
          ),
          const SizedBox(height: 24),
          const Text('Welcome to Trimly', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Manage your salon, grow your business', style: TextStyle(color: Colors.blueGrey, fontSize: 15)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.storefront),
              label: const Text('Register Business', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Login', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('By continuing, you agree to our Terms & Privacy Policy',
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  // ═══════════════════ MOBILE OTP STEP ═══════════════════
  Widget _buildMobileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Mobile Verification'),
          _subtitle('Enter your phone number to verify your account'),
          _errorBanner(),
          _inputField(
            controller: _phoneCtrl,
            label: 'Mobile Number',
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone, color: Colors.blueGrey),
          ),
          if (_otpSent) ...[
            _inputField(
              controller: _otpCtrl,
              label: 'Enter OTP',
              hint: '6-digit code',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueGrey),
              validator: (v) => (v == null || v.length < 4) ? 'Enter valid OTP' : null,
            ),
          ],
          const SizedBox(height: 8),
          if (!_otpSent)
            _actionButton('Send OTP', onPressed: () async {
              if (_formKeys[1].currentState!.validate()) {
                final phone = _phoneCtrl.text.trim();
                final ok = await ref.read(onboardingControllerProvider.notifier).sendOtp(phone);
                if (ok && mounted) setState(() => _otpSent = true);
              }
            }),
          if (_otpSent) ...[
            _actionButton('Verify OTP', onPressed: () async {
              if (_formKeys[1].currentState!.validate()) {
                final phone = _phoneCtrl.text.trim();
                final otp = _otpCtrl.text.trim();
                final ok = await ref.read(onboardingControllerProvider.notifier).verifyOtp(phone, otp);
                if (ok && mounted) _goNext();
              }
            }),
            const SizedBox(height: 8),
            _skipButton(),
          ],
        ]),
      ),
    );
  }

  // ═══════════════════ BASIC INFO STEP ═══════════════════
  Widget _buildBasicInfoStep() {
    final categories = ['SALON', 'SPA', 'NAIL_STUDIO', 'BARBER', 'MAKEUP_STUDIO'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Basic Information'),
          _subtitle('Tell us about yourself and your business'),
          _errorBanner(),
          _inputField(controller: _ownerNameCtrl, label: 'Owner Name', prefixIcon: const Icon(Icons.person, color: Colors.blueGrey)),
          _inputField(controller: _salonNameCtrl, label: 'Salon Name', prefixIcon: const Icon(Icons.store, color: Colors.blueGrey)),
          _inputField(controller: _emailCtrl, label: 'Email', keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.email, color: Colors.blueGrey),
              validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null),
          _inputField(controller: _passwordCtrl, label: 'Password', obscure: true, prefixIcon: const Icon(Icons.lock, color: Colors.blueGrey),
              validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:             DropdownButtonFormField<String>(
              initialValue: _businessCategory,
              dropdownColor: _cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Business Category',
                prefixIcon: const Icon(Icons.category, color: Colors.blueGrey),
                filled: true, fillColor: _cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent)),
                labelStyle: const TextStyle(color: Colors.blueGrey),
              ),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ')))).toList(),
              onChanged: (v) { if (v != null) setState(() => _businessCategory = v); },
            ),
          ),
          _actionButton('Continue', onPressed: () async {
            if (_formKeys[2].currentState!.validate()) {
              final ok = await ref.read(onboardingControllerProvider.notifier).saveBasicInfo(
                ownerName: _ownerNameCtrl.text.trim(),
                salonName: _salonNameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text,
                businessCategory: _businessCategory,
              );
            }
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  // ═══════════════════ LOCATION STEP ═══════════════════
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Business Location'),
          _subtitle('Where is your salon located?'),
          _errorBanner(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              icon: _isFetchingLocation 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: Colors.blueAccent),
              label: Text(_isFetchingLocation ? 'Fetching...' : 'Fetch Location automatically'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _inputField(controller: _countryCtrl, label: 'Country', prefixIcon: const Icon(Icons.public, color: Colors.blueGrey)),
          _inputField(controller: _stateCtrl, label: 'State', prefixIcon: const Icon(Icons.map, color: Colors.blueGrey)),
          _inputField(controller: _cityCtrl, label: 'City', prefixIcon: const Icon(Icons.location_city, color: Colors.blueGrey)),
          _inputField(controller: _areaCtrl, label: 'Area / Locality', prefixIcon: const Icon(Icons.near_me, color: Colors.blueGrey)),
          _inputField(controller: _addressCtrl, label: 'Full Address', prefixIcon: const Icon(Icons.home, color: Colors.blueGrey)),
          Row(
            children: [
              Expanded(child: _inputField(controller: TextEditingController(text: _lat?.toString() ?? ''), label: 'Latitude', keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (_) => null)),
              const SizedBox(width: 12),
              Expanded(child: _inputField(controller: TextEditingController(text: _lng?.toString() ?? ''), label: 'Longitude', keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (_) => null)),
            ],
          ),
          const SizedBox(height: 8),
          _actionButton('Continue', onPressed: () async {
            if (_formKeys[3].currentState!.validate()) {
              final ok = await ref.read(onboardingControllerProvider.notifier).saveLocation(
                country: _countryCtrl.text.trim(), stateStr: _stateCtrl.text.trim(),
                city: _cityCtrl.text.trim(), area: _areaCtrl.text.trim(),
                fullAddress: _addressCtrl.text.trim(), lat: _lat, lng: _lng,
              );
            }
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  // ═══════════════════ DETAILS STEP ═══════════════════
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[4],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Business Details'),
          _subtitle('Add your business information (optional fields can be skipped)'),
          _errorBanner(),
          _inputField(controller: _gstCtrl, label: 'GST Number (Optional)', validator: (_) => null, prefixIcon: const Icon(Icons.receipt, color: Colors.blueGrey)),
          _inputField(controller: _panCtrl, label: 'PAN Number (Optional)', validator: (_) => null, prefixIcon: const Icon(Icons.credit_card, color: Colors.blueGrey)),
          _inputField(controller: _regNoCtrl, label: 'Business Registration No. (Optional)', validator: (_) => null, prefixIcon: const Icon(Icons.article, color: Colors.blueGrey)),
          _inputField(controller: _descCtrl, label: 'Business Description (Optional)', maxLines: 3, validator: (_) => null, prefixIcon: const Icon(Icons.description, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          _actionButton('Continue', onPressed: () async {
            final ok = await ref.read(onboardingControllerProvider.notifier).saveDetails(
              gst: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
              pan: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
              regNo: _regNoCtrl.text.trim().isEmpty ? null : _regNoCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            );
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  // ═══════════════════ TIMING STEP ═══════════════════
  Widget _buildTimingStep() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[5],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Business Hours'),
          _subtitle('Set your weekly working hours'),
          _errorBanner(),
          ...List.generate(7, (i) {
            final schedule = _schedules[i];
            final isOpen = schedule['isOpen'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(days[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                  const Spacer(),
                  if (isOpen) ...[
                    GestureDetector(
                      onTap: () => _pickTime(i, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                        child: Text(_formatTime12h(schedule['openTime']), style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(color: Colors.blueGrey))),
                    GestureDetector(
                      onTap: () => _pickTime(i, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                        child: Text(_formatTime12h(schedule['closeTime']), style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else
                    const Text('Closed', style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _schedules[i]['isOpen'] = !isOpen),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: isOpen ? const Color(0xFF166534) : Colors.red.shade900, borderRadius: BorderRadius.circular(6)),
                      child: Text(isOpen ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),
          _actionButton('Continue', onPressed: () async {
            final ok = await ref.read(onboardingControllerProvider.notifier).saveTiming(_schedules);
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  // ═══════════════════ PHOTOS STEP ═══════════════════
  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[6],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Upload Photos'),
          _subtitle('Add your salon photos to attract customers'),
          _errorBanner(),
          _buildPhotoCard('Logo', _logoUrl, () => _pickImage((url) => setState(() => _logoUrl = url))),
          const SizedBox(height: 12),
          _buildPhotoCard('Cover Image', _coverUrl, () => _pickImage((url) => setState(() => _coverUrl = url))),
          const SizedBox(height: 12),
          const Text('Salon Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._gallery.map((g) => Container(
                  width: 100, height: 100, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border),
                      image: DecorationImage(image: NetworkImage(g['url']!), fit: BoxFit.cover)),
                )),
                GestureDetector(
                  onTap: () => _pickImage((url) {
                    if (url != null) setState(() => _gallery.add({'url': url, 'mediaType': 'IMAGE'}));
                  }),
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border, style: BorderStyle.solid)),
                    child: const Icon(Icons.add_photo_alternate, color: Colors.blueGrey, size: 32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _actionButton('Continue', onPressed: () async {
            final ok = await ref.read(onboardingControllerProvider.notifier).savePhotos(
              logoUrl: _logoUrl, coverUrl: _coverUrl,
              gallery: _gallery.isNotEmpty ? _gallery : null,
            );
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
          const SizedBox(height: 8),
          _skipButton(),
        ]),
      ),
    );
  }

  Widget _buildPhotoCard(String label, String? url, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 80,
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Row(children: [
          const SizedBox(width: 16),
          Icon(url != null ? Icons.check_circle : Icons.add_photo_alternate, color: url != null ? Colors.green : Colors.blueGrey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          if (url != null)
            Container(width: 60, height: 60, margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover))),
        ]),
      ),
    );
  }

  Future<void> _pickImage(Function(String?) onUrl) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      final url = await ref.read(onboardingControllerProvider.notifier).uploadFile(file.path);
      onUrl(url);
    }
  }

  // ═══════════════════ SERVICES STEP ═══════════════════
  Widget _buildServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[7],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Add Services'),
          _subtitle('What services do you offer? (Add at least one or skip)'),
          _errorBanner(),
          ..._services.asMap().entries.map((e) => Container(
            padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('₹${e.value['price']} | ${e.value['duration']} min', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ])),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _services.removeAt(e.key))),
            ]),
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
            style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _accent)),
          ),
          const SizedBox(height: 16),
          _actionButton('Continue', onPressed: () async {
            if (_services.isNotEmpty) {
              await ref.read(onboardingControllerProvider.notifier).addServices(_services);
            } else {
              await ref.read(onboardingControllerProvider.notifier).skipServices();
            }
          }),
          _skipButton(),
        ]),
      ),
    );
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Add Service', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _inputField(controller: nameCtrl, label: 'Service Name'),
            _inputField(controller: catCtrl, label: 'Category (e.g. Haircut)', validator: (_) => null),
            _inputField(controller: priceCtrl, label: 'Price (₹)', keyboardType: TextInputType.number),
            _inputField(controller: durCtrl, label: 'Duration (min)', keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty && durCtrl.text.isNotEmpty) {
                setState(() => _services.add({
                  'name': nameCtrl.text.trim(),
                  'categoryName': catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
                  'price': double.parse(priceCtrl.text.trim()),
                  'duration': int.parse(durCtrl.text.trim()),
                }));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ STAFF STEP ═══════════════════
  Widget _buildStaffStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[8],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Add Staff'),
          _subtitle('Add your team members (optional)'),
          _errorBanner(),
          ..._staffList.asMap().entries.map((e) => Container(
            padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value['fullName'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(e.value['designation'] as String, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ])),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _staffList.removeAt(e.key))),
            ]),
          )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddStaffDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Staff'),
            style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _accent)),
          ),
          const SizedBox(height: 16),
          _actionButton('Continue', onPressed: () async {
            if (_staffList.isNotEmpty) {
              await ref.read(onboardingControllerProvider.notifier).addStaff(_staffList);
            } else {
              await ref.read(onboardingControllerProvider.notifier).skipStaff();
            }
          }),
          _skipButton(),
        ]),
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Add Staff', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _inputField(controller: nameCtrl, label: 'Staff Name'),
            _inputField(controller: phoneCtrl, label: 'Phone Number', keyboardType: TextInputType.phone),
            _inputField(controller: desigCtrl, label: 'Designation', hint: 'e.g. Hair Stylist'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => _staffList.add({
                  'fullName': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'designation': desigCtrl.text.trim().isEmpty ? 'Staff' : desigCtrl.text.trim(),
                }));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ BANK STEP ═══════════════════
  Widget _buildBankStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[9],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Bank Details'),
          _subtitle('Add your bank details for receiving settlements'),
          _errorBanner(),
          _inputField(controller: _accHolderCtrl, label: 'Account Holder Name', prefixIcon: const Icon(Icons.person, color: Colors.blueGrey)),
          _inputField(controller: _bankNameCtrl, label: 'Bank Name', prefixIcon: const Icon(Icons.account_balance, color: Colors.blueGrey)),
          _inputField(controller: _accNumCtrl, label: 'Account Number', keyboardType: TextInputType.number, prefixIcon: const Icon(Icons.numbers, color: Colors.blueGrey)),
          _inputField(controller: _ifscCtrl, label: 'IFSC Code', prefixIcon: const Icon(Icons.code, color: Colors.blueGrey)),
          _inputField(controller: _upiCtrl, label: 'UPI ID (Optional)', validator: (_) => null, prefixIcon: const Icon(Icons.payments, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          _actionButton('Continue', onPressed: () async {
            if (_formKeys[9].currentState!.validate()) {
              final ok = await ref.read(onboardingControllerProvider.notifier).saveBankDetails(
                accountHolder: _accHolderCtrl.text.trim(),
                bankName: _bankNameCtrl.text.trim(),
                accountNumber: _accNumCtrl.text.trim(),
                ifsc: _ifscCtrl.text.trim(),
                upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
              );
            }
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  // ═══════════════════ KYC STEP ═══════════════════
  Widget _buildKycStep() {
    const docs = ['PAN', 'AADHAAR', 'GST', 'CANCELED_CHEQUE', 'PASSBOOK'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[10],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('KYC Verification'),
          _subtitle('Upload your documents for verification'),
          _errorBanner(),
          ...docs.map((doc) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: ListTile(
              leading: Icon(_kycUploaded[doc]! ? Icons.check_circle : Icons.upload_file, color: _kycUploaded[doc]! ? Colors.green : Colors.blueGrey),
              title: Text(doc.replaceAll('_', ' '), style: const TextStyle(color: Colors.white)),
              trailing: _kycUploaded[doc]!
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.upload, color: Colors.blueGrey),
              onTap: () => _uploadKycDoc(doc),
            ),
          )),
          const SizedBox(height: 16),
          _actionButton('Continue', onPressed: () async {
            final ok = await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
          }, loading: ref.watch(onboardingControllerProvider).isLoading),
        ]),
      ),
    );
  }

  Future<void> _uploadKycDoc(String docType) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file != null) {
      final url = await ref.read(onboardingControllerProvider.notifier).uploadFile(file.path);
      if (url != null) {
        final ok = await ref.read(onboardingControllerProvider.notifier).uploadKyc(docType, url);
        if (ok && mounted) setState(() => _kycUploaded[docType] = true);
      }
    }
  }

  // ═══════════════════ SUBSCRIPTION STEP ═══════════════════
  Widget _buildSubscriptionStep() {
    final state = ref.watch(onboardingControllerProvider);
    final plans = state.plans;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[11],
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Choose Your Plan'),
          _subtitle('Select a subscription plan that suits your business'),
          _errorBanner(),
          if (plans.isEmpty) 
            const Center(child: CircularProgressIndicator())
          else
          ...plans.map((plan) {
            final name = plan['name'] as String;
            final price = (plan['price'] as num).toDouble();
            final selected = _selectedPlanId == plan['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPlanId = plan['id'] as String?),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? _accent : _border, width: selected ? 2 : 1),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$price/month • ${plan['branchLimit']} branches • ${plan['staffLimit']} staff',
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                  ])),
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? _accent : Colors.blueGrey, size: 22),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),
          _actionButton(
            _selectedPlanId == null || _selectedPlanId == 'free' ? 'Continue with Free Plan' : 'Continue', 
            onPressed: () async {
              // Default to free if none selected
              final planIdToSubmit = _selectedPlanId ?? 'free';
              final ok = await ref.read(onboardingControllerProvider.notifier).subscribe(planIdToSubmit);
            }, 
            loading: ref.watch(onboardingControllerProvider).isLoading,
          ),
        ]),
      ),
    );
  }

  // ═══════════════════ TOUR STEP ═══════════════════
  Widget _buildTourStep() {
    final features = [
      {'icon': Icons.calendar_month, 'label': 'Bookings', 'desc': 'Manage all appointments'},
      {'icon': Icons.people, 'label': 'Staff', 'desc': 'Manage your team'},
      {'icon': Icons.content_cut, 'label': 'Services', 'desc': 'Manage service catalog'},
      {'icon': Icons.account_balance_wallet, 'label': 'Wallet', 'desc': 'Track earnings'},
      {'icon': Icons.bar_chart, 'label': 'Reports', 'desc': 'Business insights'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.explore, color: _accent, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('Dashboard Tour', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Here\'s what you can do from your dashboard', style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
        const SizedBox(height: 32),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Icon(f['icon'] as IconData, color: _accent, size: 28),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(f['desc'] as String, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ]),
          ]),
        )),
        const Spacer(),
        _actionButton('Finish Tour', onPressed: _goNext),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ═══════════════════ COMPLETED STEP ═══════════════════
  Widget _buildCompletedStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: const Color(0xFF166534).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(50)),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
        ),
        const SizedBox(height: 24),
        const Text('Ready to Go!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text(
          'Your salon profile has been submitted for review.\nYou will be notified once approved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF9A3412).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC2410C))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hourglass_bottom, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Text('Pending Approval', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 32),
        _actionButton('Go to Dashboard', onPressed: () {
          ref.read(authControllerProvider.notifier).restoreAfterOtp();
          context.go('/dashboard');
        }),
        const SizedBox(height: 16),
      ]),
    );
  }
}
