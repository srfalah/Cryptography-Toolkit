import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

enum RowTransMode { encrypt, decrypt }

class RowTranspositionScreen extends StatefulWidget {
  const RowTranspositionScreen({super.key});

  @override
  State<RowTranspositionScreen> createState() => _RowTranspositionScreenState();
}

class _RowTranspositionScreenState extends State<RowTranspositionScreen> {
  final TextEditingController messageController = TextEditingController();

  int _keyLength = 4;
  late List<TextEditingController> _squareControllers;
  late List<FocusNode> _squareFocusNodes;
  late List<FocusNode> _listenerFocusNodes;

  RowTransMode _selectedMode = RowTransMode.encrypt;
  String result = '';
  String? errorMessage;

  Color _accent(BuildContext context) => AppTheme.transpositionAccent(context);

  List<List<String>> displayGrid = [];
  List<int> _charColOrigins = [];
  List<({int orderNum, int colIndex, String segment})> _orderedColSegments = [];

  // Distinct educational colors per column (up to 7 columns)
  Color _colCellBg(int colIndex, {bool isHeader = false}) {
    switch (colIndex % 7) {
      case 0: // Column 1: Royal Blue
        return isHeader ? const Color(0xFF1E3A8A) : const Color(0xFF1D4ED8);
      case 1: // Column 2: Emerald Teal
        return isHeader ? const Color(0xFF134E4A) : const Color(0xFF0F766E);
      case 2: // Column 3: Vibrant Purple
        return isHeader ? const Color(0xFF4C1D95) : const Color(0xFF6D28D9);
      case 3: // Column 4: Amber Orange
        return isHeader ? const Color(0xFF7C2D12) : const Color(0xFFC2410C);
      case 4: // Column 5: Rose Magenta
        return isHeader ? const Color(0xFF831843) : const Color(0xFFBE185D);
      case 5: // Column 6: Cyan Sky
        return isHeader ? const Color(0xFF0C4A6E) : const Color(0xFF0369A1);
      default: // Column 7: Forest Green
        return isHeader ? const Color(0xFF14532D) : const Color(0xFF15803D);
    }
  }

  Color _colTextColor(BuildContext context, int colIndex) {
    final bool isDark = AppTheme.isDark(context);
    switch (colIndex % 7) {
      case 0: // Column 1: Blue
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case 1: // Column 2: Teal
        return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
      case 2: // Column 3: Purple
        return isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9);
      case 3: // Column 4: Orange
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
      case 4: // Column 5: Rose
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D);
      case 5: // Column 6: Sky
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
      default: // Column 7: Green
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    }
  }

  @override
  void initState() {
    super.initState();
    _initKeySquares(_keyLength);
  }

  void _initKeySquares(int length, {List<String>? initialValues}) {
    _squareControllers = List.generate(
      length,
      (i) => TextEditingController(
        text: (initialValues != null && i < initialValues.length)
            ? initialValues[i]
            : '',
      ),
    );
    _squareFocusNodes = List.generate(length, (_) => FocusNode());
    _listenerFocusNodes =
        List.generate(length, (_) => FocusNode(skipTraversal: true));
  }

  void _disposeKeySquares() {
    for (final c in _squareControllers) {
      c.dispose();
    }
    for (final f in _squareFocusNodes) {
      f.dispose();
    }
    for (final l in _listenerFocusNodes) {
      l.dispose();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _disposeKeySquares();
    super.dispose();
  }

  void _changeKeyLength(int newLength) {
    if (newLength == _keyLength) return;
    final List<String> preserved = _squareControllers
        .take(newLength)
        .map((c) => c.text)
        .toList();
    _disposeKeySquares();
    setState(() {
      _keyLength = newLength;
      _initKeySquares(newLength, initialValues: preserved);
      _processCipher();
    });
  }

  String _getAssembledKey() {
    return _squareControllers.map((c) => c.text.trim()).join();
  }

  bool _isCompleteKeyFilled() {
    return _squareControllers.every((c) => c.text.trim().isNotEmpty);
  }

  void _autoGenerateValidKey() {
    FocusScope.of(context).unfocus();
    final List<int> digits = List.generate(_keyLength, (i) => i + 1);
    digits.shuffle(Random());
    // Avoid identity 1,2,3... so transposition is visually interesting
    bool isIdentity = true;
    for (int i = 0; i < digits.length; i++) {
      if (digits[i] != i + 1) {
        isIdentity = false;
        break;
      }
    }
    if (isIdentity && digits.length >= 2) {
      final int tmp = digits[0];
      digits[0] = digits[1];
      digits[1] = tmp;
    }

    setState(() {
      for (int i = 0; i < _keyLength; i++) {
        _squareControllers[i].text = digits[i].toString();
      }
      _processCipher();
    });
  }

  void _clearKeySquares() {
    setState(() {
      for (final c in _squareControllers) {
        c.clear();
      }
      result = '';
      displayGrid = [];
      _charColOrigins = [];
      _orderedColSegments = [];
      errorMessage = null;
    });
    if (_squareFocusNodes.isNotEmpty) {
      _squareFocusNodes.first.requestFocus();
    }
  }

  void _onSquareChanged(int index, String val) {
    if (val.isNotEmpty) {
      // Keep only the last typed digit if multiple characters arrived
      final String lastChar = val.substring(val.length - 1);
      if (_squareControllers[index].text != lastChar) {
        _squareControllers[index].text = lastChar;
        _squareControllers[index].selection =
            const TextSelection.collapsed(offset: 1);
      }
      // Auto-advance to the next square!
      if (index + 1 < _keyLength) {
        _squareFocusNodes[index + 1].requestFocus();
      } else {
        _squareFocusNodes[index].unfocus();
      }
    }
    _processCipher();
  }

  void _fillNextEmptySquareWithDigit(int digit) {
    int targetIndex =
        _squareControllers.indexWhere((c) => c.text.trim().isEmpty);
    if (targetIndex == -1) {
      // If all squares are full, check if any square is currently focused
      targetIndex = _squareFocusNodes.indexWhere((f) => f.hasFocus);
      if (targetIndex == -1) return;
    }
    setState(() {
      _squareControllers[targetIndex].text = digit.toString();
    });
    if (targetIndex + 1 < _keyLength) {
      _squareFocusNodes[targetIndex + 1].requestFocus();
    } else {
      _squareFocusNodes[targetIndex].unfocus();
    }
    _processCipher();
  }

  void _processCipher() {
    String text =
        messageController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final bool allFilled = _isCompleteKeyFilled();
    final String key = _getAssembledKey();

    if (key.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
        _charColOrigins = [];
        _orderedColSegments = [];
        errorMessage = null;
      });
      return;
    }

    // Check individual squares for out-of-range or duplicate digits immediately
    final List<String> entered = _squareControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final s in entered) {
      final int? d = int.tryParse(s);
      if (d == null || d < 1 || d > _keyLength) {
        setState(() {
          result = '';
          displayGrid = [];
          _charColOrigins = [];
          _orderedColSegments = [];
          errorMessage = tr(
            "Each square must contain a digit between 1 and $_keyLength.",
            "كل مربع يجب أن يحتوي على رقم بين 1 و $_keyLength.",
          );
        });
        return;
      }
    }

    if (entered.toSet().length != entered.length) {
      setState(() {
        result = '';
        displayGrid = [];
        _charColOrigins = [];
        _orderedColSegments = [];
        errorMessage = tr(
          "Duplicate digits detected! Use each number from 1 to $_keyLength once.",
          "يوجد تكرار في الأرقام! استخدم كل رقم من 1 إلى $_keyLength مرة واحدة فقط.",
        );
      });
      return;
    }

    if (!allFilled || text.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
        _charColOrigins = [];
        _orderedColSegments = [];
        errorMessage = null;
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    if (_selectedMode == RowTransMode.encrypt) {
      result = _encryptRowTransposition(text, key);
    } else {
      result = _decryptRowTransposition(text, key);
    }
  }

  String _encryptRowTransposition(String text, String key) {
    while (text.length % key.length != 0) {
      text += 'X';
    }

    int cols = key.length;
    int rows = text.length ~/ cols;

    List<List<String>> grid = List.generate(rows, (_) => List.filled(cols, ''));
    int textIndex = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c] = text[textIndex++];
      }
    }

    List<List<String>> disp = [];
    disp.add(key.split(''));
    disp.addAll(grid);

    String res = "";
    final List<int> origins = [];
    final List<({int orderNum, int colIndex, String segment})> segments = [];

    for (int i = 1; i <= cols; i++) {
      int colIndex = key.indexOf(i.toString());
      if (colIndex != -1) {
        final StringBuffer segBuf = StringBuffer();
        for (int r = 0; r < rows; r++) {
          final String ch = grid[r][colIndex];
          res += ch;
          segBuf.write(ch);
          origins.add(colIndex);
        }
        segments.add((
          orderNum: i,
          colIndex: colIndex,
          segment: segBuf.toString(),
        ));
      }
    }

    setState(() {
      displayGrid = disp;
      _charColOrigins = origins;
      _orderedColSegments = segments;
    });
    return res;
  }

  String _decryptRowTransposition(String cipher, String key) {
    while (cipher.length % key.length != 0) {
      cipher += 'X';
    }

    int cols = key.length;
    int rows = cipher.length ~/ cols;

    List<List<String>> grid = List.generate(rows, (_) => List.filled(cols, ''));
    final List<({int orderNum, int colIndex, String segment})> segments = [];

    int cipherIndex = 0;
    for (int i = 1; i <= cols; i++) {
      int colIndex = key.indexOf(i.toString());
      if (colIndex != -1) {
        final StringBuffer segBuf = StringBuffer();
        for (int r = 0; r < rows; r++) {
          final String ch = cipher[cipherIndex++];
          grid[r][colIndex] = ch;
          segBuf.write(ch);
        }
        segments.add((
          orderNum: i,
          colIndex: colIndex,
          segment: segBuf.toString(),
        ));
      }
    }

    List<List<String>> disp = [];
    disp.add(key.split(''));
    disp.addAll(grid);

    String res = "";
    final List<int> origins = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        res += grid[r][c];
        origins.add(c);
      }
    }

    setState(() {
      displayGrid = disp;
      _charColOrigins = origins;
      _orderedColSegments = segments;
    });
    return res;
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();

    setState(() {
      messageController.clear();
      for (final c in _squareControllers) {
        c.clear();
      }
      _selectedMode = RowTransMode.encrypt;
      result = '';
      displayGrid = [];
      _charColOrigins = [];
      _orderedColSegments = [];
      errorMessage = null;
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
            tr('Row Transposition', 'تبديل الصفوف (Row Transposition)'),
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
              // 1. Unified Controls Card (Message + Columns Tabs & Mode Tabs + Auto-Advancing Key Squares)
              _buildCompactControlsCard(context, primaryColor),
              const SizedBox(height: 14),

              // 2. Visual Matrix Grid Card
              if (displayGrid.isNotEmpty) ...[
                _buildVisualizationGrid(context, primaryColor),
                const SizedBox(height: 14),
              ],

              // 3. Output Result Card
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Input Message
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

          // Row 2: Columns Count Selector (3, 4, 5, 6, 7) + Segmented Mode Tabs (Encrypt | Decrypt)
          Row(
            children: [
              // Columns Count Selector
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
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          tr("Cols:", "أعمدة:"),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      for (final int cols in [3, 4, 5, 6, 7])
                        _buildColCountPill(context, cols, primaryColor),
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
                        context,
                        tr("Encrypt", "تشفير"),
                        RowTransMode.encrypt,
                        primaryColor,
                      ),
                      _buildModePill(
                        context,
                        tr("Decrypt", "فك التشفير"),
                        RowTransMode.decrypt,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Interactive Auto-Advancing Key Squares Section
          _buildKeySquaresSection(context, primaryColor),
        ],
      ),
    );
  }

  Widget _buildKeySquaresSection(BuildContext context, Color primaryColor) {
    final bool isDark = AppTheme.isDark(context);
    final List<String> allValues =
        _squareControllers.map((c) => c.text.trim()).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorMessage != null
              ? AppTheme.errorBorder(context)
              : AppTheme.borderSubtle(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Label + Random Key & Clear Key Action Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_column_rounded,
                          size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        tr(
                          "Column Key Squares (1 to $_keyLength)",
                          "مربعات المفتاح الرقمي (من 1 إلى $_keyLength)",
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _autoGenerateValidKey,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.casino_outlined,
                              size: 13, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            tr("Random", "عشوائي"),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _clearKeySquares,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.pillBg(context),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderMedium(context)),
                      ),
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row of Auto-Advancing Little Squares (Always LTR so Col 1..Col N match the matrix)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_keyLength, (index) {
                final String val = allValues[index];
                final int? parsed = int.tryParse(val);
                final bool isOutOfRange =
                    parsed != null && (parsed < 1 || parsed > _keyLength);
                final bool isDuplicate = val.isNotEmpty &&
                    allValues.where((v) => v == val).length > 1;
                final bool hasError = isOutOfRange || isDuplicate;
                final bool isFilled = val.isNotEmpty && !hasError;
                final Color colColor = _colTextColor(context, index);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _colCellBg(index),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "C${index + 1}",
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 46,
                          child: KeyboardListener(
                            focusNode: _listenerFocusNodes[index],
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.backspace &&
                                  _squareControllers[index].text.isEmpty &&
                                  index > 0) {
                                _squareFocusNodes[index - 1].requestFocus();
                              }
                            },
                            child: TextField(
                              controller: _squareControllers[index],
                              focusNode: _squareFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onTap: () {
                                // Select existing digit so typing immediately replaces it
                                _squareControllers[index].selection =
                                    TextSelection(
                                  baseOffset: 0,
                                  extentOffset:
                                      _squareControllers[index].text.length,
                                );
                              },
                              onChanged: (v) => _onSquareChanged(index, v),
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasError
                                    ? AppTheme.errorText(context)
                                    : (isFilled
                                        ? colColor
                                        : AppTheme.textPrimary(context)),
                              ),
                              decoration: InputDecoration(
                                hintText: '${index + 1}',
                                hintStyle: TextStyle(
                                  fontFamily: 'Courier New',
                                  fontSize: 14,
                                  color: AppTheme.textMuted(context)
                                      .withValues(alpha: 0.4),
                                ),
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: hasError
                                    ? AppTheme.errorBg(context)
                                    : (isFilled
                                        ? colColor.withValues(
                                            alpha: isDark ? 0.2 : 0.1)
                                        : AppTheme.cardBg(context)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: hasError
                                        ? AppTheme.errorBorder(context)
                                        : (isFilled
                                            ? colColor.withValues(alpha: 0.75)
                                            : colColor.withValues(alpha: 0.35)),
                                    width: isFilled || hasError ? 1.8 : 1.1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: hasError
                                        ? AppTheme.errorBorder(context)
                                        : colColor,
                                    width: 2.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Quick-Tap Available Digit Pills (1..N) + Validation Message
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.errorText(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr("Tap or type digits:", "اضغط أو اكتب الأرقام:"),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Wrap(
                    spacing: 4,
                    children: List.generate(_keyLength, (i) {
                      final int digit = i + 1;
                      final bool used = allValues.contains(digit.toString());
                      return GestureDetector(
                        onTap: used
                            ? null
                            : () => _fillNextEmptySquareWithDigit(digit),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: used
                                ? AppTheme.successBg(context)
                                : primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: used
                                  ? AppTheme.successBorder(context)
                                  : primaryColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            used ? "$digit✓" : "$digit",
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: used
                                  ? AppTheme.successText(context)
                                  : primaryColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildColCountPill(
    BuildContext context,
    int cols,
    Color primaryColor,
  ) {
    final bool isSelected = _keyLength == cols;
    final bool isDark = AppTheme.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeKeyLength(cols),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0284C7) : primaryColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$cols',
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
    );
  }

  Widget _buildModePill(
    BuildContext context,
    String label,
    RowTransMode mode,
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
    final bool isDark = AppTheme.isDark(context);
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
          Text(
            tr(
              "Visual Grid (Color-Coded Columns)",
              "الشبكة التوضيحية (أعمدة ملونة)",
            ),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              int colsCount = displayGrid[0].length + 1;
              double calculatedWidth =
                  ((constraints.maxWidth - 10) / colsCount) - 4;
              double cellWidth = calculatedWidth < 35 ? 35 : calculatedWidth;

              return Directionality(
                textDirection: TextDirection.ltr,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: displayGrid.asMap().entries.map((entry) {
                      int rowIndex = entry.key;
                      List<String> row = entry.value;
                      bool isHeader = rowIndex == 0;

                      return Row(
                        children: [
                          Container(
                            width: cellWidth,
                            height: 40,
                            margin: const EdgeInsets.all(2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isHeader
                                  ? Colors.blueGrey.shade900
                                  : (isDark
                                      ? Colors.blueGrey.shade800
                                      : Colors.blueGrey.shade200),
                              border:
                                  Border.all(color: Colors.blueGrey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isHeader ? '#' : rowIndex.toString(),
                              style: TextStyle(
                                color: isHeader || isDark
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: isHeader ? 18 : 14,
                              ),
                            ),
                          ),
                          ...row.asMap().entries.map((colEntry) {
                            final int colIndex = colEntry.key;
                            final String char = colEntry.value;
                            final Color cellBg =
                                _colCellBg(colIndex, isHeader: isHeader);

                            return Container(
                              width: cellWidth,
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cellBg,
                                border: Border.all(
                                  color: isHeader
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : cellBg,
                                  width: isHeader ? 1.8 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                char,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isHeader
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                                  fontSize: isHeader ? 18 : 16,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Color primaryColor) {
    final bool isDark = AppTheme.isDark(context);
    return Container(
      width: double.infinity,
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
          if (result.isEmpty)
            SelectableText(
              tr('Waiting for input...', 'بانتظار إدخال النص...'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted(context),
                letterSpacing: isArabic ? 0 : 2.0,
              ),
            )
          else ...[
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText.rich(
                TextSpan(
                  children: List.generate(result.length, (i) {
                    final int colOrigin =
                        (i < _charColOrigins.length) ? _charColOrigins[i] : 0;
                    return TextSpan(
                      text: result[i],
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _colTextColor(context, colOrigin),
                        letterSpacing: 2.0,
                      ),
                    );
                  }),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_orderedColSegments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _orderedColSegments.map((item) {
                    final Color colColor =
                        _colTextColor(context, item.colIndex);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: colColor.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: colColor.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "#${item.orderNum} (C${item.colIndex + 1}): ",
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colColor,
                            ),
                          ),
                          Text(
                            item.segment,
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: colColor,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
