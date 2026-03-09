// lib/src/ui/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/aqi_history_store.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  const ProfileScreen({super.key, this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Your Name';
  String _email = 'you@example.com';
  String? _avatarUrl;
  bool _editing = false;

  int? _age;
  bool _smoking = false;
  bool _asthma = false;
  bool _chronic = false;
  String? _chronicDetails;
  String? _gender;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _chronicController;

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _ageController = TextEditingController(text: _age?.toString() ?? '');
    _chronicController = TextEditingController(text: _chronicDetails ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('local_name') ?? _name;
      _email = prefs.getString('local_email') ?? _email;
      _age = prefs.containsKey('local_age') ? prefs.getInt('local_age') : _age;
      _smoking = prefs.getBool('local_smoking') ?? _smoking;
      _asthma = prefs.getBool('local_asthma') ?? _asthma;
      _chronic = prefs.getBool('local_chronic') ?? _chronic;
      _chronicDetails = prefs.getString('local_chronicDetails');
      _gender = prefs.getString('local_gender');
      final storedAvatar = prefs.getString('local_avatarUrl');
      _avatarUrl = (storedAvatar == null || storedAvatar.isEmpty) ? null : storedAvatar;
      _nameController.text = _name;
      _emailController.text = _email;
      _ageController.text = _age?.toString() ?? '';
      _chronicController.text = _chronicDetails ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _chronicController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _changeAvatarDialog() async {
    final controller = TextEditingController(text: _avatarUrl ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change avatar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter image URL (or leave empty to use initials)',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (res == null) return;
    setState(() => _avatarUrl = res.isEmpty ? null : res);
  }

  void _startEditing() {
    _nameController.text = _name;
    _emailController.text = _email;
    _ageController.text = _age?.toString() ?? '';
    _chronicController.text = _chronicDetails ?? '';
    setState(() => _editing = true);
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final ageText = _ageController.text.trim();
    final chronicText = _chronicController.text.trim();

    int? parsedAge;
    if (ageText.isNotEmpty) {
      parsedAge = int.tryParse(ageText);
      if (parsedAge == null || parsedAge <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid age')));
        return;
      }
    }

    setState(() {
      if (newName.isNotEmpty) _name = newName;
      if (newEmail.isNotEmpty) _email = newEmail;
      _age = parsedAge;
      _chronicDetails = chronicText.isEmpty ? null : chronicText;
      _editing = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_name', _name);
    await prefs.setString('local_email', _email);
    if (_age != null) {
      await prefs.setInt('local_age', _age!);
    } else {
      await prefs.remove('local_age');
    }
    await prefs.setBool('local_smoking', _smoking);
    await prefs.setBool('local_asthma', _asthma);
    await prefs.setBool('local_chronic', _chronic);
    await prefs.setString('local_chronicDetails', _chronicDetails ?? '');
    if (_gender != null) {
      await prefs.setString('local_gender', _gender!);
    } else {
      await prefs.remove('local_gender');
    }
    await prefs.setString('local_avatarUrl', _avatarUrl ?? '');
    await prefs.setBool('local_profile_completed', true);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove stored AQI history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      AqiHistoryStore.instance.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AQI history cleared')));
    }
  }

  Widget _healthChips() {
    final chips = <Widget>[];

    if (_age != null) {
      chips.add(Chip(label: Text('Age: $_age')));
    }

    if (_gender != null && _gender!.isNotEmpty) {
      chips.add(Chip(label: Text('Gender: $_gender')));
    }

    if (_smoking) chips.add(const Chip(label: Text('Smoking')));
    if (_asthma) chips.add(const Chip(label: Text('Asthma')));
    if (_chronic) {
      final label = (_chronicDetails != null && _chronicDetails!.isNotEmpty)
          ? 'Chronic: ${_chronicDetails!}'
          : 'Chronic disease';
      chips.add(Chip(label: Text(label)));
    }

    if (chips.isEmpty) {
      return const Text('No health conditions set', style: TextStyle(color: Colors.grey));
    }

    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Future<void> _signOutLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);

    if (widget.onSignOut != null) widget.onSignOut!();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarUrl != null && _avatarUrl!.isNotEmpty
        ? CircleAvatar(radius: 36, backgroundImage: NetworkImage(_avatarUrl!))
        : CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(_initials(_name), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Change avatar',
            icon: const Icon(Icons.image),
            onPressed: _changeAvatarDialog,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOutLocal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _editing
                            ? TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name'))
                            : Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _editing
                            ? TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'))
                            : Text(_email, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (!_editing)
                              OutlinedButton.icon(
                                onPressed: _startEditing,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit profile'),
                              ),
                            if (_editing) ...[
                              ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
                              const SizedBox(width: 8),
                              OutlinedButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel')),
                            ]
                          ],
                        )
                      ]),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Health & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (!_editing) _healthChips(),
                    if (_editing) ...[
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age (years)', hintText: 'e.g. 29'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => _gender = v),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: _smoking,
                        onChanged: (v) => setState(() => _smoking = v),
                        title: const Text('Smoking'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _asthma,
                        onChanged: (v) => setState(() => _asthma = v),
                        title: const Text('Asthma'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _chronic,
                        onChanged: (v) {
                          setState(() {
                            _chronic = v;
                            if (!_chronic) {
                              _chronicDetails = null;
                              _chronicController.text = '';
                            }
                          });
                        },
                        title: const Text('Chronic disease'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_chronic) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _chronicController,
                          decoration: const InputDecoration(
                            labelText: 'Chronic disease details',
                            hintText: 'e.g. Diabetes, COPD, Heart disease',
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'These preferences are used to tailor guidance and alerts (local only).',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('AQI history'),
                    subtitle: const Text('View or clear stored AQI history'),
                    trailing: TextButton(
                      onPressed: () {
                        final len = AqiHistoryStore.instance.records.length;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stored records: $len')));
                      },
                      child: const Text('View'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Clear AQI history'),
                    subtitle: const Text('Removes all locally-stored history'),
                    trailing: ElevatedButton(
                      onPressed: _confirmClearHistory,
                      child: const Text('Clear'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App info'),
                    subtitle: const Text('Version, credits, licenses'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Vayu',
                        applicationVersion: '1.0.0',
                        children: const [Text('Air quality app powered by WAQI')],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share app'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share (TODO)'))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.feedback),
                    label: const Text('Send feedback'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback (TODO)'))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
