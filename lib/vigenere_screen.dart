import 'package:flutter/material.dart';
import 'app_theme.dart';

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

  Color _accent(BuildContext context) => AppTheme.purpleAccent(context);

  void _processCipher() {
    String text = messageController.text;
    String keyword = keywordController.text.toUpperCase();

    if (text.isEmpty ||
        keyword.isEmpty ||
        !RegExp(r'^[A-Z]+$').hasMatch(keyword)) {
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

      if ((charCode >= 65 && charCode <= 90) ||
          (charCode >= 97 && charCode <= 122)) {
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

  void _clearAll() {
    FocusScope.of(context).unfocus();

    setState(() {
      messageController.clear();
      keywordController.clear();
      _selectedMode = VigenereMode.encrypt;
      result = '';
      repeatedKeyDisplay = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _accent(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tr('Vigenère Cipher', 'تشفير فيجينير (Vigenère)'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.purpleAppBar(context),
        foregroundColor: Colors.white,
        actions: [
          AppTheme.buildLanguageToggleButton(context),
          IconButton(
            onPressed: _clearAll,
            tooltip: tr('Reset', 'إعادة تعيين'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                context,
                messageController,
                tr("Message", "النص (الرسالة)"),
                Icons.message_outlined,
                3,
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                context,
                keywordController,
                tr("Keyword (Letters Only)", "الكلمة المفتاحية (حروف إنجليزية فقط)"),
                Icons.vpn_key_outlined,
                1,
                primaryColor,
              ),
              const SizedBox(height: 24),
              if (repeatedKeyDisplay.isNotEmpty)
                _buildEducationalPreview(context, primaryColor),
              const SizedBox(height: 24),
              _buildModeSelector(context, primaryColor),
              const SizedBox(height: 32),
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalPreview(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 18,
                color: AppTheme.warningText(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(
                    "How it works (Key Alignment):",
                    "طريقة العمل (محاذاة وتكرار المفتاح مع النص):",
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MSG: ${messageController.text}",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  Text(
                    "KEY: $repeatedKeyDisplay",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
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

  Widget _buildInputField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon,
    int lines,
    Color primaryColor,
  ) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      onChanged: (_) => _processCipher(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, Color primaryColor) {
    return RadioGroup<VigenereMode>(
      groupValue: _selectedMode,
      onChanged: (v) {
        if (v != null) {
          setState(() => _selectedMode = v);
          _processCipher();
        }
      },
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<VigenereMode>(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tr("Encrypt", "تشفير"),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                ),
              ),
              value: VigenereMode.encrypt,
              activeColor: primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: RadioListTile<VigenereMode>(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tr("Decrypt", "فك التشفير"),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                ),
              ),
              value: VigenereMode.decrypt,
              activeColor: primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final Color cardColor = Colors.deepPurple.shade600;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            tr("RESULT", "النتيجة"),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            result.isEmpty ? '...' : result,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Courier New',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
