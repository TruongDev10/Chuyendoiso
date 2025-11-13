import 'package:flutter/material.dart';

import '../services/ai_advisor_service.dart';
import '../services/api_key_service.dart';

class AiAdvisorExampleScreen extends StatefulWidget {
  const AiAdvisorExampleScreen({Key? key}) : super(key: key);

  @override
  State<AiAdvisorExampleScreen> createState() => _AiAdvisorExampleScreenState();
}

class _AiAdvisorExampleScreenState extends State<AiAdvisorExampleScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiAdvisorService _advisor = AiAdvisorService();
  final ApiKeyService _keyService = ApiKeyService();

  String? _response;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() {
      _loading = true;
      _response = null;
    });

    try {
      final text = _controller.text.trim();
      if (text.isEmpty) return;
      final res = await _advisor.ask(text);
      setState(() => _response = res);
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveKeyDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Set API key'),
              content: TextField(
                controller: ctrl,
                decoration:
                    const InputDecoration(hintText: 'Paste your API key here'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(c).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(c).pop(true),
                    child: const Text('Save')),
              ],
            ));

    if (ok == true) {
      final saved = await _keyService.saveApiKey(ctrl.text);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(saved ? 'Saved' : 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Advisor Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _saveKeyDialog,
              icon: const Icon(Icons.vpn_key),
              label: const Text('Set API Key'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 6,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ask the AI Advisor...'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _ask,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Ask'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response ?? 'No response yet',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
