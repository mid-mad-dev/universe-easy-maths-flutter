import 'package:flutter/material.dart';

import '../core/app_constants.dart';

class FirstRunConfigScreen extends StatefulWidget {
  final VoidCallback? onConfigurationSaved;

  const FirstRunConfigScreen({super.key, this.onConfigurationSaved});

  @override
  State<FirstRunConfigScreen> createState() => _FirstRunConfigScreenState();
}

class _FirstRunConfigScreenState extends State<FirstRunConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    final config = await AppConstants.load();
    if (!mounted) return;
    _urlController.text = config.url;
    _keyController.text = config.publishableKey;
  }

  Future<void> _saveAndRestart() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await AppConstants.save(
        Config(
          url: _urlController.text.trim(),
          publishableKey: _keyController.text.trim(),
        ),
      );

      // Re-run the bootstrap so Supabase is initialized from saved config.
      final onConfigurationSaved = widget.onConfigurationSaved;
      if (onConfigurationSaved != null) {
        onConfigurationSaved();
      } else if (mounted) {
        setState(() => _saving = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Could not save config: ${error.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceVariant = colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: const Color(0xFF070C20),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _appTitle(context),
              const SizedBox(height: 6),
              Text(
                'UNIVERSE EASY MATHS needs your Supabase project details before it can start. This screen appears once on a fresh device or when the app cannot reach a configured backend.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: surfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildSectionHeader(context, 'Supabase project'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Supabase project URL',
                            hintText: 'https://your-project.supabase.co',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.cloud_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'URL is required.';
                            }
                            if (!v.startsWith('https://')) {
                              return 'URL must start with https://';
                            }
                            if (v.startsWith('YOUR_')) {
                              return 'Replace the placeholder value.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _keyController,
                          decoration: const InputDecoration(
                            labelText: 'Supabase publishable key',
                            hintText: 'sb_publishable_...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _saveAndRestart(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'Publishable key is required.';
                            }
                            if (v.startsWith('YOUR_')) {
                              return 'Replace the placeholder value.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 28),
                        _buildSectionHeader(context, 'Optional payment setup'),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Razorpay payments are powered by your backend. If payments are not working, set the Razorpay key id on your Supabase project (edge functions), not here.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: surfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 28),
                        _buildActions(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextButton.icon(
                  onPressed: _saving ? null : _resetConfig,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset config to placeholder'),
                  style: TextButton.styleFrom(foregroundColor: surfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.calculate_outlined,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNIVERSE EASY MATHS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'First-run setup',
                style: TextStyle(fontSize: 13, color: Color(0xFF8497B3)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _showResetConfirmation(context),
            child: const Text('CANCEL'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(
            onPressed: _saving ? null : _saveAndRestart,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('SAVE & START'),
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F1422),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset config?'),
        content: const Text(
          'This clears the saved Supabase values and returns you to this setup screen. You can re-enter them after.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _resetConfig();
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetConfig() async {
    try {
      await AppConstants.save(const Config.empty());
      await _loadCurrent();
      if (mounted) _showError('Config reset to placeholder values.');
    } catch (error) {
      if (mounted) _showError('Could not reset config: $error');
    }
  }
}
