import 'package:flutter/material.dart';

enum CaesarMode { encrypt, decrypt }

class CaesarScreen extends StatefulWidget {
  const CaesarScreen({super.key});

  @override
  State<CaesarScreen> createState() => _CaesarScreenState();
}

class _CaesarScreenState extends State<CaesarScreen> {
  final TextEditingController messageController = TextEditingController();


  double _shiftValue = 3.0;
  CaesarMode _selectedMode = CaesarMode.encrypt;
  String result = '';

  final Color primaryColor = Colors.deepPurple.shade600;

  void _processCipher() {
    if (messageController.text.isEmpty) {
      setState(() { result = ""; });
      return;
    }

    String text = messageController.text;
    int shift = _shiftValue.toInt();
    String processedText = "";

    int effectiveShift = _selectedMode == CaesarMode.encrypt ? shift : -shift;

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);

      if (charCode >= 65 && charCode <= 90) {
        int newCode = ((charCode - 65 + effectiveShift) % 26 + 26) % 26 + 65;
        processedText += String.fromCharCode(newCode);
      } else if (charCode >= 97 && charCode <= 122) {
        int newCode = ((charCode - 97 + effectiveShift) % 26 + 26) % 26 + 97;
        processedText += String.fromCharCode(newCode);
      } else {
        processedText += String.fromCharCode(charCode);
      }
    }

    setState(() {
      result = processedText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Caesar Cipher', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildSectionTitle("1. Message"),
              TextField(
                controller: messageController,
                maxLines: 3,
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.text_fields, color: primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
        
              _buildSectionTitle("2. Shift Key: ${_shiftValue.toInt()}"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Slider(
                      value: _shiftValue,
                      min: 0,
                      max: 25,
                      divisions: 25,
                      label: _shiftValue.toInt().toString(),
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (double value) {
                        setState(() {
                          _shiftValue = value;
                          _processCipher();
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("0"), Text("13"), Text("25")],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),
        
              _buildSectionTitle("3. Operation"),
              Row(
                children: [
                  _buildRadioTile("Encrypt", CaesarMode.encrypt),
                  _buildRadioTile("Decrypt", CaesarMode.decrypt),
                ],
              ),
              const SizedBox(height: 35),
        
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildRadioTile(String title, CaesarMode mode) {
    return Expanded(
      child: RadioListTile<CaesarMode>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: mode,
        groupValue: _selectedMode,
        onChanged: (value) {
          setState(() {
            _selectedMode = value!;
            _processCipher();
          });
        },
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        children: [
          Text("OUTPUT RESULT", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          SelectableText(
            result.isEmpty ? 'Waiting for input...' : result,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}