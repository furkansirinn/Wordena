import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NameDialog extends StatefulWidget {
  final VoidCallback onNameSaved;

  const NameDialog({required this.onNameSaved, Key? key}) : super(key: key);

  @override
  _NameDialogState createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hoşgeldin! 👋'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Text(
            'Seni tanımak isteriz. Adını söyler misin?',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Adını yaz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveName(),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _saveName,
          child: Text('Başla'),
        ),
      ],
    );
  }

  void _saveName() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen adını gir!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hive'a kaydet
    Hive.box('settingsBox').put('userName', name);
    widget.onNameSaved();
  }
}