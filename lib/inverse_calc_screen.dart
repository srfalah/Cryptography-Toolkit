import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

class InverseCalcScreen extends StatefulWidget {
  const InverseCalcScreen({super.key});

  @override
  State<InverseCalcScreen> createState() => _InverseCalcScreenState();
}

class _InverseCalcScreenState extends State<InverseCalcScreen> {
  final TextEditingController eController = TextEditingController();
  final TextEditingController phiController = TextEditingController();

  List<Map<String, dynamic>> tableRows = [];

  // Result data (the algorithm itself is unchanged)
  BigInt? _eVal;
  BigInt? _phiVal;
  BigInt? _gcd;
  BigInt? _rawX;
  BigInt? _inverse;
  bool get _hasResult => _gcd != null;
  bool get _hasInverse => _inverse != null;

  String? _inputError;
  String? _inputWarning;
  final Set<int> _expandedRows = {};

  Color _accent(BuildContext context) => AppTheme.tealAccent(context);

  @override
  void dispose() {
    eController.dispose();
    phiController.dispose();
    super.dispose();
  }

  void _calculateInverse() {
    FocusScope.of(context).unfocus();
    tableRows.clear();
    _expandedRows.clear();
    setState(() {
      _eVal = null;
      _phiVal = null;
      _gcd = null;
      _rawX = null;
      _inverse = null;
      _inputError = null;
      _inputWarning = null;
    });

    if (eController.text.trim().isEmpty || phiController.text.trim().isEmpty) {
      setState(() => _inputError = 'Please enter both e and φ(n).');
      return;
    }

    try {
      BigInt e = BigInt.parse(eController.text.trim());
      BigInt phi = BigInt.parse(phiController.text.trim());

      BigInt a = phi;
      BigInt b = e;
      BigInt x = BigInt.zero;
      BigInt y = BigInt.one;

      while (b > BigInt.zero) {
        BigInt q = a ~/ b;
        BigInt r = a % b;
        BigInt z = x - (q * y);

        tableRows.add({
          'q': q,
          'a': a,
          'b': b,
          'r': r,
          'x': x,
          'y': y,
          'z': z,
        });

        a = b;
        b = r;
        x = y;
        y = z;
      }

      tableRows.add({
        'q': '-',
        'a': a,
        'b': 0,
        'r': '-',
        'x': x,
        'y': '-',
        'z': '-',
      });

      BigInt? d;
      if (a == BigInt.one) {
        d = x < BigInt.zero ? x + phi : x;
      }

      setState(() {
        _eVal = e;
        _phiVal = phi;
        _gcd = a;
        _rawX = x;
        _inverse = d;
        if (e >= phi) {
          _inputWarning =
              'e is not smaller than φ(n). The table still works, but usually 1 < e < φ(n).';
        }
      });
    } catch (err) {
      setState(() => _inputError = 'Please enter valid numerical values.');
    }
  }

  void _resetFields() {
    FocusScope.of(context).unfocus();

    setState(() {
      eController.clear();
      phiController.clear();
      tableRows.clear();
      _expandedRows.clear();
      _eVal = null;
      _phiVal = null;
      _gcd = null;
      _rawX = null;
      _inverse = null;
      _inputError = null;
      _inputWarning = null;
    });
  }

  void _copyInverse() {
    if (_inverse == null) return;
    Clipboard.setData(ClipboardData(text: _inverse.toString()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('d = $_inverse copied to clipboard!'),
        backgroundColor: Colors.green.shade700,
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
        title: const Text(
          'Extended Euclidean',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.tealAppBar(context),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _resetFields,
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGoalBadge(context, primaryColor),
              const SizedBox(height: 16),
              Text(
                "Inputs",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Divider(
                thickness: 1.5,
                color: primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      eController,
                      'Value (e)',
                      'e.g. 7',
                      primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      context,
                      phiController,
                      'Modulus φ(n)',
                      'e.g. 40',
                      primaryColor,
                    ),
                  ),
                ],
              ),
              if (_inputError != null)
                _buildNotice(
                  context,
                  _inputError!,
                  AppTheme.errorBg(context),
                  AppTheme.errorBorder(context),
                  AppTheme.errorText(context),
                  Icons.error_outline_rounded,
                ),
              if (_inputWarning != null)
                _buildNotice(
                  context,
                  _inputWarning!,
                  AppTheme.warningBg(context),
                  AppTheme.warningBorder(context),
                  AppTheme.warningText(context),
                  Icons.warning_amber_rounded,
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateInverse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "CALCULATE STEPS",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (tableRows.isNotEmpty) ...[
                Text(
                  "Calculation Steps",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any row to see its formulas with the numbers plugged in.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 10),
                _buildModernTable(context, primaryColor),
                const SizedBox(height: 10),
                _buildLegend(context),
                const SizedBox(height: 22),
                _buildResultCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalBadge(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'GOAL',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted(context),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'd ≡ e⁻¹ (mod φ(n))   ⇔   e · d ≡ 1 (mod φ(n))',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(
    BuildContext context,
    String message,
    Color bg,
    Color border,
    Color fg,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint,
    Color primaryColor,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'Courier New',
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary(context),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: (_) => _calculateInverse(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.textMuted(context),
          fontWeight: FontWeight.normal,
        ),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: primaryColor),
      ),
      keyboardType: TextInputType.number,
    );
  }

  // Palette used to colour a value as it travels diagonally down the table
  List<Color> _chainPalette(BuildContext context) => [
        AppTheme.orangeAccent(context),
        AppTheme.transpositionAccent(context),
        AppTheme.purpleAccent(context),
      ];

  Color _chainColor(BuildContext context, int chain) {
    final palette = _chainPalette(context);
    return palette[((chain % 3) + 3) % 3];
  }

  Widget _buildModernTable(BuildContext context, Color primaryColor) {
    final int lastIndex = tableRows.length - 1;
    final Color divisionColor = primaryColor;
    final Color coeffColor = AppTheme.purpleAccent(context);

    // Size columns to fit the largest number
    int maxLen = 1;
    for (final row in tableRows) {
      for (final k in ['q', 'a', 'b', 'r', 'x', 'y', 'z']) {
        final s = row[k].toString();
        if (s.length > maxLen) maxLen = s.length;
      }
    }
    final double minCell = (maxLen * 9.0 + 18).clamp(48.0, 400.0);
    const double stepW = 38;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW = ((constraints.maxWidth - stepW - 2) / 7)
            .clamp(minCell, double.infinity);
        final double totalW = stepW + cellW * 7;

        Widget headerCell(String t, Color bg) => Container(
              width: cellW,
              padding: const EdgeInsets.symmetric(vertical: 9),
              color: bg,
              alignment: Alignment.center,
              child: Text(
                t,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );

        Widget groupCell(String t, int cols, Color bg) => Container(
              width: cellW * cols,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: bg,
              alignment: Alignment.center,
              child: Text(
                t,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  letterSpacing: 1.0,
                ),
              ),
            );

        final Color divDark = Color.alphaBlend(
            Colors.black.withValues(alpha: 0.28), divisionColor);
        final Color coeffDark =
            Color.alphaBlend(Colors.black.withValues(alpha: 0.28), coeffColor);

        final List<Widget> children = [
          // Group headers
          Row(
            children: [
              SizedBox(width: stepW, child: Container(color: divDark)),
              groupCell('DIVISION', 4, divDark),
              groupCell('COEFFICIENTS', 3, coeffDark),
            ],
          ),
          // Column headers
          Row(
            children: [
              Container(
                width: stepW,
                padding: const EdgeInsets.symmetric(vertical: 9),
                color: divisionColor.withValues(alpha: 0.9),
                alignment: Alignment.center,
                child: const Text(
                  '#',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              headerCell('Q', divisionColor.withValues(alpha: 0.9)),
              headerCell('A', divisionColor.withValues(alpha: 0.9)),
              headerCell('B', divisionColor.withValues(alpha: 0.9)),
              headerCell('R', divisionColor.withValues(alpha: 0.9)),
              headerCell('𝑥', coeffColor.withValues(alpha: 0.9)),
              headerCell('𝑦', coeffColor.withValues(alpha: 0.9)),
              headerCell('𝑧', coeffColor.withValues(alpha: 0.9)),
            ],
          ),
        ];

        for (int i = 0; i < tableRows.length; i++) {
          children.add(_buildRow(context, i, lastIndex, cellW, stepW));
          if (_expandedRows.contains(i)) {
            children.add(_buildExpandedFormula(context, i, lastIndex, totalW));
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderMedium(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalW,
                child: Column(children: children),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    int i,
    int lastIndex,
    double cellW,
    double stepW,
  ) {
    final row = tableRows[i];
    final bool isLast = i == lastIndex;
    final bool isExpanded = _expandedRows.contains(i);

    Color? base;
    if (isLast && _hasInverse) {
      base = AppTheme.successBg(context);
    } else if (isLast) {
      base = AppTheme.errorBg(context);
    } else if (i.isOdd) {
      base = AppTheme.surfaceSubtle(context);
    }

    Widget cell(
      String text, {
      int? chain,
      bool bold = false,
      String? tag,
      Color? tagColor,
    }) {
      final Color? tint =
          chain != null ? _chainColor(context, chain) : null;
      return Container(
        width: cellW,
        height: tag != null ? 48 : 40,
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(minWidth: cellW - 14),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: tint?.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 13.5,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: tint ?? AppTheme.textPrimary(context),
                ),
              ),
              if (tag != null)
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tagColor ?? AppTheme.textMuted(context),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final Color tagCol = _hasInverse
        ? AppTheme.successText(context)
        : AppTheme.errorText(context);

    return InkWell(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedRows.remove(i);
        } else {
          _expandedRows.add(i);
        }
      }),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          border: Border(
            top: BorderSide(
              color: isLast
                  ? (_hasInverse
                      ? AppTheme.successBorder(context)
                      : AppTheme.errorBorder(context))
                  : AppTheme.borderSubtle(context),
              width: isLast ? 1.6 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: stepW,
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted(context),
                ),
              ),
            ),
            cell(row['q'].toString()),
            // A_i carries chain i-2, B_i carries chain i-1, R_i starts chain i
            cell(
              row['a'].toString(),
              chain: i - 2,
              bold: isLast,
              tag: isLast ? 'gcd' : null,
              tagColor: tagCol,
            ),
            cell(row['b'].toString(), chain: isLast ? null : i - 1),
            cell(row['r'].toString(), chain: isLast ? null : i),
            // x_i carries chain i-2, y_i carries chain i-1, z_i starts chain i
            cell(
              row['x'].toString(),
              chain: i - 2,
              bold: isLast,
              tag: isLast ? 'x' : null,
              tagColor: tagCol,
            ),
            cell(row['y'].toString(), chain: isLast ? null : i - 1),
            cell(row['z'].toString(), chain: isLast ? null : i),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFormula(
    BuildContext context,
    int i,
    int lastIndex,
    double totalW,
  ) {
    final row = tableRows[i];
    final bool isLast = i == lastIndex;
    final TextStyle style = TextStyle(
      fontFamily: 'Courier New',
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary(context),
    );

    List<String> lines;
    if (isLast) {
      lines = [
        'B reached 0, so the algorithm stops.',
        'gcd(e, φ(n)) = A = ${row['a']}',
        'raw inverse x = ${row['x']}',
      ];
    } else {
      lines = [
        'A = Q × B + R   →   ${row['a']} = ${row['q']} × ${row['b']} + ${row['r']}',
        'z = x − Q × y   →   ${row['z']} = ${row['x']} − ${row['q']} × ${row['y']}',
        'Next row: A←B, B←R, x←y, y←z',
      ];
    }

    return Container(
      width: totalW,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: _accent(context).withValues(alpha: 0.08),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(l, style: style),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final palette = _chainPalette(context);
    return Row(
      children: [
        for (final c in palette)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Same colour = same number moving diagonally (R→B→A and z→y→x).',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context) {
    if (!_hasResult) return const SizedBox.shrink();

    final bool isSuccess = _hasInverse;
    final Color fg = isSuccess
        ? AppTheme.successText(context)
        : AppTheme.errorText(context);

    final TextStyle detail = TextStyle(
      fontFamily: 'Courier New',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: fg,
    );

    final List<Widget> content = [];
    if (isSuccess) {
      final BigInt x = _rawX!;
      final BigInt phi = _phiVal!;
      final BigInt e = _eVal!;
      final BigInt d = _inverse!;
      final BigInt check = (e * d) % phi;

      content.addAll([
        Text(
          'Multiplicative Inverse (d) = $d',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg),
        ),
        const SizedBox(height: 12),
        Divider(color: fg.withValues(alpha: 0.3), height: 1),
        const SizedBox(height: 12),
        Text(
          x < BigInt.zero
              ? 'x = $x is negative, so  d = x + φ(n) = $x + $phi = $d'
              : 'x = $x is not negative, so  d = x = $d',
          textAlign: TextAlign.center,
          style: detail,
        ),
        const SizedBox(height: 8),
        Text(
          check == BigInt.one
              ? 'Check: (e × d) mod φ(n) = ($e × $d) mod $phi = 1 ✓'
              : 'Check: (e × d) mod φ(n) = ($e × $d) mod $phi = $check',
          textAlign: TextAlign.center,
          style: detail,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _copyInverse,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy d'),
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: fg.withValues(alpha: 0.6)),
          ),
        ),
      ]);
    } else {
      content.addAll([
        Text(
          'No inverse exists (GCD != 1)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg),
        ),
        const SizedBox(height: 10),
        Text(
          'gcd(e, φ(n)) = $_gcd ≠ 1, so e and φ(n) share a factor and e⁻¹ mod φ(n) does not exist.',
          textAlign: TextAlign.center,
          style: detail,
        ),
      ]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppTheme.successBg(context)
            : AppTheme.errorBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? AppTheme.successBorder(context)
              : AppTheme.errorBorder(context),
          width: 2,
        ),
      ),
      child: Column(children: content),
    );
  }
}
