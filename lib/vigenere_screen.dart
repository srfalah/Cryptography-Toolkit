import 'package:flutter/material.dart';

enum VigenereMode { encrypt, decrypt }

class VigenereScreen extends StatefulWidget {
  const VigenereScreen({super.key});

  @override
  State<VigenereScreen> createState() => _VigenereScreenState();
}

class _VigenereScreenState extends State<VigenereScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController keywordController = TextEditingController();

  VigenereMode _selectedMode = VigenereMode.encrypt;
  String result = '';
  String repeatedKeyDisplay = '';

  final Color primaryColor = Colors.deepPurple.shade600;

  void _processCipher() {
    String text = messageController.text;
    String keyword = keywordController.text.toUpperCase();

    if (text.isEmpty || keyword.isEmpty || !RegExp(r'^[A-Z]+$').hasMatch(keyword)) {
      setState(() {
        result = '';
        repeatedKeyDisplay = '';
      });
      return;
    }

    String processedText = "";
    String keyMapping = "";
    int keywordIndex = 0;

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);

      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        int base = (charCode >= 65 && charCode <= 90) ? 65 : 97;
        int p = charCode - base;


        String currentKeyChar = keyword[keywordIndex % keyword.length];
        int k = currentKeyChar.codeUnitAt(0) - 65;

        keyMapping += currentKeyChar;

        int newCode;
        if (_selectedMode == VigenereMode.encrypt) {
          newCode = (p + k) % 26 + base;
        } else {
          newCode = (p - k + 26) % 26 + base;
        }

        processedText += String.fromCharCode(newCode);
        keywordIndex++;
      } else {
        processedText += String.fromCharCode(charCode);
        keyMapping += " ";
      }
    }

    setState(() {
      result = processedText;
      repeatedKeyDisplay = keyMapping;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vigenère Cipher', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(messageController, "Message", Icons.message_outlined, 3),
              const SizedBox(height: 16),
              _buildInputField(keywordController, "Keyword (Letters Only)", Icons.vpn_key_outlined, 1),
              const SizedBox(height: 24),
        
        
              if (repeatedKeyDisplay.isNotEmpty) _buildEducationalPreview(),
        
              const SizedBox(height: 24),
              _buildModeSelector(),
              const SizedBox(height: 32),
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Text("How it works (Key Alignment):",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MSG: ${messageController.text}", style: const TextStyle(fontFamily: 'Courier New', fontWeight: FontWeight.bold)),
                Text("KEY: $repeatedKeyDisplay", style: TextStyle(fontFamily: 'Courier New', color: primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String label, IconData icon, int lines) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      onChanged: (_) => _processCipher(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(child: RadioListTile<VigenereMode>(
          title: const Text("Encrypt"), value: VigenereMode.encrypt, groupValue: _selectedMode,
          onChanged: (v) { setState(() => _selectedMode = v!); _processCipher(); }, activeColor: primaryColor,
        )),
        Expanded(child: RadioListTile<VigenereMode>(
          title: const Text("Decrypt"), value: VigenereMode.decrypt, groupValue: _selectedMode,
          onChanged: (v) { setState(() => _selectedMode = v!); _processCipher(); }, activeColor: primaryColor,
        )),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("RESULT", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          SelectableText(
            result.isEmpty ? '...' : result,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Courier New'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}