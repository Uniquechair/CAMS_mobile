import 'dart:math' show min;
import 'package:flutter/material.dart';

// Who is using the page right now?
enum AppRole { admin, moderator }

class AdminUserManagementPage extends StatefulWidget {
  final AppRole viewerRole;

  const AdminUserManagementPage({
    Key? key,
    required this.viewerRole,
  }) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom nav selection
  int _selectedIndex = 0;

  // Tabs
  String _selectedUserType = 'Customer'; // Customer | Moderator | Admin
  String _selectedStatus = 'All Statuses'; // All Statuses | Active | Inactive

  // Search
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Demo data (replace with API data)
  final List<Map<String, dynamic>> _users = [
    {
      'uid': '1',
      'username': 'admin123',
      'name': 'Admin 123',
      'email': 'admin23@gmail.com',
      'status': 'Active',
      'type': 'Admin',
      'phone': '4345632145',
      'country': 'Malaysia',
    },
    {
      'uid': '3',
      'username': 'moderator123',
      'name': 'Moderator 123',
      'email': 'moderator23@gmail.com',
      'status': 'Active',
      'type': 'Moderator',
      'cluster': 'Kuching',
      'phone': '132453467',
      'country': 'Malaysia',
    },
    {
      'uid': '4',
      'username': 'customer123',
      'name': 'Customer 123',
      'email': 'customer23@gmail.com',
      'status': 'Active',
      'type': 'Customer',
      'phone': '120101987',
      'country': 'Malaysia',
    },
  ];

  // ===== Role-aware theme =====
  static const Color kBg = Color(0xFFE7F0FF); // both roles

  Color get kPrimary =>
      widget.viewerRole == AppRole.admin ? const Color(0xFF649EFF) : const Color(0xFF78AAFF);

  Color get kPrimaryDeep => _darken(kPrimary, .12);
  static const Color kMuted = Color(0xFF6B7280); // gray-500

  static Color _darken(Color c, [double amount = .1]) {
    final hsl = HSLColor.fromColor(c);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  List<String> get _availableTypes {
    if (widget.viewerRole == AppRole.admin) {
      return const ['Customer', 'Moderator', 'Admin'];
    }
    // Moderator can only see Customers
    return const ['Customer'];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===== SMART SEARCH (role-aware) =====
  void _performSmartSearch(String query) {
    final q = query.trim().toLowerCase();
    _searchQuery = query;

    if (q.isEmpty) {
      setState(() {});
      return;
    }

    final match = _users.firstWhere(
      (u) => (u['username'] as String).toLowerCase().contains(q),
      orElse: () => <String, dynamic>{},
    );

    if (match.isNotEmpty) {
      final targetType = match['type'] as String;
      // only switch if the viewer can access that tab
      if (_availableTypes.contains(targetType) && targetType != _selectedUserType) {
        setState(() => _selectedUserType = targetType);
        return;
      }
    }

    setState(() {}); // refresh filter on current tab
  }

  // ===== FILTERED VIEW =====
  List<Map<String, dynamic>> get _visibleUsers {
    // Ensure current tab is valid for viewer
    if (!_availableTypes.contains(_selectedUserType)) {
      _selectedUserType = _availableTypes.first;
    }

    final list = _users.where((u) => u['type'] == _selectedUserType).where((u) {
      final s = _searchQuery.trim().toLowerCase();
      final matchesQuery = s.isEmpty ||
          (u['username'] as String).toLowerCase().contains(s) ||
          (u['name'] as String).toLowerCase().contains(s) ||
          (u['email'] as String).toLowerCase().contains(s);

      final matchesStatus = _selectedStatus == 'All Statuses' ||
          (u['status'] == 'Active' && _selectedStatus == 'Active') ||
          (u['status'] == 'Inactive' && _selectedStatus == 'Inactive');

      return matchesQuery && matchesStatus;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildTopBar(),
          _buildTypeChips(),
          const SizedBox(height: 10),
          Expanded(child: _buildUserListGlass()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ===== App Bar =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      title: const Text(
        'User Management',
        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: .3, color: Colors.white),
      ),
      centerTitle: false,
    );
  }

  // ===== Search + Filters =====
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Search (glass)
          _glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.search, color: kPrimaryDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _performSmartSearch,
                    cursorColor: kPrimary, // blinking cursor follows role
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search users…',
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchCtrl.clear();
                      _performSmartSearch('');
                    },
                    icon: const Icon(Icons.close, size: 18, color: kMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status filter
          _glass(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none),
              items: const [
                DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v ?? 'All Statuses'),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Type Chips =====
  Widget _buildTypeChips() {
    Widget chip(String label) {
      final selected = _selectedUserType == label;
      return GestureDetector(
        onTap: () => setState(() => _selectedUserType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: [kPrimary, kPrimaryDeep])
                : LinearGradient(colors: [Colors.white, Colors.white.withOpacity(.9)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : kPrimary.withOpacity(.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? kPrimary.withOpacity(.28) : Colors.black.withOpacity(.04),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                label == 'Admin'
                    ? Icons.shield // stable icon
                    : label == 'Moderator'
                        ? Icons.verified_user
                        : Icons.person,
                size: 18,
                color: selected ? Colors.white : kPrimaryDeep,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kPrimaryDeep,
                ),
              ),
              const SizedBox(width: 8),
              _countPill(
                _users.where((u) => u['type'] == label).length,
                selected ? Colors.white.withOpacity(.2) : kPrimary.withOpacity(.08),
                selected ? Colors.white : kPrimaryDeep,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _availableTypes.map((t) => chip(t)).toList(),
      ),
    );
  }

  // ===== List (glass cards) =====
  Widget _buildUserListGlass() {
    final data = _visibleUsers;
    if (data.isEmpty) {
      return Center(
        child: _glass(
          radius: 20,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off, size: 42, color: kMuted),
              SizedBox(height: 10),
              Text('No users found', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Try adjusting your filters', style: TextStyle(color: kMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final user = data[i];
        return _glass(
          radius: 18,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatarForType(user['type']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          user['username'],
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        _statusPill(user['status']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['name'],
                      style: const TextStyle(color: kMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email'],
                      style: const TextStyle(color: kMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user['type'] == 'Moderator' && user['cluster'] != null) ...[
                      const SizedBox(height: 6),
                      _tag('Cluster: ${user['cluster']}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _refinedMenu(user),
            ],
          ),
        );
      },
    );
  }

  // ===== UI helpers =====
  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double radius = 16,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(.90), Colors.white.withOpacity(.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: kPrimary.withOpacity(.18), width: 1.25),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _countPill(int count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _statusPill(String status) {
    final bool active = status == 'Active';
    final Color bg = active ? const Color(0xFFE8F1FF) : const Color(0xFFEDF2FD);
    final Color fg = active ? const Color(0xFF1D4ED8) : const Color(0xFF6477B9);
    final IconData icon = active ? Icons.check_circle : Icons.pause_circle_filled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: kPrimaryDeep, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _avatarForType(String type) {
    final Color c = type == 'Admin'
        ? kPrimaryDeep
        : type == 'Moderator'
            ? _darken(kPrimary, .05)
            : kPrimary.withOpacity(.9);
    return CircleAvatar(
      radius: 26,
      backgroundColor: c.withOpacity(.2),
      child: Icon(
        type == 'Admin'
            ? Icons.shield
            : type == 'Moderator'
                ? Icons.verified_user
                : Icons.person,
        color: c,
      ),
    );
  }

  // ===== Refined Popup Menu (role-based + viewer-aware) =====
  Widget _refinedMenu(Map<String, dynamic> user) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      elevation: 8,
      onSelected: (v) {
        switch (v) {
          case 'view':
            _showUserDetails(user);
            break;
          case 'edit':
            _showEditUser(user);
            break;
          case 'suspend':
            _suspendUser(user);
            break;
          case 'activate':
            _activateUser(user);
            break;
          case 'remove':
            _removeUser(user);
            break;
        }
      },
      itemBuilder: (_) {
        final type = user['type'] as String;        // target user
        final isActive = user['status'] == 'Active';
        final v = widget.viewerRole;                // viewer role
        final items = <PopupMenuEntry<String>>[];

        // Everyone can view visible rows
        items.add(_menuItem('view', Icons.remove_red_eye_rounded, 'View Details'));

        if (v == AppRole.moderator) {
          // Moderator viewer: can only see customers and only view
          return items;
        }

        // Admin viewer:
        if (type == 'Admin') {
          // View only for Admin targets
          return items;
        }

        // Common to Moderator/Customer targets (when viewer is Admin)
        items.add(_menuItem('edit', Icons.edit_rounded, 'Edit'));

        if (isActive) {
          items.add(_menuItem('suspend', Icons.block_rounded, 'Suspend'));
        } else {
          items.add(_menuItem('activate', Icons.check_circle_rounded, 'Activate'));
          if (type == 'Moderator') {
            // Only moderators can be removed when inactive
            items.add(_menuItem('remove', Icons.delete_forever_rounded, 'Remove'));
          }
        }
        return items;
      },
      child: _glass(
        padding: const EdgeInsets.all(8),
        radius: 12,
        child: Icon(Icons.more_horiz, color: kPrimaryDeep),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: kPrimaryDeep),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ===== Responsive View Details Dialog =====
  void _showUserDetails(Map<String, dynamic> user) {
    final type = (user['type'] as String?) ?? '—';
    final status = (user['status'] as String?) ?? '—';
    final isActive = status == 'Active';

    showDialog(
      context: context,
      builder: (_) {
        final size = MediaQuery.of(context).size;
        final double maxDialogWidth = min(size.width - 32, 720); // responsive width

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: SafeArea(
            child: SizedBox(
              width: maxDialogWidth,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ===== Header Banner =====
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimary.withOpacity(.95), _darken(kPrimary, .15)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar glow
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(.15),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                        colors: [Colors.white.withOpacity(.25), Colors.white.withOpacity(.12)],
                                      ),
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      type == 'Admin'
                                          ? Icons.shield
                                          : type == 'Moderator'
                                              ? Icons.verified_user
                                              : Icons.person,
                                      color: Colors.black87,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + status (Wrap)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          (user['username'] as String?) ?? '—',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        _bigStatusPill(isActive ? 'Active' : 'Inactive', isActive),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Role + email (Wrap). Email is a width-aware badge to avoid overflow.
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        _roleBadge(type),
                                        if (user['email'] != null)
                                          _emailBadge(user['email'] as String),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        // ===== Body Content (Responsive & Tidy) =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 520;
                              final List<Widget> tiles = [
                                _infoTile(Icons.badge_outlined, 'Full Name', (user['name'] as String?) ?? '—'),
                                _infoTile(Icons.tag, 'UID', (user['uid'] as String?) ?? '—'),
                                _infoTile(Icons.person_outline, 'Username', (user['username'] as String?) ?? '—'),
                                _infoTile(Icons.email_outlined, 'Email', (user['email'] as String?) ?? '—'),
                                _infoTile(Icons.phone_outlined, 'Phone', (user['phone'] as String?) ?? '—'),
                                _infoTile(Icons.public, 'Country', (user['country'] as String?) ?? '—'),
                                if (user['cluster'] != null)
                                  _infoTile(Icons.account_tree_outlined, 'Cluster', user['cluster'] as String),
                                _infoTile(
                                  Icons.layers_outlined,
                                  'User Type',
                                  type,
                                  chipify: true,
                                ),
                                _infoTile(
                                  isActive ? Icons.verified : Icons.pause_circle_filled,
                                  'Status',
                                  isActive ? 'Active' : 'Inactive',
                                  chipify: true,
                                  chipColor: isActive ? const Color(0xFFE8F1FF) : const Color(0xFFEDF2FD),
                                  chipTextColor: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF6477B9),
                                ),
                              ];

                              if (isWide) {
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: tiles
                                      .map((w) => SizedBox(
                                            width: (constraints.maxWidth - 12) / 2,
                                            child: w,
                                          ))
                                      .toList(),
                                );
                              }
                              return Column(
                                children: tiles
                                    .map((w) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: w,
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, kPrimary.withOpacity(.25), Colors.transparent],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                foregroundColor: kPrimaryDeep,
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Width-aware email chip to prevent Wrap/Row overflows
  Widget _emailBadge(String email) {
    return LayoutBuilder(
      builder: (context, cons) {
        // Force the internal Row to exactly the available width
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cons.maxWidth),
          child: SizedBox(
            width: cons.maxWidth, // <= this guarantees no overflow
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Pretty pieces used in dialog =====
  Widget _bigStatusPill(String label, bool active) {
    final Color bg = active ? const Color(0xFFBEE3F8).withOpacity(.35) : const Color(0xFFE2E8F0);
    final Color fg = Colors.white;
    final IconData icon = active ? Icons.verified : Icons.pause_circle_filled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _roleBadge(String type) {
    final IconData icon =
        type == 'Admin' ? Icons.shield : (type == 'Moderator' ? Icons.verified_user : Icons.person);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    bool chipify = false,
    Color? chipColor,
    Color? chipTextColor,
  }) {
    final tile = _glass(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    )),
                const SizedBox(height: 6),
                if (chipify)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (chipColor ?? kPrimary.withOpacity(.10)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: (chipTextColor ?? kPrimaryDeep).withOpacity(.2)),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: chipTextColor ?? kPrimaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return tile;
  }

  // ===== Edit Dialog (Admin only) =====
  void _showEditUser(Map<String, dynamic> user) {
    // Only Admin can reach here (menu guards this)
    final firstNameController = TextEditingController(
      text: (user['name'] as String).split(' ').isNotEmpty ? user['name'].split(' ').first : '',
    );
    final lastNameController = TextEditingController(
      text: (user['name'] as String).split(' ').length > 1
          ? (user['name'] as String).split(' ').skip(1).join(' ')
          : '',
    );
    final usernameController = TextEditingController(text: user['username']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final countryController = TextEditingController(text: user['country'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _glass(
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text('Edit User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 3, width: 64, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(2))),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _input('First Name *', Icons.person_outline, firstNameController)),
                      const SizedBox(width: 12),
                      Expanded(child: _input('Last Name *', Icons.person_outline, lastNameController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _input('Username *', Icons.person, usernameController, readOnly: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _input('Email *', Icons.email_outlined, emailController, readOnly: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _input('Password', Icons.lock_outline, passwordController, obscure: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _input('Confirm Password', Icons.lock_outline, confirmPasswordController, obscure: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _input('Phone No *', Icons.phone_outlined, phoneController)),
                      const SizedBox(width: 12),
                      Expanded(child: _input('Country *', Icons.public, countryController)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (firstNameController.text.isEmpty ||
                            lastNameController.text.isEmpty ||
                            usernameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            phoneController.text.isEmpty ||
                            countryController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
                          );
                          return;
                        }
                        if (passwordController.text.isNotEmpty &&
                            passwordController.text != confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords do not match')),
                          );
                          return;
                        }

                        setState(() {
                          user['name'] = '${firstNameController.text} ${lastNameController.text}';
                          user['username'] = usernameController.text;
                          user['email'] = emailController.text;
                          user['phone'] = phoneController.text;
                          user['country'] = countryController.text;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User ${user['username']} has been updated.')),
                        );
                      },
                      child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, IconData icon, TextEditingController ctrl, {bool obscure = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _glass(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: ctrl,
            readOnly: readOnly,
            obscureText: obscure,
            cursorColor: kPrimary,
            decoration: InputDecoration(
              icon: Icon(icon, color: kPrimaryDeep),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ===== Actions =====
  void _suspendUser(Map<String, dynamic> user) {
    // Only Admin viewer can get here (menu guarded)
    showDialog(
      context: context,
      builder: (_) => _confirm(
        title: 'Suspend User',
        message: 'Suspend ${user['username']}?',
        confirmLabel: 'Suspend',
        confirmColor: kPrimaryDeep,
        onConfirm: () {
          setState(() => user['status'] = 'Inactive');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ${user['username']} has been suspended.')),
          );
        },
      ),
    );
  }

  void _activateUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => _confirm(
        title: 'Activate User',
        message: 'Activate ${user['username']}?',
        confirmLabel: 'Activate',
        confirmColor: kPrimaryDeep,
        onConfirm: () {
          setState(() => user['status'] = 'Active');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ${user['username']} has been activated.')),
          );
        },
      ),
    );
  }

  void _removeUser(Map<String, dynamic> user) {
    // Only Admin viewer & only inactive moderators (menu guards this)
    showDialog(
      context: context,
      builder: (_) => _confirm(
        title: 'Remove User',
        message: 'Permanently remove ${user['username']}? This cannot be undone.',
        confirmLabel: 'Remove',
        confirmColor: Colors.redAccent,
        onConfirm: () {
          setState(() => _users.remove(user));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ${user['username']} has been removed.')),
          );
        },
      ),
    );
  }

  Widget _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _glass(
        radius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryDeep,
                      side: BorderSide(color: kPrimaryDeep),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== Drawer (same layout you provided) =====
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.supervised_user_circle, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.viewerRole == AppRole.admin ? 'Admin' : 'Moderator',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigating to $title')));
        },
      ),
    );
  }

  // ===== Bottom Navigation (same structure) =====
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
        ],
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
              Icon(icon, color: isSelected ? kPrimary : const Color(0xFF94A3B8), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? kPrimary : const Color(0xFF94A3B8),
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
