import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/salon_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  late TabController _tabController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showServiceForm({SalonService? existing}) async {
    final categoriesAsync = ref.read(serviceCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a category first'), backgroundColor: Colors.orange),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ServiceFormSheet(
        existing: existing,
        categories: categories,
        onSaved: () {
          ref.invalidate(servicesListProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('New Category', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Hair, Skin, Nail',
            hintStyle: const TextStyle(color: Colors.blueGrey),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(salonRepositoryProvider).createCategory(name);
                ref.invalidate(serviceCategoriesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(SalonService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Delete Service?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${service.name}"?', style: const TextStyle(color: Colors.blueGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(salonRepositoryProvider).deleteService(service.id);
      ref.invalidate(servicesListProvider);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blueGrey,
          tabs: const [Tab(text: 'Services'), Tab(text: 'Categories')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: _accent),
            onPressed: () => _tabController.index == 0 ? _showServiceForm() : _showAddCategoryDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Services Tab ─────────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async { ref.invalidate(servicesListProvider); ref.invalidate(serviceCategoriesProvider); },
            color: _accent,
            backgroundColor: _card,
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
              error: (e, _) => _buildError('Failed to load services', () => ref.invalidate(servicesListProvider)),
              data: (services) => _buildServicesList(services, categoriesAsync.valueOrNull ?? []),
            ),
          ),
          // ── Categories Tab ───────────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(serviceCategoriesProvider),
            color: _accent,
            backgroundColor: _card,
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
              error: (e, _) => _buildError('Failed to load categories', () => ref.invalidate(serviceCategoriesProvider)),
              data: (cats) => _buildCategoriesList(cats),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: () => _tabController.index == 0 ? _showServiceForm() : _showAddCategoryDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Add Service' : 'Add Category', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildServicesList(List<SalonService> services, List<ServiceCategory> categories) {
    if (services.isEmpty) return _buildEmptyState('No services yet', 'Tap + to add your first service', Icons.content_cut_rounded);

    // Filter by category
    final filtered = _selectedCategoryId == null
        ? services
        : services.where((s) => s.categoryId == _selectedCategoryId).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildCategoryFilter(categories),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _buildServiceCard(filtered[i]),
            childCount: filtered.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<ServiceCategory> categories) {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All', null),
          ...categories.map((c) => _filterChip(c.name, c.id)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? catId) {
    final selected = _selectedCategoryId == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = catId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _accent : _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _accent : _border),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildServiceCard(SalonService service) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.content_cut_rounded, color: _accent, size: 22),
        ),
        title: Row(
          children: [
            Expanded(child: Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            if (!service.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('Inactive', style: TextStyle(color: Colors.red, fontSize: 10)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey.shade500),
                const SizedBox(width: 4),
                Text('${service.duration} min', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                if (service.categoryName != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.label_rounded, size: 12, color: Colors.blueGrey.shade500),
                  const SizedBox(width: 4),
                  Text(service.categoryName!, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('₹${service.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                if (service.discountPrice != null) ...[
                  const SizedBox(width: 8),
                  Text('₹${service.discountPrice!.toStringAsFixed(0)}', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12, decoration: TextDecoration.lineThrough)),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20),
              onPressed: () => _showServiceForm(existing: service),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _deleteService(service),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(List<ServiceCategory> cats) {
    if (cats.isEmpty) return _buildEmptyState('No categories yet', 'Tap + to create a category', Icons.category_rounded);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final cat = cats[i];
        return Container(
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.category_rounded, color: _accent, size: 20),
            ),
            title: Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: cat.description != null ? Text(cat.description!, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)) : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.blueGrey.shade700, size: 64),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
      ]),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.blueGrey, size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
  }
}

// ─── Service Form Bottom Sheet ────────────────────────────────────────────────

class _ServiceFormSheet extends ConsumerStatefulWidget {
  final SalonService? existing;
  final List<ServiceCategory> categories;
  final VoidCallback onSaved;

  const _ServiceFormSheet({this.existing, required this.categories, required this.onSaved});

  @override
  ConsumerState<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<_ServiceFormSheet> {
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);
  static const _border = Color(0xFF334155);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String? _categoryId;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s != null) {
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description ?? '';
      _priceCtrl.text = s.price.toStringAsFixed(0);
      _durationCtrl.text = s.duration.toString();
      _categoryId = s.categoryId;
      _isActive = s.isActive;
    } else {
      _categoryId = widget.categories.isNotEmpty ? widget.categories.first.id : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'duration': int.parse(_durationCtrl.text.trim()),
        'categoryId': _categoryId,
        'isActive': _isActive,
      };
      if (widget.existing != null) {
        await ref.read(salonRepositoryProvider).updateService(widget.existing!.id, data);
      } else {
        await ref.read(salonRepositoryProvider).createService(data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              widget.existing != null ? 'Edit Service' : 'New Service',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _field('Service Name *', _nameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _field('Description', _descCtrl, maxLines: 2),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field('Price (₹) *', _priceCtrl, keyboardType: TextInputType.number, validator: (v) => double.tryParse(v ?? '') == null ? 'Enter number' : null)),
              const SizedBox(width: 12),
              Expanded(child: _field('Duration (min) *', _durationCtrl, keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null ? 'Enter number' : null)),
            ]),
            const SizedBox(height: 14),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _categoryId,
              dropdownColor: _card,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: const TextStyle(color: Colors.blueGrey),
                filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
              ),
              items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),

            // Active toggle
            Row(
              children: [
                const Text('Active', style: TextStyle(color: Colors.white)),
                const Spacer(),
                Switch(value: _isActive, activeColor: _accent, onChanged: (v) => setState(() => _isActive = v)),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.existing != null ? 'Update Service' : 'Create Service', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
