import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'app_theme.dart';

class ElGamalScreen extends StatefulWidget {
  const ElGamalScreen({super.key});

  @override
  State<ElGamalScreen> createState() => _ElGamalScreenState();
}

class _ElGamalScreenState extends State<ElGamalScreen> {
  Color get primaryColor => AppTheme.navyAccent(context);
  Color get accentColor => AppTheme.orangeAccent(context);

  // Step 1: Key Generation Controllers
  final TextEditingController qController = TextEditingController();
  final TextEditingController alphaController = TextEditingController();
  final TextEditingController xaController = TextEditingController();
  final TextEditingController yaController = TextEditingController();

  // Step 2: Encryption Controllers
  final TextEditingController messageController = TextEditingController();
  final TextEditingController kRandomController = TextEditingController();
  final TextEditingController c1Controller = TextEditingController();
  final TextEditingController c2Controller = TextEditingController();
  final TextEditingController kEncryptController = TextEditingController();

  // Step 3: Decryption Controllers
  final TextEditingController kDecryptController = TextEditingController();
  final TextEditingController kInverseController = TextEditingController();
  final TextEditingController decryptedController = TextEditingController();

  bool isKeyReady = false;
  bool isEncrypted = false;
  bool isDecrypted = false;

  String? _keyValidationMessage;
  BigInt? _suggestedAlpha;
  String? _encryptErrorMessage;
  String? _decryptErrorMessage;

  @override
  void dispose() {
    qController.dispose();
    alphaController.dispose();
    xaController.dispose();
    yaController.dispose();
    messageController.dispose();
    kRandomController.dispose();
    c1Controller.dispose();
    c2Controller.dispose();
    kEncryptController.dispose();
    kDecryptController.dispose();
    kInverseController.dispose();
    decryptedController.dispose();
    super.dispose();
  }

  // Fast primality check
  bool _isPrime(BigInt n) {
    if (n <= BigInt.one) return false;
    if (n == BigInt.two || n == BigInt.from(3)) return true;
    if (n.isEven || n % BigInt.from(3) == BigInt.zero) return false;
    BigInt i = BigInt.from(5);
    while (i * i <= n) {
      if (n % i == BigInt.zero || n % (i + BigInt.two) == BigInt.zero) {
        return false;
      }
      i += BigInt.from(6);
    }
    return true;
  }

  // Fast prime factorization of (q - 1) for instant primitive root verification
  List<BigInt> _primeFactors(BigInt n) {
    final List<BigInt> factors = [];
    BigInt temp = n;
    BigInt d = BigInt.two;
    while (d * d <= temp) {
      if (temp % d == BigInt.zero) {
        factors.add(d);
        while (temp % d == BigInt.zero) {
          temp ~/= d;
        }
      }
      d += (d == BigInt.two) ? BigInt.one : BigInt.two;
    }
    if (temp > BigInt.one) {
      factors.add(temp);
    }
    return factors;
  }

  bool _isPrimitiveRoot(BigInt alpha, BigInt q) {
    if (q <= BigInt.two) return false;
    if (alpha < BigInt.two || alpha >= q) return false;
    if (!_isPrime(q)) return false;

    final BigInt phi = q - BigInt.one;
    final List<BigInt> factors = _primeFactors(phi);
    for (final BigInt p in factors) {
      if (alpha.modPow(phi ~/ p, q) == BigInt.one) {
        return false;
      }
    }
    return true;
  }

  BigInt? _findSmallestPrimitiveRoot(BigInt q) {
    if (!_isPrime(q) || q <= BigInt.two) return null;
    final BigInt phi = q - BigInt.one;
    final List<BigInt> factors = _primeFactors(phi);
    for (BigInt a = BigInt.two; a < q; a += BigInt.one) {
      bool ok = true;
      for (final BigInt p in factors) {
        if (a.modPow(phi ~/ p, q) == BigInt.one) {
          ok = false;
          break;
        }
      }
      if (ok) return a;
    }
    return null;
  }

  void _generateGlobalParams() {
    final List<Map<String, int>> commonPairs = [
      {'q': 467, 'a': 2},
      {'q': 257, 'a': 3},
      {'q': 107, 'a': 2},
      {'q': 89, 'a': 3},
      {'q': 43, 'a': 3},
      {'q': 23, 'a': 5},
    ];
    final pair = commonPairs[Random().nextInt(commonPairs.length)];
    final int qVal = pair['q']!;
    setState(() {
      qController.text = qVal.toString();
      alphaController.text = pair['a'].toString();
      xaController.text = (Random().nextInt(qVal - 3) + 2).toString();
      _calculatePublicKey();
    });
  }

  void _resetDownstreamResults() {
    kEncryptController.clear();
    c1Controller.clear();
    c2Controller.clear();
    kDecryptController.clear();
    kInverseController.clear();
    decryptedController.clear();
    isEncrypted = false;
    isDecrypted = false;
    _encryptErrorMessage = null;
    _decryptErrorMessage = null;
  }

  void _calculatePublicKey() {
    _resetDownstreamResults();
    _suggestedAlpha = null;

    if (qController.text.trim().isEmpty ||
        alphaController.text.trim().isEmpty ||
        xaController.text.trim().isEmpty) {
      setState(() {
        isKeyReady = false;
        yaController.clear();
        _keyValidationMessage = null;
      });
      return;
    }

    try {
      final BigInt q = BigInt.parse(qController.text.trim());
      final BigInt alpha = BigInt.parse(alphaController.text.trim());
      final BigInt xa = BigInt.parse(xaController.text.trim());

      if (q <= BigInt.from(3) || !_isPrime(q)) {
        setState(() {
          isKeyReady = false;
          yaController.clear();
          _keyValidationMessage = 'Prime (q) must be a prime number > 3.';
        });
        return;
      }

      if (!_isPrimitiveRoot(alpha, q)) {
        final BigInt? suggestion = _findSmallestPrimitiveRoot(q);
        setState(() {
          isKeyReady = false;
          yaController.clear();
          _suggestedAlpha = suggestion;
          _keyValidationMessage =
              'α = $alpha is not a primitive root of q = $q.';
        });
        return;
      }

      if (xa <= BigInt.one || xa >= q - BigInt.one) {
        setState(() {
          isKeyReady = false;
          yaController.clear();
          _keyValidationMessage =
              'Private key X_A must be between 2 and ${q - BigInt.two}.';
        });
        return;
      }

      final BigInt ya = alpha.modPow(xa, q);
      setState(() {
        yaController.text = ya.toString();
        isKeyReady = true;
        _keyValidationMessage = null;
      });
    } catch (e) {
      setState(() {
        isKeyReady = false;
        yaController.clear();
        _keyValidationMessage = 'Please enter valid integer numbers.';
      });
    }
  }

  void _generateRandomK() {
    if (qController.text.trim().isEmpty) return;
    try {
      final BigInt q = BigInt.parse(qController.text.trim());
      if (q <= BigInt.from(3)) return;
      final int maxRange =
          (q - BigInt.two) > BigInt.from(100000) ? 100000 : (q.toInt() - 2);
      final BigInt k = BigInt.from(Random().nextInt(maxRange - 1) + 2);
      setState(() {
        kRandomController.text = k.toString();
        _encryptErrorMessage = null;
      });
    } catch (e) {
      // Ignore invalid number format
    }
  }

  void _encryptMessage() {
    FocusScope.of(context).unfocus();
    setState(() => _encryptErrorMessage = null);

    if (messageController.text.trim().isEmpty ||
        kRandomController.text.trim().isEmpty) {
      setState(() {
        _encryptErrorMessage = 'Please enter both Message (M) and Random (k).';
      });
      return;
    }

    try {
      final BigInt m = BigInt.parse(messageController.text.trim());
      final BigInt q = BigInt.parse(qController.text.trim());
      final BigInt alpha = BigInt.parse(alphaController.text.trim());
      final BigInt ya = BigInt.parse(yaController.text.trim());
      final BigInt k = BigInt.parse(kRandomController.text.trim());

      if (m < BigInt.zero || m >= q) {
        setState(() {
          _encryptErrorMessage =
              'Message (M) must be between 0 and ${q - BigInt.one} (M < q).';
        });
        return;
      }

      if (k < BigInt.one || k >= q) {
        setState(() {
          _encryptErrorMessage =
              'Random (k) must be between 1 and ${q - BigInt.one}.';
        });
        return;
      }

      final BigInt c1 = alpha.modPow(k, q);
      final BigInt bigK = ya.modPow(k, q);
      final BigInt c2 = (bigK * m) % q;

      setState(() {
        kEncryptController.text = bigK.toString();
        c1Controller.text = c1.toString();
        c2Controller.text = c2.toString();
        isEncrypted = true;
        // Reset previous decryption until user clicks Decrypt or auto-update
        isDecrypted = false;
        kDecryptController.clear();
        kInverseController.clear();
        decryptedController.clear();
      });
    } catch (e) {
      setState(() {
        _encryptErrorMessage = 'Encryption error: check your numerical inputs.';
      });
    }
  }

  void _decryptMessage() {
    FocusScope.of(context).unfocus();
    setState(() => _decryptErrorMessage = null);

    if (c1Controller.text.trim().isEmpty || c2Controller.text.trim().isEmpty) {
      setState(() {
        _decryptErrorMessage =
            'Enter Ciphertext C1 and C2 (or encrypt a message above).';
      });
      return;
    }

    try {
      final BigInt c1 = BigInt.parse(c1Controller.text.trim());
      final BigInt c2 = BigInt.parse(c2Controller.text.trim());
      final BigInt q = BigInt.parse(qController.text.trim());
      final BigInt xa = BigInt.parse(xaController.text.trim());

      if (c1 <= BigInt.zero || c1 >= q || c2 < BigInt.zero || c2 >= q) {
        setState(() {
          _decryptErrorMessage = 'C1 and C2 must be less than prime q ($q).';
        });
        return;
      }

      final BigInt bigK = c1.modPow(xa, q);
      final BigInt kInv = bigK.modInverse(q);
      final BigInt m = (c2 * kInv) % q;

      setState(() {
        kDecryptController.text = bigK.toString();
        kInverseController.text = kInv.toString();
        decryptedController.text = m.toString();
        isDecrypted = true;
      });
    } catch (e) {
      setState(() {
        _decryptErrorMessage = 'Decryption error: C1 must be coprime to q.';
      });
    }
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      qController.clear();
      alphaController.clear();
      xaController.clear();
      yaController.clear();
      messageController.clear();
      kRandomController.clear();
      _resetDownstreamResults();
      isKeyReady = false;
      _keyValidationMessage = null;
      _suggestedAlpha = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgAlt(context),
      appBar: AppBar(
        title: const Text(
          'El-Gamal Cipher',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.navyAppBar(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearAll,
            tooltip: 'Reset All',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // STEP 1: KEY GENERATION (ALICE)
              _buildKeyGenerationCard(),
              const SizedBox(height: 16),

              if (isKeyReady) ...[
                // STEP 2: ENCRYPTION (BOB)
                _buildEncryptionCard(),
                const SizedBox(height: 16),

                // STEP 3: DECRYPTION (ALICE) - Always accessible once keys are ready!
                _buildDecryptionCard(),
              ] else
                _buildWarningCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyGenerationCard() {
    return _buildStepCard(
      title: "1. Key Generation (Alice)",
      subtitle: "Public Key: {q, α, Y_A}  •  Private Key: X_A",
      icon: Icons.vpn_key_rounded,
      trailing: TextButton.icon(
        onPressed: _generateGlobalParams,
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: const Text("Auto Fill", style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.tealAccent(context),
          backgroundColor: AppTheme.tealAccent(context).withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  qController,
                  "Prime (q)",
                  onChanged: (_) => _calculatePublicKey(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  alphaController,
                  "Root (α)",
                  onChanged: (_) => _calculatePublicKey(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  xaController,
                  "Private (X_A)",
                  color: accentColor,
                  onChanged: (_) => _calculatePublicKey(),
                ),
              ),
            ],
          ),

          // Inline Validation Banner (Replaces disruptive popup SnackBars while typing)
          if (_keyValidationMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningBg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningText(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _keyValidationMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningText(context),
                      ),
                    ),
                  ),
                  if (_suggestedAlpha != null)
                    TextButton(
                      onPressed: () {
                        alphaController.text = _suggestedAlpha.toString();
                        _calculatePublicKey();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Use α = $_suggestedAlpha",
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Computed Public Key Y_A Live Breakdown
          if (isKeyReady) ...[
            const SizedBox(height: 14),
            _buildCompactCalcRow(
              label: "Public Key (Y_A)",
              symbolicFormula: "Y_A = α^(X_A) mod q",
              substitutedFormula:
                  "${alphaController.text}^${xaController.text} mod ${qController.text}",
              resultValue: yaController.text,
              highlightColor: primaryColor,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Public Key PU = {${qController.text}, ${alphaController.text}, ${yaController.text}}",
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    "PR = {${xaController.text}}",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEncryptionCard() {
    return _buildStepCard(
      title: "2. Encryption (Bob)",
      subtitle: "Encrypts Message M < ${qController.text} with random k",
      icon: Icons.lock_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  messageController,
                  "Message (M)",
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  kRandomController,
                  "Random (k)",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.casino_outlined,
                        color: primaryColor, size: 20),
                    tooltip: 'Random k',
                    onPressed: _generateRandomK,
                  ),
                ),
              ),
            ],
          ),
          if (_encryptErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _encryptErrorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _encryptMessage,
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: const Text(
              "ENCRYPT MESSAGE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (isEncrypted) ...[
            const Divider(height: 24),
            _buildCompactCalcRow(
              label: "1. One-Time Shared Key (K)",
              symbolicFormula: "K = (Y_A)^k mod q",
              substitutedFormula:
                  "${yaController.text}^${kRandomController.text} mod ${qController.text}",
              resultValue: kEncryptController.text,
            ),
            const SizedBox(height: 8),
            _buildCompactCalcRow(
              label: "2. First Ciphertext (C1)",
              symbolicFormula: "C1 = α^k mod q",
              substitutedFormula:
                  "${alphaController.text}^${kRandomController.text} mod ${qController.text}",
              resultValue: c1Controller.text,
            ),
            const SizedBox(height: 8),
            _buildCompactCalcRow(
              label: "3. Second Ciphertext (C2)",
              symbolicFormula: "C2 = (K × M) mod q",
              substitutedFormula:
                  "(${kEncryptController.text} × ${messageController.text}) mod ${qController.text}",
              resultValue: c2Controller.text,
            ),
            const SizedBox(height: 12),
            _buildCiphertextTuple(),
          ],
        ],
      ),
    );
  }

  Widget _buildDecryptionCard() {
    return _buildStepCard(
      title: "3. Decryption (Alice)",
      subtitle: "Recovers M from (C1, C2) using Private Key X_A",
      icon: Icons.lock_open_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editable C1 and C2 so students can also solve Decryption-only problems!
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  c1Controller,
                  "Cipher 1 (C1)",
                  onChanged: (_) => setState(() => isDecrypted = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  c2Controller,
                  "Cipher 2 (C2)",
                  onChanged: (_) => setState(() => isDecrypted = false),
                ),
              ),
            ],
          ),
          if (_decryptErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _decryptErrorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _decryptMessage,
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text(
              "DECRYPT CIPHERTEXT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (isDecrypted) ...[
            const Divider(height: 24),
            _buildCompactCalcRow(
              label: "1. Recover Shared Key (K)",
              symbolicFormula: "K = (C1)^(X_A) mod q",
              substitutedFormula:
                  "${c1Controller.text}^${xaController.text} mod ${qController.text}",
              resultValue: kDecryptController.text,
            ),
            const SizedBox(height: 8),
            _buildCompactCalcRow(
              label: "2. Modular Inverse (K⁻¹)",
              symbolicFormula: "K⁻¹ mod q",
              substitutedFormula:
                  "${kDecryptController.text}⁻¹ mod ${qController.text}",
              resultValue: kInverseController.text,
            ),
            const SizedBox(height: 8),
            _buildCompactCalcRow(
              label: "3. Recover Plaintext (M)",
              symbolicFormula: "M = (C2 × K⁻¹) mod q",
              substitutedFormula:
                  "(${c2Controller.text} × ${kInverseController.text}) mod ${qController.text}",
              resultValue: decryptedController.text,
              highlightColor: AppTheme.isDark(context)
                  ? const Color(0xFF4ADE80)
                  : Colors.green.shade700,
            ),
            const SizedBox(height: 12),
            _buildSuccessDecryptionBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label, {
    bool readOnly = false,
    IconData? icon,
    Widget? suffixIcon,
    Color? color,
    Function(String)? onChanged,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
        style: TextStyle(
          color: color ?? AppTheme.textPrimary(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Courier New',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 12),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: color ?? primaryColor)
              : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color ?? primaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.surfaceSubtle(context),
        ),
      ),
    );
  }

  // Compact 1-card live formula & value row (replaces bulky read-only TextField + Badge pairs)
  Widget _buildCompactCalcRow({
    required String label,
    required String symbolicFormula,
    required String substitutedFormula,
    required String resultValue,
    Color? highlightColor,
  }) {
    final Color activeColor = highlightColor ?? primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        symbolicFormula,
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "= $substitutedFormula",
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: activeColor.withValues(alpha: 0.4)),
            ),
            child: SelectableText(
              resultValue,
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCiphertextTuple() {
    final String tupleStr = "(${c1Controller.text}, ${c2Controller.text})";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Final Ciphertext Tuple (C1, C2)",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                tupleStr,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Courier New',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _copyText(tupleStr, 'Ciphertext $tupleStr'),
            icon: Icon(Icons.copy_rounded, color: primaryColor, size: 20),
            tooltip: 'Copy (C1, C2)',
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningBorder(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningText(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Complete Step 1 (or tap 'Auto Fill') to unlock Encryption and Decryption.",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDecryptionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.successBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successBorder(context), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: AppTheme.successText(context), size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recovered Original Message (M)",
                    style: TextStyle(
                      color: AppTheme.successText(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  SelectableText(
                    decryptedController.text,
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successText(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                _copyText(decryptedController.text, 'Recovered Message M'),
            icon: Icon(Icons.copy_rounded,
                color: AppTheme.successText(context), size: 20),
            tooltip: 'Copy M',
          ),
        ],
      ),
    );
  }
}
