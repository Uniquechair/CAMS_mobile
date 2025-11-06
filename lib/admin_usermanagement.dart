import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  // For the shared sidebar button to open
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom nav index (Dashboard / Properties / Bookings / Profile / More)
  int _selectedIndex = 2;

  // Filters/state
  String _selectedUserType = 'Moderator'; // default tab
  String _selectedStatus = 'All Statuses';
  String _searchQuery = '';

  // Demo data
  final List<Map<String, dynamic>> _users = [
    {
      'uid': '1',
      'username': 'admin123',
      'firstName': 'admin',
      'lastName': '123',
      'name': 'admin 123',
      'email': 'Admin23@gmail.com',
      'status': 'Active',
      'type': 'Admin',
      'phone': '4345632145',
      'country': 'Malaysia',
    },
    {
      'uid': '3',
      'username': 'moderator123',
      'firstName': 'moderator',
      'lastName': '123',
      'name': 'moderator 123',
      'email': 'Moderator23@gmail.com',
      'status': 'Active',
      'type': 'Moderator',
      'cluster': 'Kuching',
      'phone': '132453467',
      'country': 'Malaysia',
    },
    {
      'uid': '4',
      'username': 'customer123',
      'firstName': 'customer',
      'lastName': '123',
      'name': 'customer 123',
      'email': 'Customer23@gmail.com',
      'status': 'Active',
      'type': 'Customer',
      'phone': '120101987',
      'country': 'Malaysia',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final title = _selectedUserType == 'Admin'
        ? 'Administrator Details'
        : _selectedUserType == 'Moderator'
            ? 'Moderator Details'
            : 'Customer Details';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF649EFF),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(20)),
        ),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildTopBar(),
          const SizedBox(height: 8),
          _buildUserTypeChips(),
          const SizedBox(height: 10),
          Expanded(child: _buildUserList()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top filter/search bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search ${'users'}...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v ?? 'All Statuses'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // User type selector (Customer / Moderator / Admin)
  // ─────────────────────────────────────────────────────────────
  Widget _buildUserTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _userTypeChip('Customer', Icons.people),
          const SizedBox(width: 8),
          _userTypeChip('Moderator', Icons.verified_user),
          const SizedBox(width: 8),
          _userTypeChip('Admin', Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _userTypeChip(String label, IconData icon) {
    final selected = _selectedUserType == label;
    const primary = Color(0xFF649EFF);
    return ElevatedButton(
      onPressed: () => setState(() => _selectedUserType = label),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? primary : Colors.white,
        foregroundColor: selected ? Colors.white : primary,
        elevation: selected ? 3 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: primary.withOpacity(selected ? 0 : .6))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(.2) : primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _users.where((u) => u['type'] == label).length.toString(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Users list
  // ─────────────────────────────────────────────────────────────
  Widget _buildUserList() {
    final filtered = _users.where((u) {
      final matchesType = u['type'] == _selectedUserType;
      final matchesStatus = _selectedStatus == 'All Statuses' || u['status'] == _selectedStatus;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (u['username'] as String).toLowerCase().contains(q) ||
          (u['name'] as String).toLowerCase().contains(q) ||
          (u['email'] as String).toLowerCase().contains(q);
      return matchesType && matchesStatus && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text('No users found', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final user = filtered[i];
        final type = user['type'] as String;
        final status = user['status'] as String;

        Color avatarBg;
        switch (type) {
          case 'Admin':
            avatarBg = const Color(0xFF649EFF);
            break;
          case 'Moderator':
            avatarBg = const Color(0xFF78AAFF);
            break;
          default:
            avatarBg = const Color(0xFF92BBFF);
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(backgroundColor: avatarBg, radius: 24, child: const Icon(Icons.person, color: Colors.white)),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user['username'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                _statusPill(status),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user['name'],
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            trailing: _actionMenuFor(user),
          ),
        );
      },
    );
  }

  Widget _statusPill(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDFF7E8) : const Color(0xFFFDE2E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? const Color(0xFF22C55E) : const Color(0xFFEF4444).withOpacity(.6)),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? const Color(0xFF16A34A) : const Color(0xFFB91C1C),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // Actions menu depends on type:
  // - Admin: View Details only
  // - Moderator: View, Edit, Suspend (if active) OR View, Edit, Activate, Remove (if inactive)
  // - Customer: View, Edit, Suspend (if active) OR View, Edit, Activate (if inactive) — no remove
  Widget _actionMenuFor(Map<String, dynamic> user) {
    final type = user['type'] as String;
    final isActive = user['status'] == 'Active';

    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showUserDetails(user);
            break;
          case 'edit':
            _showEditUser(user);
            break;
          case 'suspend':
            _confirmSuspend(user);
            break;
          case 'activate':
            _confirmActivate(user);
            break;
          case 'remove':
            _confirmRemove(user);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'view',
            child: _menuRow(Icons.remove_red_eye, 'View Details'),
          ),
        ];

        if (type != 'Admin') {
          items.add(PopupMenuItem<String>(value: 'edit', child: _menuRow(Icons.edit, 'Edit')));

          if (isActive) {
            items.add(PopupMenuItem<String>(value: 'suspend', child: _menuRow(Icons.block, 'Suspend')));
          } else {
            items.add(PopupMenuItem<String>(value: 'activate', child: _menuRow(Icons.check_circle, 'Activate')));
            if (type == 'Moderator') {
              items.add(PopupMenuItem<String>(value: 'remove', child: _menuRow(Icons.delete, 'Remove')));
            }
          }
        }

        return items;
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.more_horiz),
      ),
    );
  }

  Widget _menuRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1F2A44)),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dialogs: View / Edit / Confirmations
  // ─────────────────────────────────────────────────────────────
  void _showUserDetails(Map<String, dynamic> user) {
    final type = user['type'] as String;
    final title = type == 'Admin' ? 'Administrator Details' : type == 'Moderator' ? 'Moderator Details' : 'Customer Details';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF649EFF),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _detailTile('UID', user['uid']),
              _detailTile('Username', user['username']),
              _detailTile('First Name', user['firstName'] ?? ''),
              _detailTile('Last Name', user['lastName'] ?? ''),
              _detailTile('Email', user['email']),
              _detailTile('Phone Number', user['phone'] ?? 'N/A'),
              _detailTile('Country', user['country'] ?? 'N/A'),
              _detailTile('Status', user['status']),
              if (user['cluster'] != null) _detailTile('Cluster', user['cluster']),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showEditUser(Map<String, dynamic> user) {
    // Admins are view-only
    if (user['type'] == 'Admin') {
      _showUserDetails(user);
      return;
    }

    final first = TextEditingController(text: user['firstName'] ?? (user['name'] as String).split(' ').first);
    final last = TextEditingController(text: user['lastName'] ?? (user['name'] as String).split(' ').skip(1).join(' '));
    final username = TextEditingController(text: user['username']);
    final email = TextEditingController(text: user['email']);
    final phone = TextEditingController(text: user['phone'] ?? '');
    final country = TextEditingController(text: user['country'] ?? '');
    final password = TextEditingController();
    final confirm = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(height: 3, width: 64, decoration: BoxDecoration(color: const Color(0xFF649EFF), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),

                // First/Last
                Row(
                  children: [
                    Expanded(child: _labeledField('First Name *', first, icon: Icons.person_outline)),
                    const SizedBox(width: 16),
                    Expanded(child: _labeledField('Last Name *', last, icon: Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 14),
                // Username/Email
                Row(
                  children: [
                    Expanded(child: _labeledField('Username *', username, icon: Icons.person, readOnly: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _labeledField('Email *', email, icon: Icons.email_outlined, readOnly: true)),
                  ],
                ),
                const SizedBox(height: 14),
                // Password/Confirm
                Row(
                  children: [
                    Expanded(child: _labeledField('Password', password, icon: Icons.lock_outline, obscure: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _labeledField('Confirm Password', confirm, icon: Icons.lock_outline, obscure: true)),
                  ],
                ),
                const SizedBox(height: 14),
                // Phone/Country
                Row(
                  children: [
                    Expanded(child: _labeledField('Phone No *', phone, icon: Icons.phone_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: _labeledField('Country *', country, icon: Icons.public)),
                  ],
                ),
                const SizedBox(height: 22),
                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (first.text.isEmpty ||
                          last.text.isEmpty ||
                          username.text.isEmpty ||
                          email.text.isEmpty ||
                          phone.text.isEmpty ||
                          country.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      if (password.text.isNotEmpty && password.text != confirm.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      setState(() {
                        user['firstName'] = first.text;
                        user['lastName'] = last.text;
                        user['name'] = '${first.text} ${last.text}';
                        user['phone'] = phone.text;
                        user['country'] = country.text;
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('User ${user['username']} has been updated successfully.'),
                        backgroundColor: Colors.green,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF649EFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool obscure = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _confirmSuspend(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend ${user['username']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => user['status'] = 'Inactive');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('User ${user['username']} has been suspended.'),
                backgroundColor: Colors.orange,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmActivate(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Activate User'),
        content: Text('Are you sure you want to activate ${user['username']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => user['status'] = 'Active');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('User ${user['username']} has been activated.'),
                backgroundColor: Colors.green,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(Map<String, dynamic> user) {
    // Only moderators can be removed per your requirement
    if (user['type'] != 'Moderator') return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove User'),
        content: Text('Are you sure you want to permanently remove ${user['username']}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _users.remove(user));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('User ${user['username']} has been removed.'),
                backgroundColor: Colors.red,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Drawer & Bottom Nav (matching your admin_managebooking styles)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E293B),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.supervised_user_circle, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Moderator',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', true),
                  _buildDrawerItem(Icons.people, 'Customer', false),
                  _buildDrawerItem(Icons.apartment, 'PropertyListing', false),
                  _buildDrawerItem(Icons.calendar_today, 'Reservation', false),
                  _buildDrawerItem(Icons.receipt_long, 'BooknPayLog', false),
                  _buildDrawerItem(Icons.history, 'AuditTrails', false),
                  _buildDrawerItem(Icons.trending_up, 'Finance', false),
                  _buildDrawerItem(Icons.person, 'Profile', false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigating to $title')));
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.dashboard, 'Dashboard', 0),
              _buildBottomNavItem(Icons.room_service, 'Properties', 1),
              _buildBottomNavItem(Icons.calendar_today, 'Bookings', 2),
              _buildBottomNavItem(Icons.person, 'Profile', 3),
              _buildBottomNavItem(Icons.more_horiz, 'More', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF649EFF) : const Color(0xFF94A3B8), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF649EFF) : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
