import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/salon_profile.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/onboarding_provider.dart' show onboardingControllerProvider;

class SalonProfileScreen extends ConsumerStatefulWidget {
  const SalonProfileScreen({super.key});

  @override
  ConsumerState<SalonProfileScreen> createState() => _SalonProfileScreenState();
}

class _SalonProfileScreenState extends ConsumerState<SalonProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  late TabController _tabController;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;

  // Edit controllers
  final _nameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String? _logoUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _legalNameCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _regNoCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _startEditing(SalonProfile profile) {
    _nameCtrl.text = profile.name;
    _legalNameCtrl.text = profile.legalName ?? '';
    _descCtrl.text = profile.description ?? '';
    _emailCtrl.text = profile.ownerEmail ?? '';
    _phoneCtrl.text = profile.ownerPhone ?? '';
    _websiteCtrl.text = profile.websiteUrl ?? '';
    _gstCtrl.text = profile.gstNumber ?? '';
    _panCtrl.text = profile.panNumber ?? '';
    _regNoCtrl.text = profile.businessRegNumber ?? '';
    _addressCtrl.text = profile.fullAddress ?? '';
    _areaCtrl.text = profile.area ?? '';
    _cityCtrl.text = profile.city ?? '';
    _stateCtrl.text = profile.state ?? '';
    _logoUrl = profile.logoUrl;
    _coverUrl = profile.coverImageUrl;
    setState(() => _editing = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(salonRepositoryProvider).updateProfile({
        'name': _nameCtrl.text.trim(),
        'legalName': _legalNameCtrl.text.trim().isEmpty ? null : _legalNameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'ownerEmail': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'ownerPhone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'websiteUrl': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'gstNumber': _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        'panNumber': _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
        'businessRegNumber': _regNoCtrl.text.trim().isEmpty ? null : _regNoCtrl.text.trim(),
        'fullAddress': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'area': _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
        'primaryCity': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        'logoUrl': _logoUrl,
        'coverImageUrl': _coverUrl,
      });
      ref.invalidate(salonProfileProvider);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to save profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage(bool isLogo) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file == null) return;

    if (isLogo) {
      setState(() => _uploadingLogo = true);
    } else {
      setState(() => _uploadingCover = true);
    }

    try {
      final url = await ref.read(onboardingControllerProvider.notifier).uploadFile(file.path);
      if (url != null) {
        setState(() {
          if (isLogo) _logoUrl = url;
          else _coverUrl = url;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() { _uploadingLogo = false; _uploadingCover = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(salonProfileProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (profile) => _editing ? _buildEditView(profile) : _buildViewMode(profile),
      ),
    );
  }

  Widget _buildViewMode(SalonProfile profile) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: _card,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                profile.coverImageUrl != null
                    ? Image.network(profile.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _card))
                    : Container(color: _card, child: const Icon(Icons.store_rounded, size: 80, color: Colors.white24)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, _bg.withOpacity(0.8)]))),
                Positioned(
                  bottom: 56,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: _accent.withOpacity(0.2),
                        backgroundImage: profile.logoUrl != null ? NetworkImage(profile.logoUrl!) : null,
                        child: profile.logoUrl == null ? const Icon(Icons.store, color: _accent, size: 36) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => _startEditing(profile),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: _accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueGrey,
            tabs: const [
              Tab(text: 'Business'),
              Tab(text: 'Location'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessTab(profile),
          _buildLocationTab(profile),
          _buildDocumentsTab(profile),
        ],
      ),
    );
  }

  Widget _buildBusinessTab(SalonProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildViewSection('Salon Details', [
          _buildInfoRow(Icons.store_rounded, 'Salon Name', profile.name),
          if (profile.legalName != null) _buildInfoRow(Icons.business_rounded, 'Legal Name', profile.legalName!),
          if (profile.businessCategory != null) _buildInfoRow(Icons.category_rounded, 'Business Type', profile.businessCategory!),
          _buildInfoRow(Icons.circle_rounded, 'Status', profile.status, valueColor: profile.isActive ? Colors.green : Colors.red),
        ]),
        const SizedBox(height: 16),
        _buildViewSection('Contact', [
          if (profile.ownerEmail != null) _buildInfoRow(Icons.email_rounded, 'Email', profile.ownerEmail!),
          if (profile.ownerPhone != null) _buildInfoRow(Icons.phone_rounded, 'Phone', profile.ownerPhone!),
          if (profile.websiteUrl != null) _buildInfoRow(Icons.language_rounded, 'Website', profile.websiteUrl!),
        ]),
        if (profile.description != null) ...[
          const SizedBox(height: 16),
          _buildViewSection('About', [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(profile.description!, style: const TextStyle(color: Colors.white70, height: 1.5)),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildLocationTab(SalonProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildViewSection('Address', [
          if (profile.fullAddress != null) _buildInfoRow(Icons.location_on_rounded, 'Full Address', profile.fullAddress!),
          if (profile.area != null) _buildInfoRow(Icons.map_rounded, 'Area', profile.area!),
          if (profile.city != null) _buildInfoRow(Icons.location_city_rounded, 'City', profile.city!),
          if (profile.state != null) _buildInfoRow(Icons.flag_rounded, 'State', profile.state!),
          if (profile.country != null) _buildInfoRow(Icons.public_rounded, 'Country', profile.country!),
        ]),
        if (profile.latitude != null && profile.longitude != null) ...[
          const SizedBox(height: 16),
          _buildViewSection('Coordinates', [
            _buildInfoRow(Icons.my_location_rounded, 'Latitude', '${profile.latitude!.toStringAsFixed(6)}'),
            _buildInfoRow(Icons.my_location_rounded, 'Longitude', '${profile.longitude!.toStringAsFixed(6)}'),
          ]),
        ],
      ],
    );
  }

  Widget _buildDocumentsTab(SalonProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildViewSection('Business Documents', [
          if (profile.gstNumber != null) _buildInfoRow(Icons.receipt_long_rounded, 'GST Number', profile.gstNumber!),
          if (profile.panNumber != null) _buildInfoRow(Icons.badge_rounded, 'PAN Number', profile.panNumber!),
          if (profile.businessRegNumber != null) _buildInfoRow(Icons.numbers_rounded, 'Reg. Number', profile.businessRegNumber!),
        ]),
      ],
    );
  }

  Widget _buildViewSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIT VIEW ──────────────────────────────────────────────────────────────

  Widget _buildEditView(SalonProfile profile) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _editing = false),
        ),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cover + Logo
          _buildPhotoSection(),
          const SizedBox(height: 20),
          // Basic Info
          _buildEditSection('Business Details', [
            _editField('Salon Name *', _nameCtrl, Icons.store_rounded),
            _editField('Legal Business Name', _legalNameCtrl, Icons.business_rounded),
            _editField('About / Description', _descCtrl, Icons.notes_rounded, maxLines: 4),
          ]),
          const SizedBox(height: 16),
          _buildEditSection('Contact Info', [
            _editField('Owner Email', _emailCtrl, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            _editField('Contact Number', _phoneCtrl, Icons.phone_rounded, keyboardType: TextInputType.phone),
            _editField('Website URL', _websiteCtrl, Icons.language_rounded, keyboardType: TextInputType.url),
          ]),
          const SizedBox(height: 16),
          _buildEditSection('Location', [
            _editField('Full Address', _addressCtrl, Icons.location_on_rounded, maxLines: 2),
            _editField('Area / Locality', _areaCtrl, Icons.map_rounded),
            _editField('City', _cityCtrl, Icons.location_city_rounded),
            _editField('State', _stateCtrl, Icons.flag_rounded),
          ]),
          const SizedBox(height: 16),
          _buildEditSection('Business Documents', [
            _editField('GST Number', _gstCtrl, Icons.receipt_long_rounded),
            _editField('PAN Number', _panCtrl, Icons.badge_rounded),
            _editField('Business Reg. Number', _regNoCtrl, Icons.numbers_rounded),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          // Cover image
          GestureDetector(
            onTap: () => _uploadImage(false),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, style: BorderStyle.solid),
                color: _bg,
                image: _coverUrl != null ? DecorationImage(image: NetworkImage(_coverUrl!), fit: BoxFit.cover) : null,
              ),
              child: _uploadingCover
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _coverUrl == null
                      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_rounded, color: Colors.blueGrey, size: 32), SizedBox(height: 4), Text('Cover Image', style: TextStyle(color: Colors.blueGrey, fontSize: 12))]))
                      : Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(8), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 16)))),
            ),
          ),
          const SizedBox(height: 12),
          // Logo
          Row(
            children: [
              GestureDetector(
                onTap: () => _uploadImage(true),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bg,
                    border: Border.all(color: _border),
                    image: _logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: _uploadingLogo
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))
                      : _logoUrl == null
                          ? const Icon(Icons.add_a_photo_rounded, color: Colors.blueGrey, size: 28)
                          : null,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Salon Logo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Tap to change', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(String title, List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey),
          prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
        ),
      ),
    );
  }
}
