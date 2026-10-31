import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String normalizedMessageDisplay = '';
  String repeatedKeyDisplay = '';

  Color _accent(BuildContext context) => AppTheme.purpleAccent(context);

  @override
  void dispose() {
    messageController.dispose();
    keywordController.dispose();
    super.dispose();
  }

  void _processCipher() {
    String text =
        messageController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    String keyword =
        keywordController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    if (text.isEmpty ||
        keyword.isEmpty ||
        !RegExp(r'^[A-Z]+$').hasMatch(keyword)) {
      setState(() {
        result = '';
        normalizedMessageDisplay = '';
        repeatedKeyDisplay = '';
      });
      return;
    }

    String processedText = "";
    String keyMapping = "";
    int keywordIndex = 0;

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);

      if (charCode >= 65 && charCode <= 90) {
        int p = charCode - 65;

        String currentKeyChar = keyword[keywordIndex % keyword.length];
        int k = currentKeyChar.codeUnitAt(0) - 65;

        keyMapping += currentKeyChar;

        int newCode;
        if (_selectedMode == VigenereMode.encrypt) {
          newCode = (p + k) % 26 + 65;
        } else {
          newCode = (p - k + 26) % 26 + 65;
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
      normalizedMessageDisplay = text;
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
      normalizedMessageDisplay = '';
      repeatedKeyDisplay = '';
    });
  }

  void _copyResult() {
    if (result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(
          'Result copied to clipboard!',
          'تم نسخ النتيجة إلى الحافظة!',
        )),
        backgroundColor: Colors.deepPurple.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Unified Compact Controls Card (Message + Keyword & Encrypt/Decrypt Tabs)
              _buildCompactControlsCard(context, primaryColor),
              const SizedBox(height: 14),

              // 2. Live Key Alignment Preview
              if (repeatedKeyDisplay.isNotEmpty) ...[
                _buildEducationalPreview(context, primaryColor),
                const SizedBox(height: 14),
              ],

              // 3. Output Result Card
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactControlsCard(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Message Input
          TextField(
            controller: messageController,
            maxLines: 2,
            minLines: 1,
            onChanged: (_) => _processCipher(),
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              labelText: tr("Message", "النص (الرسالة)"),
              hintText: tr("e.g., ATTACKATDAWN", "مثال: ATTACKATDAWN"),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon:
                  Icon(Icons.message_outlined, color: primaryColor, size: 19),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Keyword Input (Left) + Segmented Encrypt/Decrypt Tabs (Right)
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: keywordController,
                    onChanged: (_) => _processCipher(),
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary(context)),
                    decoration: InputDecoration(
                      labelText: tr("Keyword", "الكلمة المفتاحية"),
                      hintText: tr("e.g., LEMON", "مثال: LEMON"),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.vpn_key_outlined,
                          color: primaryColor, size: 19),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.pillBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderMedium(context)),
                  ),
                  child: Row(
                    children: [
                      _buildModePill(
                          tr("Encrypt", "تشفير"), VigenereMode.encrypt),
                      _buildModePill(
                          tr("Decrypt", "فك التشفير"), VigenereMode.decrypt),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModePill(String label, VigenereMode mode) {
    final bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = mode;
            _processCipher();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationalPreview(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                    "MSG: $normalizedMessageDisplay",
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

  Widget _buildResultCard() {
    final Color cardColor = Colors.deepPurple.shade600;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 28),
              Text(
                tr("OUTPUT RESULT", "النتيجة النهائية"),
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: isArabic ? 0 : 1.2,
                ),
              ),
              if (result.isNotEmpty)
                InkWell(
                  onTap: _copyResult,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy_rounded,
                        color: Colors.white, size: 18),
                  ),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            result.isEmpty
                ? tr('Waiting for input...', 'بانتظار إدخال النص...')
                : result,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily:
                  result.isEmpty && isArabic ? 'Cairo' : 'Courier New',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
