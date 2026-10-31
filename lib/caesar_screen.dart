import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _processCipher() {
    String text = messageController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (text.isEmpty) {
      setState(() {
        result = "";
      });
      return;
    }

    int shift = _shiftValue.toInt();
    String processedText = "";

    int effectiveShift = _selectedMode == CaesarMode.encrypt ? shift : -shift;

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);

      if (charCode >= 65 && charCode <= 90) {
        int newCode = ((charCode - 65 + effectiveShift) % 26 + 26) % 26 + 65;
        processedText += String.fromCharCode(newCode);
      } else {
        processedText += String.fromCharCode(charCode);
      }
    }

    setState(() {
      result = processedText;
    });
  }

  void _stepShift(int delta) {
    final int next = (_shiftValue.toInt() + delta).clamp(0, 25);
    setState(() {
      _shiftValue = next.toDouble();
      _processCipher();
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

  void _copyResult(Color primaryColor) {
    if (result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(
          'Result copied to clipboard!',
          'تم نسخ النتيجة إلى الحافظة!',
        )),
        backgroundColor: primaryColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Unified Compact Controls Card (Message + Shift Key & Mode Tabs + Slider)
              _buildControlsCard(context, primaryColor),
              const SizedBox(height: 16),

              // 2. Output Result Card
              _buildResultCard(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context, Color primaryColor) {
    final int shiftInt = _shiftValue.toInt();
    final String formulaStr = _selectedMode == CaesarMode.encrypt
        ? "C = (P + $shiftInt) mod 26"
        : "P = (C − $shiftInt) mod 26";

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Message Input
          TextField(
            controller: messageController,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
            onChanged: (_) => _processCipher(),
            decoration: InputDecoration(
              labelText: tr("Message", "النص (الرسالة)"),
              hintText: tr(
                'Type your message here...',
                'اكتب النص بالإنجليزية هنا...',
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon:
                  Icon(Icons.message_outlined, color: primaryColor, size: 20),
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

          // Row 2: Shift Stepper Pill (Left) + Segmented Encrypt/Decrypt Tabs (Right)
          Row(
            children: [
              // Shift Key Stepper Pill
              Expanded(
                flex: 5,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.pillBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderMedium(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStepBtn(
                        icon: Icons.remove_rounded,
                        onTap: shiftInt > 0 ? () => _stepShift(-1) : null,
                        color: primaryColor,
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              tr("Shift K = $shiftInt", "الإزاحة K = $shiftInt"),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildStepBtn(
                        icon: Icons.add_rounded,
                        onTap: shiftInt < 25 ? () => _stepShift(1) : null,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Unified Segmented Mode Tabs (Encrypt | Decrypt)
              Expanded(
                flex: 5,
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
                          tr("Encrypt", "تشفير"), CaesarMode.encrypt),
                      _buildModePill(
                          tr("Decrypt", "فك التشفير"), CaesarMode.decrypt),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Interactive Shift Slider + Active Formula Badge
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle(context)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr("Shift Slider (0–25)", "شريط مفتاح الإزاحة (0–25)"),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          formulaStr,
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Slider(
                      value: _shiftValue,
                      min: 0,
                      max: 25,
                      divisions: 25,
                      label: shiftInt.toString(),
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withValues(alpha: 0.2),
                      onChanged: (double value) {
                        setState(() {
                          _shiftValue = value;
                          _processCipher();
                        });
                      },
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "0",
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context)),
                        ),
                        Text(
                          "13 (ROT13)",
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context)),
                        ),
                        Text(
                          "25",
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : AppTheme.textMuted(context),
        ),
      ),
    );
  }

  Widget _buildModePill(String label, CaesarMode mode) {
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

  Widget _buildResultCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor, width: 2),
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
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: isArabic ? 0 : 1.2,
                ),
              ),
              if (result.isNotEmpty)
                InkWell(
                  onTap: () => _copyResult(primaryColor),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.copy_rounded,
                        color: primaryColor, size: 18),
                  ),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 12),
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
