import 'package:flutter/material.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../services/session.dart';
import '../api.dart' as api;

class OwnerClusterPage extends StatefulWidget {
  const OwnerClusterPage({super.key});

  @override
  State<OwnerClusterPage> createState() => _OwnerClusterPageState();
}

class _OwnerClusterPageState extends State<OwnerClusterPage> {
  int _selectedIndex = -1;
  String _isoNowUtc() => DateTime.now().toIso8601String();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Cluster Names';

  List<Map<String, dynamic>> allClusters = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get filteredClusters {
    List<Map<String, dynamic>> filtered = allClusters;

    if (_selectedFilter != 'All Cluster Names') {
      filtered = filtered.where((c) => c['name'] == _selectedFilter).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c['name'].toString().toLowerCase().contains(q) ||
            c['state'].toString().toLowerCase().contains(q) ||
            c['province'].toString().toLowerCase().contains(q);
      }).toList();
    }
    return filtered;
  }

  List<String> get clusterNames =>
      ['All Cluster Names', ...allClusters.map((c) => c['name'].toString()).toSet()];

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await api.fetchClusters();
      // Handle possible shapes: {clusters: [...]}, {data: [...]}
      List<dynamic> raw = [];
      if (data['clusters'] != null && data['clusters'] is List) {
        raw = data['clusters'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        raw = data['data'] as List<dynamic>;
      }

      final now = _isoNowUtc();
      final mapped = raw.whereType<Map<String, dynamic>>().map((c) {
        // Normalise backend fields to local keys used by UI
        final id = c['clusterid'] ?? c['clusterId'] ?? c['id'];
        final name = c['clustername'] ?? c['clusterName'] ?? c['name'];
        final state = c['state'] ?? c['clusterstate'] ?? c['clusterState'];
        final province = c['province'] ?? c['clusterprovince'] ?? c['clusterProvince'];
        return {
          'id': id,
          'name': name?.toString() ?? '',
          'state': state?.toString() ?? '',
          'province': province?.toString() ?? '',
          'timestamp': (c['updated_at'] ?? c['created_at'] ?? now).toString(),
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        allClusters = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load clusters: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420; 
    final isTablet = width >= 420 && width < 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: _buildAppBar(),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.owner,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Cluster',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsiveHeader(isCompact),
              const SizedBox(height: 16),
              _buildFilterSection(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: Color(0xFF0077B6)),
                  ),
                )
              else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddClusterDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add New Cluster', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isCompact) _buildClusterCards() else _buildClusterTable(forceShortHeader: isTablet),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: nav.UserRole.owner,
      ),
    );
  }

  Widget _buildResponsiveHeader(bool isCompact) {
    final title = const Text(
      'Cluster Management',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );

    final search = TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      cursorColor: const Color(0xFF0077B6),
      decoration: InputDecoration(
        hintText: 'Search clusters...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 8),
          search,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: search,
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cluster Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Theme(
              data: Theme.of(context).copyWith(
                dropdownMenuTheme: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white),
                  ),
                ),
                highlightColor: Colors.white,
                splashColor: Colors.transparent,
              ),

              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: Colors.white,

                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),

                items: clusterNames.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedFilter = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildClusterCards() {
    final clusters = filteredClusters;
    if (clusters.isEmpty) return _emptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clusters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = clusters[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${c['id']}', style: const TextStyle(color: Color(0xFF64748B))),
                  Text('Province: ${c['province']}', style: const TextStyle(color: Color(0xFF64748B))),
                  Text('State: ${c['state']}', style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            trailing: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: const PopupMenuThemeData(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                ),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'view') _showViewClusterDialog(c);
                  if (v == 'edit') _showEditClusterDialog(c);
                  if (v == 'delete') _showDeleteConfirmDialog(c);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'view', child: _MenuRow(icon: Icons.visibility, text: 'View Details')),
                  const PopupMenuItem(
                      value: 'edit', child: _MenuRow(icon: Icons.edit, text: 'Edit Cluster')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(icon: Icons.delete, text: 'Delete Cluster', danger: true)),
                ],
              )
            ),
          ),
        );
      },
    );
  }

  Widget _buildClusterTable({bool forceShortHeader = false}) {
    final clusters = filteredClusters;

    if (clusters.isEmpty) return _emptyState();

    final headerActions = forceShortHeader ? 'Action' : 'Actions';

    final table = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                Expanded(flex: 1, child: _HeaderText('ID')),
                Expanded(flex: 2, child: _HeaderText('Name')),
                Expanded(flex: 2, child: _HeaderText('State')),
                Expanded(flex: 2, child: _HeaderText('Province')),
                Expanded(flex: 1, child: _HeaderText(headerActions, alignRight: true)),
              ],
            ),
          ),
          ...clusters.map(_buildClusterRow),
        ],
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 680),
        child: table,
      ),
    );
  }

  Widget _buildClusterRow(Map<String, dynamic> cluster) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${cluster['id']}', style: const TextStyle(color: Color(0xFF1E293B)))),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Text(cluster['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Text(cluster['state'])),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Text(cluster['province'])),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'view') _showViewClusterDialog(cluster);
                  if (v == 'edit') _showEditClusterDialog(cluster);
                  if (v == 'delete') _showDeleteConfirmDialog(cluster);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'view', child: _MenuRow(icon: Icons.visibility, text: 'View Details')),
                  const PopupMenuItem(
                      value: 'edit', child: _MenuRow(icon: Icons.edit, text: 'Edit Cluster')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(icon: Icons.delete, text: 'Delete Cluster', danger: true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text('No clusters found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          SizedBox(height: 6),
          Text('Try adjusting your search or filter criteria', style: TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _showAddClusterDialog() {
    final nameController = TextEditingController();
    final stateController = TextEditingController();
    final provinceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFFE7F0FF), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Cluster',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: _input('Cluster Name', 'Enter cluster name'),
              ),
              const SizedBox(height: 12),
              TextField(controller: stateController, decoration: _input('State', 'Enter cluster state')),
              const SizedBox(height: 12),
              TextField(controller: provinceController, decoration: _input('Province', 'Enter province')),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                      TextButton.styleFrom(foregroundColor: const Color(0xFF64748B), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        stateController.text.isEmpty ||
                        provinceController.text.isEmpty) {
                      return;
                    }
                    try {
                      await api.addCluster({
                        'clustername': nameController.text,
                        'state': stateController.text,
                        'province': provinceController.text,
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                      await _loadClusters();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Cluster added successfully'),
                        backgroundColor: Color(0xFF84CC16),
                      ));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to add cluster: $e'),
                        backgroundColor: const Color(0xFFEF4444),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Cluster', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewClusterDialog(Map<String, dynamic> cluster) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Cluster Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            _buildDetailRow('ID', '${cluster['id']}'),
            const SizedBox(height: 12),
            _buildDetailRow('Cluster Name', cluster['name']),
            const SizedBox(height: 12),
            _buildDetailRow('State', cluster['state']),
            const SizedBox(height: 12),
            _buildDetailRow('Province', cluster['province']),
            const SizedBox(height: 12),
            _buildDetailRow('Timestamp', (cluster['timestamp'] ?? '-') as String),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _input(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0), 
        width: 0.8,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF0077B6), 
        width: 1.2,
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 0.8,
      ),
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF64748B), 
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
      ]),
    );
  }

  void _showEditClusterDialog(Map<String, dynamic> cluster) {
    final nameController = TextEditingController(text: cluster['name']);
    final stateController = TextEditingController(text: cluster['state']);
    final provinceController = TextEditingController(text: cluster['province']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Edit Cluster',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: _input('Cluster Name', '')),
            const SizedBox(height: 12),
            TextField(controller: stateController, decoration: _input('State', '')),
            const SizedBox(height: 12),
            TextField(controller: provinceController, decoration: _input('Province', '')),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style:
                    TextButton.styleFrom(foregroundColor: const Color(0xFF64748B), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final id = cluster['id'];
                  if (id == null) return;
                  try {
                    await api.updateCluster(
                      id is int ? id : int.tryParse(id.toString()) ?? 0,
                      {
                        'clustername': nameController.text,
                        'state': stateController.text,
                        'province': provinceController.text,
                      },
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadClusters();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Cluster updated successfully'),
                      backgroundColor: Color(0xFF84CC16),
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update cluster: $e'),
                      backgroundColor: Color(0xFFEF4444),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> cluster) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Delete Cluster?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('Are you sure you want to delete "${cluster['name']}"? This action cannot be undone.',
                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final id = cluster['id'];
                    if (id == null) return;
                    try {
                      await api.deleteCluster(
                        id is int ? id : int.tryParse(id.toString()) ?? 0,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      await _loadClusters();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Cluster deleted successfully'),
                        backgroundColor: Color(0xFFEF4444),
                      ));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to delete cluster: $e'),
                        backgroundColor: const Color(0xFFEF4444),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF4188FF)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Cluster Management',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Manage property clusters', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF64748B)),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 4) {
      // More button handled by SharedBottomNavigationBar to open drawer
      return;
    }
    if (index == 0) {
      Navigator.of(context).pushNamed('/owner');
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed('/owner-property-listing');
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed('/owner-reservation');
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      Navigator.of(context).pushNamed('/owner');
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (label == 'PropertyListing' || label == 'Properties') {
      Navigator.of(context).pushNamed('/owner-property-listing');
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      Navigator.of(context).pushNamed('/owner-reservation');
      return;
    }
    if (label == 'Customer') {
      Navigator.of(context).pushNamed('/owner-manage-customer');
      return;
    }
    if (label == 'Moderator/Admin') {
      Navigator.of(context).pushNamed('/owner-manage-moderatoradmin');
      return;
    }
    if (label == 'AuditTrails') {
      Navigator.of(context).pushNamed('/owner-audit-trails');
      return;
    }
    if (label == 'BooknPayLog') {
      Navigator.of(context).pushNamed('/owner-book-and-pay');
      return;
    }
    if (label == 'Cluster') {
      // Already on cluster page
      return;
    }
    if (label == 'Finance') {
      Navigator.of(context).pushNamed('/owner-book-and-pay');
      return;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: const Text('Logout', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Session.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
      }
    }
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _HeaderText(this.text, {this.alignRight = false});
  @override
  Widget build(BuildContext context) {
    final t = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)));
    return alignRight ? Align(alignment: Alignment.centerRight, child: t) : t;
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  const _MenuRow({required this.icon, required this.text, this.danger = false});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: danger ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: danger ? const Color(0xFFEF4444) : null)),
    ]);
  }
}
