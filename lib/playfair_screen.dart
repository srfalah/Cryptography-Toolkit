import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PlayfairMode { encrypt, decrypt }

class PlayfairStep {
  final String inputPair;
  final String outputPair;
  final String ruleName;
  final String shortRule;
  final int r1, c1;
  final int r2, c2;
  final int outR1, outC1;
  final int outR2, outC2;

  PlayfairStep({
    required this.inputPair,
    required this.outputPair,
    required this.ruleName,
    required this.shortRule,
    required this.r1,
    required this.c1,
    required this.r2,
    required this.c2,
    required this.outR1,
    required this.outC1,
    required this.outR2,
    required this.outC2,
  });
}

class PlayfairScreen extends StatefulWidget {
  const PlayfairScreen({super.key});

  @override
  State<PlayfairScreen> createState() => _PlayfairScreenState();
}

class _PlayfairScreenState extends State<PlayfairScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController keywordController = TextEditingController();

  PlayfairMode _selectedMode = PlayfairMode.encrypt;
  String result = '';

  // 5x5 Matrix state
  List<List<String>> _matrix = [];
  Set<String> _keywordChars = {};
  List<PlayfairStep> _steps = [];
  int? _selectedStepIndex;

  // Matches the Substitution section theme color (Caesar & Vigenère)
  final Color primaryColor = Colors.deepPurple.shade600;

  @override
  void initState() {
    super.initState();
    _buildKeyMatrix('');
  }

  @override
  void dispose() {
    messageController.dispose();
    keywordController.dispose();
    super.dispose();
  }

  void _buildKeyMatrix(String rawKeyword) {
    final String cleanKey = rawKeyword
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .replaceAll('J', 'I');

    final Set<String> used = {};
    final Set<String> fromKey = {};

    for (int i = 0; i < cleanKey.length; i++) {
      final String ch = cleanKey[i];
      used.add(ch);
      fromKey.add(ch);
    }

    const String alphabet = 'ABCDEFGHIKLMNOPQRSTUVWXYZ'; // J merged with I
    for (int i = 0; i < alphabet.length; i++) {
      used.add(alphabet[i]);
    }

    final List<String> flat = used.toList();
    _matrix = List.generate(
      5,
      (r) => List.generate(5, (c) => flat[r * 5 + c]),
    );
    _keywordChars = fromKey;
  }

  List<String> _prepareDigraphs(String rawText, PlayfairMode mode) {
    final String cleaned = rawText
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .replaceAll('J', 'I');

    if (cleaned.isEmpty) return [];

    final List<String> pairs = [];

    if (mode == PlayfairMode.encrypt) {
      int i = 0;
      while (i < cleaned.length) {
        final String first = cleaned[i];
        if (i + 1 < cleaned.length) {
          final String second = cleaned[i + 1];
          if (first == second) {
            final String filler = (first == 'X') ? 'Q' : 'X';
            pairs.add('$first$filler');
            i += 1;
          } else {
            pairs.add('$first$second');
            i += 2;
          }
        } else {
          final String pad = (first == 'X') ? 'Q' : 'X';
          pairs.add('$first$pad');
          i += 1;
        }
      }
    } else {
      int i = 0;
      while (i < cleaned.length) {
        final String first = cleaned[i];
        if (i + 1 < cleaned.length) {
          pairs.add('$first${cleaned[i + 1]}');
          i += 2;
        } else {
          final String pad = (first == 'X') ? 'Q' : 'X';
          pairs.add('$first$pad');
          i += 1;
        }
      }
    }

    return pairs;
  }

  (int, int) _findPosition(String ch) {
    final String target = ch == 'J' ? 'I' : ch;
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (_matrix[r][c] == target) {
          return (r, c);
        }
      }
    }
    return (0, 0);
  }

  void _processCipher() {
    _buildKeyMatrix(keywordController.text);

    final List<String> pairs =
        _prepareDigraphs(messageController.text, _selectedMode);

    if (pairs.isEmpty) {
      setState(() {
        result = '';
        _steps = [];
        _selectedStepIndex = null;
      });
      return;
    }

    final List<PlayfairStep> computedSteps = [];
    final StringBuffer outBuffer = StringBuffer();
    final int shift = (_selectedMode == PlayfairMode.encrypt) ? 1 : 4;

    for (final String pair in pairs) {
      final String a = pair[0];
      final String b = pair[1];
      final (int r1, int c1) = _findPosition(a);
      final (int r2, int c2) = _findPosition(b);

      int outR1, outC1, outR2, outC2;
      String rule;
      String shortRule;

      if (r1 == r2) {
        outR1 = r1;
        outC1 = (c1 + shift) % 5;
        outR2 = r2;
        outC2 = (c2 + shift) % 5;
        rule = _selectedMode == PlayfairMode.encrypt
            ? 'Same Row ➔ Shift Right'
            : 'Same Row ➔ Shift Left';
        shortRule = _selectedMode == PlayfairMode.encrypt ? 'Row ➔' : 'Row ⬅';
      } else if (c1 == c2) {
        outR1 = (r1 + shift) % 5;
        outC1 = c1;
        outR2 = (r2 + shift) % 5;
        outC2 = c2;
        rule = _selectedMode == PlayfairMode.encrypt
            ? 'Same Col ➔ Shift Down'
            : 'Same Col ➔ Shift Up';
        shortRule = _selectedMode == PlayfairMode.encrypt ? 'Col ⬇' : 'Col ⬆';
      } else {
        outR1 = r1;
        outC1 = c2;
        outR2 = r2;
        outC2 = c1;
        rule = 'Rectangle ➔ Swap Columns';
        shortRule = 'Rect ⬌';
      }

      final String outA = _matrix[outR1][outC1];
      final String outB = _matrix[outR2][outC2];
      final String outPair = '$outA$outB';

      outBuffer.write(outPair);
      computedSteps.add(
        PlayfairStep(
          inputPair: pair,
          outputPair: outPair,
          ruleName: rule,
          shortRule: shortRule,
          r1: r1,
          c1: c1,
          r2: r2,
          c2: c2,
          outR1: outR1,
          outC1: outC1,
          outR2: outR2,
          outC2: outC2,
        ),
      );
    }

    setState(() {
      result = outBuffer.toString();
      _steps = computedSteps;
      if (_selectedStepIndex == null ||
          _selectedStepIndex! >= computedSteps.length) {
        _selectedStepIndex = 0;
      }
    });
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      messageController.clear();
      keywordController.clear();
      _selectedMode = PlayfairMode.encrypt;
      result = '';
      _steps = [];
      _selectedStepIndex = null;
      _buildKeyMatrix('');
    });
  }

  void _copyResult() {
    if (result.isEmpty) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Result copied to clipboard!'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Icon(Icons.grid_on_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'Playfair Cipher',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Compact Inputs + Mode Row
              _buildCompactControlsCard(),
              const SizedBox(height: 12),

              // 2. Side-by-Side Compact 5x5 Matrix & Digraph Inspector
              _buildCompactWorkspaceCard(),
              const SizedBox(height: 12),

              // 3. Compact Output Result Card
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactControlsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Message Input
          SizedBox(
            height: 46,
            child: TextField(
              controller: messageController,
              onChanged: (_) => _processCipher(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'e.g., INSTRUMENTS',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
          const SizedBox(height: 10),

          // Keyword Input + Encrypt/Decrypt Toggle in the Same Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: keywordController,
                    onChanged: (_) => _processCipher(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Keyword',
                      hintText: 'e.g., MONARCHY',
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildModePill('Encrypt', PlayfairMode.encrypt),
                      _buildModePill('Decrypt', PlayfairMode.decrypt),
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

  Widget _buildModePill(String label, PlayfairMode mode) {
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.blueGrey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWorkspaceCard() {
    final PlayfairStep? activeStep = (_selectedStepIndex != null &&
            _selectedStepIndex! < _steps.length)
        ? _steps[_selectedStepIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
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
          // Top Header: Title + Color Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "5×5 Key Matrix & Digraphs",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(
                      primaryColor.withValues(alpha: 0.25), "Key", primaryColor),
                  const SizedBox(width: 8),
                  _buildLegendDot(
                      Colors.amber.shade600, "In", Colors.amber.shade800),
                  const SizedBox(width: 8),
                  _buildLegendDot(
                      Colors.teal.shade600, "Out", Colors.teal.shade800),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Side-by-Side Row: Compact 5x5 Grid (Left) + Digraph Pairs Inspector (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Compact 175x175 5x5 Matrix
              SizedBox(
                width: 175,
                height: 175,
                child: Column(
                  children: List.generate(5, (r) {
                    return Expanded(
                      child: Row(
                        children: List.generate(5, (c) {
                          final String ch = _matrix[r][c];
                          final bool isFromKeyword = _keywordChars.contains(ch);

                          final bool isInputCell = activeStep != null &&
                              ((activeStep.r1 == r && activeStep.c1 == c) ||
                                  (activeStep.r2 == r && activeStep.c2 == c));
                          final bool isOutputCell = activeStep != null &&
                              ((activeStep.outR1 == r &&
                                      activeStep.outC1 == c) ||
                                  (activeStep.outR2 == r &&
                                      activeStep.outC2 == c));

                          Color bgColor = const Color(0xFFF8FAFC);
                          Color borderColor = Colors.grey.shade300;
                          Color textColor = Colors.blueGrey.shade900;

                          if (isOutputCell) {
                            bgColor = Colors.teal.shade600;
                            borderColor = Colors.teal.shade800;
                            textColor = Colors.white;
                          } else if (isInputCell) {
                            bgColor = Colors.amber.shade600;
                            borderColor = Colors.amber.shade800;
                            textColor = Colors.white;
                          } else if (isFromKeyword) {
                            bgColor = primaryColor.withValues(alpha: 0.12);
                            borderColor = primaryColor.withValues(alpha: 0.45);
                            textColor = primaryColor;
                          }

                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: borderColor,
                                  width:
                                      (isInputCell || isOutputCell) ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  ch == 'I' ? 'I/J' : ch,
                                  style: TextStyle(
                                    fontFamily: 'Courier New',
                                    fontSize: ch == 'I' ? 10.5 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),

              // Right: Digraph Pairs & Active Rule Panel (matches 175px height)
              Expanded(
                child: SizedBox(
                  height: 175,
                  child: _steps.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              "Type a message above to see digraph pairs & matrix rules.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Active Rule Banner
                            if (activeStep != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.amber.shade300),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "'${activeStep.inputPair}' ➔ '${activeStep.outputPair}'",
                                      style: TextStyle(
                                        fontFamily: 'Courier New',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    Text(
                                      activeStep.ruleName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              "Tap a pair to inspect:",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Scrollable Grid of Digraph Chips
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children:
                                      List.generate(_steps.length, (index) {
                                    final step = _steps[index];
                                    final bool isSelected =
                                        _selectedStepIndex == index;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _selectedStepIndex = index);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : primaryColor.withValues(
                                                  alpha: 0.07),
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : primaryColor.withValues(
                                                    alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          "${step.inputPair}➔${step.outputPair}",
                                          style: TextStyle(
                                            fontFamily: 'Courier New',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
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

  Widget _buildLegendDot(Color bg, String label, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final String pairedResult = _steps.map((s) => s.outputPair).join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.28),
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
              const Text(
                "OUTPUT RESULT",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              if (result.isNotEmpty)
                InkWell(
                  onTap: _copyResult,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy_rounded,
                        color: Colors.white, size: 17),
                  ),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            result.isEmpty ? 'Waiting for input...' : result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Courier New',
              letterSpacing: 1.5,
            ),
          ),
          if (pairedResult.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Pairs: $pairedResult",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Courier New',
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
