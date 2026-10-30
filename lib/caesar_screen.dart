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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tr('Caesar Cipher', 'تشفير قيصر (Caesar)'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.purpleAppBar(context),
        foregroundColor: Colors.white,
        elevation: 0,
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
              _buildSectionTitle(
                tr("1. Message", "1. النص (الرسالة)"),
                primaryColor,
              ),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary(context)),
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: tr(
                    'Type your message here...',
                    'اكتب النص بالإنجليزية هنا...',
                  ),
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
                tr(
                  "2. Shift Key: ${_shiftValue.toInt()}",
                  "2. مفتاح الإزاحة: ${_shiftValue.toInt()}",
                ),
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
              _buildSectionTitle(
                tr("3. Operation", "3. العملية"),
                primaryColor,
              ),
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
                        context,
                        tr("Encrypt", "تشفير"),
                        CaesarMode.encrypt,
                        primaryColor),
                    _buildRadioTile(
                        context,
                        tr("Decrypt", "فك التشفير"),
                        CaesarMode.decrypt,
                        primaryColor),
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
      padding: const EdgeInsetsDirectional.only(bottom: 10, start: 5),
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        value: mode,
        activeColor: primaryColor,
        contentPadding: EdgeInsets.zero,
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
            tr("OUTPUT RESULT", "النتيجة النهائية"),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: isArabic ? 0 : 1.2,
            ),
          ),
          const SizedBox(height: 15),
          SelectableText(
            result.isEmpty
                ? tr('Waiting for input...', 'بانتظار إدخال النص...')
                : result,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily:
                  result.isEmpty && isArabic ? 'Cairo' : 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}
