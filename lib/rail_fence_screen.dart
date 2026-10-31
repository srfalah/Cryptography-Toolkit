import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

enum RailFenceMode { encrypt, decrypt }

class RailFenceScreen extends StatefulWidget {
  const RailFenceScreen({super.key});

  @override
  State<RailFenceScreen> createState() => _RailFenceScreenState();
}

class _RailFenceScreenState extends State<RailFenceScreen> {
  final TextEditingController messageController = TextEditingController();

  RailFenceMode _selectedMode = RailFenceMode.encrypt;
  int _selectedKey = 2;
  String result = '';

  Color _accent(BuildContext context) => AppTheme.transpositionAccent(context);

  List<List<String>> displayGrid = [];
  List<String> _railSegments = [];
  List<int> _charRailOrigins = [];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  /// Distinct cell background color for each rail (Row 0, Row 1, Row 2)
  Color _railCellBg(BuildContext context, int railIndex) {
    final bool isDark = AppTheme.isDark(context);
    switch (railIndex % 3) {
      case 0:
        return isDark ? const Color(0xFF2563EB) : const Color(0xFF1D4ED8); // Royal Blue
      case 1:
        return isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E); // Emerald Teal
      default:
        return isDark ? const Color(0xFF7C3AED) : const Color(0xFF6D28D9); // Vibrant Purple
    }
  }

  /// High-contrast text color for displaying each rail's segment in the Output Result Card
  Color _railTextColor(BuildContext context, int railIndex) {
    final bool isDark = AppTheme.isDark(context);
    switch (railIndex % 3) {
      case 0:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8); // Blue
      case 1:
        return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E); // Teal
      default:
        return isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9); // Purple
    }
  }

  void _processCipher() {
    String text =
        messageController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (text.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
        _railSegments = [];
        _charRailOrigins = [];
      });
      return;
    }

    if (_selectedMode == RailFenceMode.encrypt) {
      result = _encryptRailFence(text, _selectedKey);
    } else {
      result = _decryptRailFence(text, _selectedKey);
    }
  }

  String _encryptRailFence(String text, int key) {
    List<List<String>> rail = List.generate(
      key,
      (_) => List.filled(text.length, ''),
    );
    bool dirDown = false;
    int row = 0, col = 0;

    for (int i = 0; i < text.length; i++) {
      if (row == 0 || row == key - 1) dirDown = !dirDown;
      rail[row][col++] = text[i];
      dirDown ? row++ : row--;
    }

    String res = "";
    final List<String> segments = [];
    final List<int> origins = [];

    for (int i = 0; i < key; i++) {
      String seg = "";
      for (int j = 0; j < text.length; j++) {
        if (rail[i][j] != '') {
          res += rail[i][j];
          seg += rail[i][j];
          origins.add(i);
        }
      }
      segments.add(seg);
    }

    setState(() {
      displayGrid = rail;
      _railSegments = segments;
      _charRailOrigins = origins;
    });

    return res;
  }

  String _decryptRailFence(String cipher, int key) {
    List<List<String>> rail = List.generate(
      key,
      (_) => List.filled(cipher.length, ''),
    );
    bool dirDown = false;
    int row = 0, col = 0;

    for (int i = 0; i < cipher.length; i++) {
      if (row == 0) dirDown = true;
      if (row == key - 1) dirDown = false;
      rail[row][col++] = '*';
      dirDown ? row++ : row--;
    }

    int index = 0;
    final List<String> segments = [];
    for (int i = 0; i < key; i++) {
      String seg = "";
      for (int j = 0; j < cipher.length; j++) {
        if (rail[i][j] == '*' && index < cipher.length) {
          final String ch = cipher[index++];
          rail[i][j] = ch;
          seg += ch;
        }
      }
      segments.add(seg);
    }

    String res = "";
    final List<int> origins = [];
    row = 0;
    col = 0;
    for (int i = 0; i < cipher.length; i++) {
      if (row == 0) dirDown = true;
      if (row == key - 1) dirDown = false;
      if (rail[row][col] != '*') {
        res += rail[row][col++];
        origins.add(row);
        dirDown ? row++ : row--;
      }
    }

    setState(() {
      displayGrid = rail;
      _railSegments = segments;
      _charRailOrigins = origins;
    });

    return res;
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();

    setState(() {
      messageController.clear();
      _selectedKey = 2;
      _selectedMode = RailFenceMode.encrypt;
      result = '';
      displayGrid = [];
      _railSegments = [];
      _charRailOrigins = [];
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
            tr('Rail Fence Cipher', 'تشفير السياج (Rail Fence)'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.transpositionAppBar(context),
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
              // 1. Unified Compact Controls Card (Message + Rails Tabs & Mode Tabs)
              _buildCompactControlsCard(context, primaryColor),
              const SizedBox(height: 14),

              // 2. Color-Coded Visual Zigzag Grid Card
              if (displayGrid.isNotEmpty) ...[
                _buildVisualizationGrid(context, primaryColor),
                const SizedBox(height: 14),
              ],

              // 3. Color-Coded Output Result Card
              _buildResultCard(context, primaryColor),
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
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary(context)),
            onChanged: (_) => _processCipher(),
            decoration: InputDecoration(
              labelText: tr("Input Message", "النص المدخل"),
              hintText: tr("Enter text here...", "أدخل النص هنا..."),
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

          // Row 2: Rails Selector Pill Tabs (Left) + Segmented Mode Pill Tabs (Right)
          Row(
            children: [
              // Rails Selector (2 Rails | 3 Rails)
              Expanded(
                flex: 5,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.pillBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderMedium(context)),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          tr("Rails:", "السكك:"),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      _buildKeyPill(
                          context, tr("2 Rails", "سكتان (2)"), 2, primaryColor),
                      _buildKeyPill(
                          context, tr("3 Rails", "3 سكك"), 3, primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mode Selector (Encrypt | Decrypt)
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
                        context,
                        tr("Encrypt", "تشفير"),
                        RailFenceMode.encrypt,
                        primaryColor,
                      ),
                      _buildModePill(
                        context,
                        tr("Decrypt", "فك التشفير"),
                        RailFenceMode.decrypt,
                        primaryColor,
                      ),
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

  Widget _buildKeyPill(
    BuildContext context,
    String label,
    int rails,
    Color primaryColor,
  ) {
    final bool isSelected = _selectedKey == rails;
    final bool isDark = AppTheme.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedKey = rails;
            _processCipher();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0284C7) : primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
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

  Widget _buildModePill(
    BuildContext context,
    String label,
    RailFenceMode mode,
    Color primaryColor,
  ) {
    final bool isSelected = _selectedMode == mode;
    final bool isDark = AppTheme.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = mode;
            _processCipher();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0284C7) : primaryColor)
                : Colors.transparent,
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

  Widget _buildVisualizationGrid(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    tr("Visual Grid (Color-Coded Rails)",
                        "الشبكة التوضيحية (تلوين كل صف/سكة)"),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_selectedKey, (r) {
                  final Color c = _railCellBg(context, r);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          tr("R${r + 1}", "صف ${r + 1}"),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _railTextColor(context, r),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
                children: displayGrid.asMap().entries.map((entry) {
                  final int rowIndex = entry.key;
                  final List<String> row = entry.value;
                  final Color rowBg = _railCellBg(context, rowIndex);

                  return Row(
                    children: [
                      // Row Rail Label Badge (R1, R2, R3)
                      Container(
                        width: 34,
                        height: 35,
                        margin: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rowBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: rowBg, width: 1.2),
                        ),
                        child: Text(
                          "R${rowIndex + 1}",
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _railTextColor(context, rowIndex),
                          ),
                        ),
                      ),
                      ...row.map((char) {
                        bool isEmpty = char == '';
                        return Container(
                          width: 35,
                          height: 35,
                          margin: const EdgeInsets.all(2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isEmpty ? Colors.transparent : rowBg,
                            border: Border.all(
                              color: isEmpty
                                  ? AppTheme.borderMedium(context)
                                  : rowBg,
                              width: isEmpty ? 1.0 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            char,
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              color: isEmpty ? Colors.transparent : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          if (result.isEmpty)
            SelectableText(
              tr('Waiting for input...', 'بانتظار إدخال النص...'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted(context),
              ),
            )
          else ...[
            // Color-coded result where each character matches its Rail color!
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText.rich(
                TextSpan(
                  children: List.generate(result.length, (i) {
                    final int railIdx =
                        i < _charRailOrigins.length ? _charRailOrigins[i] : 0;
                    return TextSpan(
                      text: result[i],
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: _railTextColor(context, railIdx),
                      ),
                    );
                  }),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_railSegments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(_railSegments.length, (r) {
                    final String seg = _railSegments[r];
                    if (seg.isEmpty) return const SizedBox.shrink();
                    final Color railCol = _railTextColor(context, r);
                    final Color railBg = _railCellBg(context, r);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: railBg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: railBg.withValues(alpha: 0.45)),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: "R${r + 1}: ",
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                            TextSpan(
                              text: seg,
                              style: TextStyle(
                                color: railCol,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
