import 'package:flutter/material.dart';
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

  void _processCipher() {
    String text = messageController.text.replaceAll(' ', '').toUpperCase();
    if (text.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
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

    setState(() {
      displayGrid = rail;
    });

    String res = "";
    for (int i = 0; i < key; i++) {
      for (int j = 0; j < text.length; j++) {
        if (rail[i][j] != '') res += rail[i][j];
      }
    }
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
    for (int i = 0; i < key; i++) {
      for (int j = 0; j < cipher.length; j++) {
        if (rail[i][j] == '*' && index < cipher.length) {
          rail[i][j] = cipher[index++];
        }
      }
    }

    setState(() {
      displayGrid = rail;
    });

    String res = "";
    row = 0;
    col = 0;
    for (int i = 0; i < cipher.length; i++) {
      if (row == 0) dirDown = true;
      if (row == key - 1) dirDown = false;
      if (rail[row][col] != '*') {
        res += rail[row][col++];
        dirDown ? row++ : row--;
      }
    }
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                tr("Input Message", "النص المدخل"),
                primaryColor,
              ),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary(context)),
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: tr("Enter text here...", "أدخل النص هنا..."),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.message, color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                tr("Select Key (Rails)", "اختر المفتاح (عدد السكك)"),
                primaryColor,
              ),
              RadioGroup<int>(
                groupValue: _selectedKey,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedKey = val;
                      _processCipher();
                    });
                  }
                },
                child: Row(
                  children: [
                    _buildKeyRadioTile(
                        context, tr("2 Rails", "سكتان (2)"), 2, primaryColor),
                    _buildKeyRadioTile(
                        context, tr("3 Rails", "3 سكك"), 3, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildSectionTitle(
                tr("Select Mode", "اختر العملية"),
                primaryColor,
              ),
              RadioGroup<RailFenceMode>(
                groupValue: _selectedMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMode = val;
                      _processCipher();
                    });
                  }
                },
                child: Row(
                  children: [
                    _buildModeRadioTile(
                        context,
                        tr("Encrypt", "تشفير"),
                        RailFenceMode.encrypt,
                        primaryColor),
                    _buildModeRadioTile(
                        context,
                        tr("Decrypt", "فك التشفير"),
                        RailFenceMode.decrypt,
                        primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (displayGrid.isNotEmpty)
                _buildVisualizationGrid(context, primaryColor),
              const SizedBox(height: 20),
              _buildResultCard(context, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizationGrid(BuildContext context, Color primaryColor) {
    final bool isDark = AppTheme.isDark(context);
    final Color filledCellBg =
        isDark ? const Color(0xFF0284C7) : Colors.blueGrey.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          tr("Visual Grid", "الشبكة التوضيحية (المسار المتعرج)"),
          primaryColor,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: displayGrid.map((row) {
                  return Row(
                    children: row.map((char) {
                      bool isEmpty = char == '';
                      return Container(
                        width: 35,
                        height: 35,
                        margin: const EdgeInsets.all(2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isEmpty ? Colors.transparent : filledCellBg,
                          border: Border.all(
                            color: isEmpty
                                ? AppTheme.borderMedium(context)
                                : primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          char,
                          style: TextStyle(
                            color: isEmpty ? Colors.transparent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildKeyRadioTile(
    BuildContext context,
    String title,
    int value,
    Color primaryColor,
  ) {
    return Expanded(
      child: RadioListTile<int>(
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
        value: value,
        activeColor: primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildModeRadioTile(
    BuildContext context,
    String title,
    RailFenceMode mode,
    Color primaryColor,
  ) {
    return Expanded(
      child: RadioListTile<RailFenceMode>(
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

  Widget _buildResultCard(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: result.isEmpty
                  ? AppTheme.textMuted(context)
                  : primaryColor,
              letterSpacing: result.isEmpty && isArabic ? 0 : 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
