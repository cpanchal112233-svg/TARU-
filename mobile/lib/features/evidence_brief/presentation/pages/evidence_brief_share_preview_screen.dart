import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../application/evidence_brief_providers.dart';

/// Shows exactly the text that will be passed to the device share sheet.
class EvidenceBriefSharePreviewScreen extends ConsumerStatefulWidget {
  const EvidenceBriefSharePreviewScreen({super.key});

  @override
  ConsumerState<EvidenceBriefSharePreviewScreen> createState() =>
      _EvidenceBriefSharePreviewScreenState();
}

class _EvidenceBriefSharePreviewScreenState
    extends ConsumerState<EvidenceBriefSharePreviewScreen> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final ShareResultStatus status = await ref.read(
        shareEvidenceBriefProvider,
      )();
      if (!mounted) return;
      if (status == ShareResultStatus.unavailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing is unavailable on this device.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = ref.watch(evidenceBriefShareTextProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Share Preview'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Exact text TARU will share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're about to share health information using another app. "
                    'TARU does not keep a cloud copy of what you share.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Evidence Brief share preview text',
                    child: SelectableText(
                      text.isEmpty ? 'Nothing selected to share yet.' : text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Back to change included sections',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: OutlinedButton(
                          onPressed: _sharing
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Share Evidence Brief plain text',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: FilledButton.icon(
                          onPressed: text.isEmpty || _sharing ? null : _share,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.ios_share_outlined),
                          label: const Text('Share'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
