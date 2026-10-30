import 'package:flutter/material.dart';
import 'app_theme.dart';

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

  Color _accent(BuildContext context) => AppTheme.purpleAccent(context);

  void _processCipher() {
    if (messageController.text.isEmpty) {
      setState(() {
        result = "";
      });
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

  void _clearAll() {
    FocusScope.of(context).unfocus();

    setState(() {
      messageController.clear();
      _shiftValue = 3.0;
      _selectedMode = CaesarMode.encrypt;
      result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _accent(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.text_fields_rounded),
            SizedBox(width: 10),
            Text('Caesar Cipher', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.purpleAppBar(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _clearAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("1. Message", primaryColor),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary(context)),
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.text_fields, color: primaryColor),
                  filled: true,
                  fillColor: AppTheme.cardBg(context),
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle(
                "2. Shift Key: ${_shiftValue.toInt()}",
                primaryColor,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderMedium(context)),
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
                      inactiveColor: primaryColor.withValues(alpha: 0.2),
                      onChanged: (double value) {
                        setState(() {
                          _shiftValue = value;
                          _processCipher();
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "0",
                            style: TextStyle(color: AppTheme.textSecondary(context)),
                          ),
                          Text(
                            "13",
                            style: TextStyle(color: AppTheme.textSecondary(context)),
                          ),
                          Text(
                            "25",
                            style: TextStyle(color: AppTheme.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle("3. Operation", primaryColor),
              RadioGroup<CaesarMode>(
                groupValue: _selectedMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMode = value;
                      _processCipher();
                    });
                  }
                },
                child: Row(
                  children: [
                    _buildRadioTile(
                        context, "Encrypt", CaesarMode.encrypt, primaryColor),
                    _buildRadioTile(
                        context, "Decrypt", CaesarMode.decrypt, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              _buildResultCard(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    String title,
    CaesarMode mode,
    Color primaryColor,
  ) {
    return Expanded(
      child: RadioListTile<CaesarMode>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary(context),
          ),
        ),
        value: mode,
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildResultCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            "OUTPUT RESULT",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
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
