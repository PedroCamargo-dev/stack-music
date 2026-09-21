import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Settings reconstruída: seções agrupadas, itens com ícone + label + status,
/// chevron se navegável, logout com confirmação. Só mostra o que funciona.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    _apiUrlController =
        TextEditingController(text: context.read<AppState>().downloadApiUrl);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        children: [
          _SectionTitle(label: 'Playback'),
          _SettingItem(
            icon: Icons.equalizer_outlined,
            label: 'Equalizer',
            value: 'Off',
            onTap: null, // não implementado ainda
          ),
          _SettingItem(
            icon: Icons.wifi_tethering_outlined,
            label: 'Stream quality',
            value: 'Auto',
            onTap: null,
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'Interface'),
          _SettingItem(
            icon: Icons.dark_mode_outlined,
            label: 'Theme',
            value: 'Dark',
            onTap: null,
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'Server'),
          _SettingItem(
            icon: Icons.dns_outlined,
            label: 'Navidrome',
            value: app.subsonic?.baseUrl ?? 'Not connected',
            onTap: null,
          ),
          _SettingItem(
            icon: Icons.cloud_download_outlined,
            label: 'Download API',
            value: app.downloadApiUrl.isEmpty ? 'Not set' : app.downloadApiUrl,
            trailing: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary(b)),
              onPressed: () => _editDownloadApi(context, app),
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'Storage'),
          _SettingItem(
            icon: Icons.folder_outlined,
            label: 'Cache size',
            value: '—',
            onTap: null,
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'Account'),
          _SettingItem(
            icon: Icons.person_outline,
            label: 'Username',
            value: app.subsonic?.username ?? '—',
            onTap: null,
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () => _confirmLogout(context, app),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _editDownloadApi(BuildContext context, AppState app) async {
    _apiUrlController.text = app.downloadApiUrl;
    final b = Theme.of(context).brightness;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download API URL'),
        content: TextField(
          controller: _apiUrlController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'http://192.168.0.10:3333',
            filled: true,
            fillColor: AppColors.surface2(b),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () =>
                Navigator.pop(ctx, _apiUrlController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await app.setDownloadApiUrl(result);
    }
  }

  Future<void> _confirmLogout(BuildContext context, AppState app) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Disconnect from Navidrome and clear saved credentials?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await app.disconnect();
      if (mounted) {
        nav.pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary(b),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);

    return ListTile(
      leading: Icon(icon, color: textS),
      title: Text(label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textP)),
      trailing: trailing ??
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: textS)),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: textS),
          ]),
      onTap: onTap,
    );
  }
}