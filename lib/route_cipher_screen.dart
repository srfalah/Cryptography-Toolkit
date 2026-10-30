import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RouteCipherMode { encrypt, decrypt }

enum RoutePattern {
  spiralClockwise, // Clockwise inward spiral starting top-left
  snakeVertical, // Top-to-bottom then bottom-to-top by columns
  snakeHorizontal, // Left-to-right then right-to-left by rows
}

class RouteStep {
  final int stepNumber; // 1-based order in route
  final int row;
  final int col;
  final String char;

  RouteStep({
    required this.stepNumber,
    required this.row,
    required this.col,
    required this.char,
  });
}

class RouteCipherScreen extends StatefulWidget {
  const RouteCipherScreen({super.key});

  @override
  State<RouteCipherScreen> createState() => _RouteCipherScreenState();
}

class _RouteCipherScreenState extends State<RouteCipherScreen> {
  final TextEditingController messageController = TextEditingController();

  RouteCipherMode _selectedMode = RouteCipherMode.encrypt;
  RoutePattern _selectedPattern = RoutePattern.spiralClockwise;
  int _selectedCols = 4;

  String result = '';
  List<List<String>> _grid = [];
  List<List<int>> _stepOrderGrid = [];
  List<RouteStep> _routeSteps = [];
  int? _highlightedStep; // 1-based step number

  // Matches the Transposition subsection theme color (Rail-Fence & Row Transposition)
  final Color primaryColor = Colors.blueGrey.shade800;

  @override
  void initState() {
    super.initState();
    _processCipher();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // Generates the ordered list of (row, col) coordinates for the chosen route pattern
  List<(int, int)> _generateRouteCoordinates(
    int rows,
    int cols,
    RoutePattern pattern,
  ) {
    final List<(int, int)> coords = [];

    switch (pattern) {
      case RoutePattern.spiralClockwise:
        int top = 0, bottom = rows - 1;
        int left = 0, right = cols - 1;
        while (top <= bottom && left <= right) {
          // Left to Right along top row
          for (int c = left; c <= right; c++) {
            coords.add((top, c));
          }
          top++;
          // Top to Bottom along right col
          for (int r = top; r <= bottom; r++) {
            coords.add((r, right));
          }
          right--;
          // Right to Left along bottom row
          if (top <= bottom) {
            for (int c = right; c >= left; c--) {
              coords.add((bottom, c));
            }
            bottom--;
          }
          // Bottom to Top along left col
          if (left <= right) {
            for (int r = bottom; r >= top; r--) {
              coords.add((r, left));
            }
            left++;
          }
        }
        break;

      case RoutePattern.snakeVertical:
        for (int c = 0; c < cols; c++) {
          if (c.isEven) {
            for (int r = 0; r < rows; r++) {
              coords.add((r, c));
            }
          } else {
            for (int r = rows - 1; r >= 0; r--) {
              coords.add((r, c));
            }
          }
        }
        break;

      case RoutePattern.snakeHorizontal:
        for (int r = 0; r < rows; r++) {
          if (r.isEven) {
            for (int c = 0; c < cols; c++) {
              coords.add((r, c));
            }
          } else {
            for (int c = cols - 1; c >= 0; c--) {
              coords.add((r, c));
            }
          }
        }
        break;
    }

    return coords;
  }

  void _processCipher() {
    String cleanText =
        messageController.text.replaceAll(' ', '').toUpperCase();

    final int cols = _selectedCols;
    final bool isEmptyInput = cleanText.isEmpty;

    // Show a 4xCols preview matrix with route step numbers even when input is empty
    final int rows = isEmptyInput
        ? 4
        : ((cleanText.length + cols - 1) ~/ cols).clamp(1, 12);

    if (!isEmptyInput) {
      while (cleanText.length < rows * cols) {
        cleanText += 'X';
      }
      if (cleanText.length > rows * cols) {
        cleanText = cleanText.substring(0, rows * cols);
      }
    }

    final List<List<String>> matrix =
        List.generate(rows, (_) => List.filled(cols, ''));
    final List<List<int>> orderMatrix =
        List.generate(rows, (_) => List.filled(cols, 0));

    final List<(int, int)> routeCoords =
        _generateRouteCoordinates(rows, cols, _selectedPattern);

    for (int i = 0; i < routeCoords.length; i++) {
      final (int r, int c) = routeCoords[i];
      orderMatrix[r][c] = i + 1;
    }

    if (isEmptyInput) {
      setState(() {
        _grid = matrix;
        _stepOrderGrid = orderMatrix;
        _routeSteps = [];
        result = '';
        _highlightedStep = null;
      });
      return;
    }

    String computedResult = '';
    final List<RouteStep> steps = [];

    if (_selectedMode == RouteCipherMode.encrypt) {
      // 1. Fill matrix row-by-row
      int idx = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          matrix[r][c] = cleanText[idx++];
        }
      }
      // 2. Read out along the route coordinates
      final StringBuffer sb = StringBuffer();
      for (int i = 0; i < routeCoords.length; i++) {
        final (int r, int c) = routeCoords[i];
        final String ch = matrix[r][c];
        sb.write(ch);
        steps.add(
          RouteStep(
            stepNumber: i + 1,
            row: r,
            col: c,
            char: ch,
          ),
        );
      }
      computedResult = sb.toString();
    } else {
      // Decryption:
      // 1. Fill matrix along the route coordinates
      for (int i = 0; i < routeCoords.length; i++) {
        final (int r, int c) = routeCoords[i];
        final String ch = cleanText[i];
        matrix[r][c] = ch;
        steps.add(
          RouteStep(
            stepNumber: i + 1,
            row: r,
            col: c,
            char: ch,
          ),
        );
      }
      // 2. Read plaintext row-by-row
      final StringBuffer sb = StringBuffer();
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          sb.write(matrix[r][c]);
        }
      }
      computedResult = sb.toString();
    }

    setState(() {
      _grid = matrix;
      _stepOrderGrid = orderMatrix;
      _routeSteps = steps;
      result = computedResult;
      if (_highlightedStep == null || _highlightedStep! > steps.length) {
        _highlightedStep = 1;
      }
    });
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      messageController.clear();
      _selectedCols = 4;
      _selectedMode = RouteCipherMode.encrypt;
      _selectedPattern = RoutePattern.spiralClockwise;
      _highlightedStep = null;
      _processCipher();
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

  String _getPatternDescription() {
    switch (_selectedPattern) {
      case RoutePattern.spiralClockwise:
        return _selectedMode == RouteCipherMode.encrypt
            ? 'Write row-by-row ➔ Read clockwise inward spiral'
            : 'Write clockwise spiral ➔ Read row-by-row';
      case RoutePattern.snakeVertical:
        return _selectedMode == RouteCipherMode.encrypt
            ? 'Write row-by-row ➔ Read alternating Cols ⬇⬆'
            : 'Write alternating Cols ⬇⬆ ➔ Read row-by-row';
      case RoutePattern.snakeHorizontal:
        return _selectedMode == RouteCipherMode.encrypt
            ? 'Write row-by-row ➔ Read alternating Rows ⇄'
            : 'Write alternating Rows ⇄ ➔ Read row-by-row';
    }
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
            Icon(Icons.route_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'Route Cipher',
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
              // 1. Compact Controls Card (Message + Columns + Mode + Route Pattern)
              _buildCompactControlsCard(),
              const SizedBox(height: 12),

              // 2. Side-by-Side Visual Route Matrix & Step Inspector
              _buildVisualWorkspaceCard(),
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
          // Row 1: Message Input
          SizedBox(
            height: 46,
            child: TextField(
              controller: messageController,
              onChanged: (_) => _processCipher(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Input Message',
                hintText: 'e.g., WE ARE DISCOVERED',
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

          // Row 2: Columns Key (3, 4, 5) + Encrypt/Decrypt Toggle
          Row(
            children: [
              // Columns Selector
              Expanded(
                flex: 5,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Cols:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      _buildColPill(3),
                      _buildColPill(4),
                      _buildColPill(5),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mode Selector (Encrypt / Decrypt)
              Expanded(
                flex: 5,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildModePill('Encrypt', RouteCipherMode.encrypt),
                      _buildModePill('Decrypt', RouteCipherMode.decrypt),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Route Path Pattern Selector
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _buildPatternPill('Spiral ↻', RoutePattern.spiralClockwise),
                _buildPatternPill('Snake Cols ⇅', RoutePattern.snakeVertical),
                _buildPatternPill(
                    'Snake Rows ⇄', RoutePattern.snakeHorizontal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColPill(int cols) {
    final bool isSelected = _selectedCols == cols;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCols = cols;
            _processCipher();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$cols',
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

  Widget _buildModePill(String label, RouteCipherMode mode) {
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
          duration: const Duration(milliseconds: 150),
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

  Widget _buildPatternPill(String label, RoutePattern pattern) {
    final bool isSelected = _selectedPattern == pattern;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPattern = pattern;
            _processCipher();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? primaryColor : Colors.blueGrey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualWorkspaceCard() {
    final int rows = _grid.length;
    final int cols = _selectedCols;

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
          // Top Header: Title + Active Route Rule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Route Matrix ($rows×$cols)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Flexible(
                child: Text(
                  _getPatternDescription(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Side-by-Side Row: Compact Route Grid (Left) + Step Path Sequence (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Compact 180x175 Route Matrix with Step Order Badges
              SizedBox(
                width: 180,
                height: 175,
                child: Column(
                  children: List.generate(rows, (r) {
                    return Expanded(
                      child: Row(
                        children: List.generate(cols, (c) {
                          final String ch = _grid[r][c];
                          final int stepNum = _stepOrderGrid[r][c];
                          final bool isHighlighted =
                              _highlightedStep != null &&
                                  stepNum == _highlightedStep;
                          final bool isVisitedBefore =
                              _highlightedStep != null &&
                                  stepNum < _highlightedStep!;

                          Color bgColor = const Color(0xFFF8FAFC);
                          Color borderColor = Colors.blueGrey.shade200;
                          Color textColor = primaryColor;

                          if (isHighlighted) {
                            bgColor = Colors.amber.shade600;
                            borderColor = Colors.amber.shade900;
                            textColor = Colors.white;
                          } else if (isVisitedBefore) {
                            bgColor = primaryColor.withValues(alpha: 0.14);
                            borderColor = primaryColor.withValues(alpha: 0.45);
                            textColor = primaryColor;
                          } else if (ch.isNotEmpty) {
                            bgColor = primaryColor;
                            borderColor = primaryColor;
                            textColor = Colors.white;
                          }

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _highlightedStep = stepNum);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isHighlighted ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Top-left step order number badge
                                    Positioned(
                                      top: 2,
                                      left: 3,
                                      child: Text(
                                        '$stepNum',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: isHighlighted ||
                                                  (ch.isNotEmpty &&
                                                      !isVisitedBefore)
                                              ? Colors.white70
                                              : Colors.blueGrey.shade500,
                                        ),
                                      ),
                                    ),
                                    // Centered Character
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          ch.isEmpty ? '·' : ch,
                                          style: TextStyle(
                                            fontFamily: 'Courier New',
                                            fontSize: rows > 5 ? 11 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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

              // Right: Route Path Sequence Inspector (175px tall)
              Expanded(
                child: SizedBox(
                  height: 175,
                  child: _routeSteps.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              "Numbers 1–${rows * cols} show the route path.\n\nType a message above to trace each step!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey.shade500,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                _highlightedStep != null &&
                                        _highlightedStep! <= _routeSteps.length
                                    ? "Step #$_highlightedStep: '${_routeSteps[_highlightedStep! - 1].char}' at (R${_routeSteps[_highlightedStep! - 1].row + 1}, C${_routeSteps[_highlightedStep! - 1].col + 1})"
                                    : "Tap any step to trace path",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Route Order (Tap to trace):",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: _routeSteps.map((step) {
                                    final bool isSelected =
                                        _highlightedStep == step.stepNumber;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() =>
                                            _highlightedStep = step.stepNumber);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.amber.shade700
                                              : primaryColor.withValues(
                                                  alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.amber.shade900
                                                : primaryColor.withValues(
                                                    alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          "${step.stepNumber}:${step.char}",
                                          style: TextStyle(
                                            fontFamily: 'Courier New',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
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

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 28),
              Text(
                "OUTPUT RESULT",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              if (result.isNotEmpty)
                InkWell(
                  onTap: _copyResult,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.copy_rounded,
                        color: primaryColor, size: 17),
                  ),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            result.isEmpty ? 'Waiting for input...' : result,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: result.isEmpty ? Colors.grey : primaryColor,
              fontFamily: 'Courier New',
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
