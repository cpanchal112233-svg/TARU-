import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../privacy/application/privacy_controller.dart';
import '../../../privacy/application/privacy_providers.dart';
import '../../../privacy/domain/purge_mode.dart';
import '../../application/account_providers.dart';
import '../../domain/account_integrity.dart';

/// Blocking recovery when Auth exists but the account is not normally usable.
class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key, required this.integrity});

  final AccountIntegrity integrity;

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _busy = false;
  String? _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pending = ref.read(pendingSignupIdentityProvider);
    if (_nameController.text.isEmpty && (pending.name ?? '').isNotEmpty) {
      _nameController.text = pending.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isUnavailable =>
      widget.integrity == AccountIntegrity.temporarilyUnavailable;

  bool get _isHealthCleanup =>
      widget.integrity == AccountIntegrity.deletionHealthInProgress;

  bool get _isAccountCleanup =>
      widget.integrity == AccountIntegrity.deletionAccountInProgress;

  bool get _isCleanup => _isHealthCleanup || _isAccountCleanup;

  bool get _isMissingRoot => widget.integrity == AccountIntegrity.missingRoot;

  Future<void> _retryCheck() async {
    ref.invalidate(accountIntegrityProvider);
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).logout();
      ref.read(pendingSignupIdentityProvider).clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Future<void> _continueCleanup() async {
    if (_isHealthCleanup) {
      await _continueHealthCleanup();
    } else if (_isAccountCleanup) {
      await _continueAccountCleanup();
    }
  }

  Future<void> _continueHealthCleanup() async {
    final String? password = await _askPassword('continue health-data cleanup');
    if (password == null || !mounted) return;

    setState(() {
      _busy = true;
      _progress = 'Continuing health-data cleanup…';
    });
    try {
      // Reuses the single Phase 10 PrivacyController destructive path.
      await ref
          .read(privacyControllerProvider)
          .deleteHealthData(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your TARU health data was deleted.')),
      );
      ref.invalidate(accountIntegrityProvider);
    } on PurgeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not finish health-data cleanup. '
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

  Future<void> _continueAccountCleanup() async {
    final String? password = await _askPassword('continue account cleanup');
    if (password == null || !mounted) return;

    setState(() {
      _busy = true;
      _progress = 'Continuing account cleanup…';
    });
    try {
      // Reuses the single Phase 10 PrivacyController destructive path.
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
      ref.invalidate(accountIntegrityProvider);
    } on PurgeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not finish account cleanup. '
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

  Future<void> _finishSetup() async {
    final User? user = ref.read(authStateChangesProvider).value;
    final pending = ref.read(pendingSignupIdentityProvider);
    final String name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (pending.name ?? '');
    final String email = pending.email ?? user?.email ?? '';

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the name for this account.')),
      );
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This login has no email to finish account setup.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(accountRootRepositoryProvider)
          .createIdentityRoot(name: name, email: email);
      pending.clear();
      ref.invalidate(accountIntegrityProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _title {
    if (_isCleanup) return 'Account cleanup';
    if (_isUnavailable) return 'Account setup';
    return 'Account setup';
  }

  String get _body {
    if (_isHealthCleanup) {
      return "TARU couldn't finish removing your health data. "
          'You can continue the trusted cleanup, or sign out.';
    }
    if (_isAccountCleanup) {
      return "TARU couldn't finish removing this account. "
          'You can continue the trusted cleanup, or sign out.';
    }
    if (_isUnavailable) {
      return 'TARU could not confirm this account record. '
          'This can happen when the network is unavailable. '
          'TARU will not create an account record until it can '
          'check safely.';
    }
    return 'TARU cannot load a normal account record for this login. '
        'This can happen after incomplete signup or after an '
        'account deletion that did not finish.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                _body,
                style: TextStyle(height: 1.45, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 24),
              if (_isCleanup) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ElevatedButton(
                      onPressed: _busy ? null : _continueCleanup,
                      child: Text(
                        _isHealthCleanup
                            ? 'Continue health-data cleanup'
                            : 'Continue account cleanup',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This continues TARU’s existing trusted deletion flow. '
                  'TARU does not clear deletion guards from this device.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
              ],
              if (_isMissingRoot) ...<Widget>[
                TextField(
                  controller: _nameController,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ElevatedButton(
                      onPressed: _busy ? null : _finishSetup,
                      child: const Text('Finish account setup'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This only creates the login identity record. It does not '
                  'restore deleted health data.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
              ],
              if (!_isCleanup)
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: OutlinedButton(
                      onPressed: _busy ? null : _retryCheck,
                      child: const Text('Try again'),
                    ),
                  ),
                ),
              if (!_isCleanup) const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
          if (_busy && _progress != null)
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
                        Text(_progress!),
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
