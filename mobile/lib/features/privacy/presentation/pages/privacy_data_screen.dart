import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/reliability/reliability_providers.dart';
import '../../../../core/reliability/user_facing_error.dart';
import '../../application/privacy_controller.dart';
import '../../application/privacy_providers.dart';
import '../../domain/purge_mode.dart';
import 'your_data_in_taru_screen.dart';

class PrivacyDataScreen extends ConsumerStatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  ConsumerState<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends ConsumerState<PrivacyDataScreen> {
  bool _busy = false;
  String? _progress;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _progress = 'Preparing export…';
    });
    try {
      final ShareResultStatus status = await ref
          .read(privacyControllerProvider)
          .exportHealthData(
            onProgress: (String step) {
              if (mounted) setState(() => _progress = step);
            },
          );
      if (!mounted) return;
      if (status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export was created. Sharing was cancelled. '
              'TARU removed its temporary copy; copies you saved elsewhere '
              'are outside TARU’s control.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export ready. TARU does not keep a cloud copy of the archive.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export failed. No complete archive was produced. '
            '${userFacingErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<String?> _askPassword(String actionLabel) async {
    final TextEditingController controller = TextEditingController();
    bool hidePassword = true;
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Confirm password to $actionLabel'),
              content: SingleChildScrollView(
                child: TextField(
                  controller: controller,
                  obscureText: hidePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      tooltip: hidePassword ? 'Show password' : 'Hide password',
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (password == null || password.isEmpty) return null;
    return password;
  }

  Future<void> _deleteHealthData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete my health data?'),
          content: const Text(
            'This permanently removes your TARU health profile, conditions, '
            'allergies, medications, dose and lifestyle history, routine '
            'preferences, measurements, reports, and reviewed extracted text.\n\n'
            'Your login and name/email account identity stay. '
            'This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final String? password = await _askPassword('delete your health data');
    if (password == null || !mounted) return;

    setState(() {
      _busy = true;
      _progress = 'Deleting health data…';
    });
    try {
      await ref
          .read(privacyControllerProvider)
          .deleteHealthData(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your TARU health data was deleted.')),
      );
      Navigator.pop(context);
    } on PurgeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_purgeMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete health data. ${userFacingErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? exportFirst = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete TARU account'),
          content: const Text(
            'This removes your health data and your login.\n\n'
            'Optional: export your data first. Export is not required.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Export first'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continue without export'),
            ),
          ],
        );
      },
    );
    if (exportFirst == null || !mounted) return;
    if (exportFirst) {
      await _export();
      if (!mounted) return;
    }

    final TextEditingController confirmController = TextEditingController();
    final bool? typedOk = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Type DELETE to confirm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Removes profile, conditions, allergies, medications, history, '
                  'measurements, reports, reviewed text, and your login.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  confirmController.text.trim() == 'DELETE',
                );
              },
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    confirmController.dispose();
    if (typedOk != true || !mounted) return;

    final String? password = await _askPassword('delete your TARU account');
    if (password == null || !mounted) return;

    setState(() {
      _busy = true;
      _progress = 'Deleting account…';
    });
    try {
      final AccountDeleteOutcome outcome = await ref
          .read(privacyControllerProvider)
          .deleteAccount(password: password);
      if (!mounted) return;
      if (outcome == AccountDeleteOutcome.dataPurgedAuthRemaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your TARU health data was removed, but your login could not '
              'yet be deleted. Please reauthenticate and try again.',
            ),
          ),
        );
        final String? retryPassword = await _askPassword(
          'finish deleting your login',
        );
        if (retryPassword != null) {
          await ref
              .read(privacyControllerProvider)
              .retryAuthDelete(password: retryPassword);
        }
      }
      // AuthGate will show login when signed out.
    } on PurgeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_purgeMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete account. ${userFacingErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  String _purgeMessage(PurgeException error) {
    switch (error.code) {
      case PurgeFailureCode.recentAuthRequired:
        return 'Please confirm your password again, then retry.';
      case PurgeFailureCode.unauthenticated:
        return 'You need to be signed in.';
      case PurgeFailureCode.purgeRetryRequired:
        return 'Deletion did not finish. Please try again.';
      case PurgeFailureCode.purgeFailed:
      case PurgeFailureCode.unknown:
        return 'Deletion failed. Your account was not removed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> guard = ref.watch(deletionGuardActiveProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Privacy & data'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                'Control your TARU health data. Exports stay on this device '
                'until you share or save them. A TARU archive contains the '
                'information you stored — it is not a certified medical '
                'record. TARU does not email exports or keep a cloud copy of '
                'the archive.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              if (guard.asData?.value == true) ...<Widget>[
                const SizedBox(height: 16),
                Material(
                  color: const Color(0xffFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'A deletion is in progress for this account. '
                      'Health writes are paused. If this persists, retry '
                      'Delete health data from this screen.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _ActionCard(
                title: 'Your data in TARU',
                subtitle:
                    'See what kinds of information TARU keeps, where it comes '
                    'from, and what TARU does not do with it.',
                onTap: _busy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const YourDataInTaruScreen(),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 12),
              _CrashDiagnosticsTile(),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Export my health data',
                subtitle:
                    'Create a ZIP archive of the information you stored — '
                    'profile, history, measurements, reports, and reviewed '
                    'extracted text when present. Not a certified medical '
                    'record.',
                onTap: _busy ? null : _export,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Delete my health data',
                subtitle: 'Remove health information but keep your TARU login.',
                onTap: _busy ? null : _deleteHealthData,
                destructive: true,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Delete TARU account',
                subtitle: 'Remove your health data and login permanently.',
                onTap: _busy ? null : _deleteAccount,
                destructive: true,
              ),
            ],
          ),
          if (_busy)
            ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_progress ?? 'Working…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CrashDiagnosticsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled =
        ref.watch(crashDiagnosticsControllerProvider).value ?? false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: SwitchListTile(
        value: enabled,
        onChanged: (bool value) {
          ref
              .read(crashDiagnosticsControllerProvider.notifier)
              .setEnabled(value);
        },
        title: const Text(
          'Share crash diagnostics',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Allow TARU to send technical crash information to help diagnose '
          'app failures. TARU does not intentionally attach health '
          'information. Native collection follows this choice from the next '
          'launch.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.35),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: destructive ? const Color(0xffB91C1C) : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
