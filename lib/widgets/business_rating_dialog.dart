import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

Future<bool> showBusinessRatingDialog(
  BuildContext context, {
  required String providerId,
  required String sourceType,
  required String sourceId,
  required String providerName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _BusinessRatingDialog(
      providerId: providerId,
      sourceType: sourceType,
      sourceId: sourceId,
      providerName: providerName,
    ),
  );
  return result ?? false;
}

class _BusinessRatingDialog extends StatefulWidget {
  final String providerId;
  final String sourceType;
  final String sourceId;
  final String providerName;

  const _BusinessRatingDialog({
    required this.providerId,
    required this.sourceType,
    required this.sourceId,
    required this.providerName,
  });

  @override
  State<_BusinessRatingDialog> createState() => _BusinessRatingDialogState();
}

class _BusinessRatingDialogState extends State<_BusinessRatingDialog> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _saving = true);
    final ok = await context.read<AppState>().submitBusinessRating(
      providerId: widget.providerId,
      sourceType: widget.sourceType,
      sourceId: widget.sourceId,
      rating: _rating,
      comment: _commentController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit your rating. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.providerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            children: List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1} stars',
                onPressed: _saving
                    ? null
                    : () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_outline,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            ),
          ),
          TextField(
            controller: _commentController,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || _rating == 0 ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit rating'),
        ),
      ],
    );
  }
}
