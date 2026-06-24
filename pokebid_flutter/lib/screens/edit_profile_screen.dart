import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../i18n/strings.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _igCtrl;
  late String _selectedEmoji;

  bool _saving = false;
  String? _usernameError;

  static const _emojiOptions = [
    '🎴', '🃏', '⭐', '🔥', '💎', '🏆', '🐉', '🌟',
    '🦋', '🎯', '🎮', '🚀', '🌈', '🎪', '🎨', '🦄',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _igCtrl = TextEditingController(text: widget.profile.igHandle);
    _selectedEmoji = widget.profile.avatarEmoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _igCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim().toLowerCase();

    if (name.isEmpty) {
      _showError(L.errEnterDisplayName);
      return;
    }
    if (username.isEmpty || username.length < 3) {
      setState(() => _usernameError = L.errUsernameTooShort);
      return;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError = L.errUsernameChars);
      return;
    }

    setState(() { _saving = true; _usernameError = null; });

    // Check username uniqueness
    final taken = await ProfileService.isUsernameTaken(username, AuthService.userId);
    if (taken) {
      setState(() { _usernameError = L.errUsernameTaken; _saving = false; });
      return;
    }

    final ok = await ProfileService.updateProfile(
      displayName: name,
      username: username,
      avatarEmoji: _selectedEmoji,
      bio: _bioCtrl.text.trim(),
      igHandle: _igCtrl.text.trim().replaceAll('@', ''),
    );

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L.profileUpdated),
          backgroundColor: const Color(0xFF16A34A),
        ));
      } else {
        _showError(L.errSaveFailed);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: const Color(0xFFE74C3C)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(L.editProfile,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFFE8A52A), strokeWidth: 2))
                  : Text(L.save,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: Color(0xFFE8A52A))),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Avatar emoji picker ──────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8A52A), width: 2),
                ),
                child: Center(child: Text(_selectedEmoji,
                    style: const TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 8),
              Text(L.chooseAvatar,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ]),
          ),
          const SizedBox(height: 12),

          // Emoji grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _emojiOptions.map((e) => GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: e == _selectedEmoji
                        ? const Color(0xFFE8A52A).withOpacity(0.15)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: e == _selectedEmoji
                          ? const Color(0xFFE8A52A)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(child: Text(e,
                      style: const TextStyle(fontSize: 22))),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Form fields ──────────────────────────────────────────────
          _card(children: [
            _field(
              label: L.displayNameLabel,
              hint: L.displayNameHint,
              controller: _nameCtrl,
              icon: Icons.person_outline,
            ),
            _divider(),
            _field(
              label: L.usernameLabel,
              hint: 'pokecollector123',
              controller: _usernameCtrl,
              icon: Icons.alternate_email,
              prefix: '@',
              error: _usernameError,
              onChanged: (_) => setState(() => _usernameError = null),
            ),
          ]),
          const SizedBox(height: 12),

          _card(children: [
            _field(
              label: L.bioLabel,
              hint: L.bioHint,
              controller: _bioCtrl,
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 12),

          _card(children: [
            _field(
              label: 'Instagram',
              hint: 'your_ig_handle',
              controller: _igCtrl,
              icon: Icons.camera_alt_outlined,
              prefix: '@',
            ),
          ]),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF3F4F6),
          indent: 16, endIndent: 16);

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? prefix,
    String? error,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF))),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              TextField(
                controller: controller,
                maxLines: maxLines,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  prefixText: prefix,
                  prefixStyle: const TextStyle(
                      fontSize: 15, color: Color(0xFF9CA3AF)),
                  hintText: hint,
                  hintStyle: const TextStyle(
                      color: Color(0xFFD1D5DB), fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 4),
                Text(error, style: const TextStyle(
                    fontSize: 11, color: Color(0xFFE74C3C))),
              ],
            ])),
          ]),
        ]),
      );
}
