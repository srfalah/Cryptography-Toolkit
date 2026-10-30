import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'app_theme.dart';

class DiffieHellmanScreen extends StatefulWidget {
  const DiffieHellmanScreen({super.key});

  @override
  State<DiffieHellmanScreen> createState() => _DiffieHellmanScreenState();
}

class _DiffieHellmanScreenState extends State<DiffieHellmanScreen> {
  Color get primaryColor => AppTheme.navyAccent(context);
  Color get aliceColor => AppTheme.aliceColor(context);
  Color get bobColor => AppTheme.bobColor(context);
  Color get successColor => AppTheme.successText(context);

  final TextEditingController qController = TextEditingController();
  final TextEditingController alphaController = TextEditingController();
  final TextEditingController privateAController = TextEditingController();
  final TextEditingController privateBController = TextEditingController();

  BigInt? _qVal, _alphaVal, _xAVal, _xBVal;
  BigInt? publicA, publicB, sharedA, sharedB;

  String? errorMessage;
  BigInt? _suggestedAlpha;

  @override
  void dispose() {
    qController.dispose();
    alphaController.dispose();
    privateAController.dispose();
    privateBController.dispose();
    super.dispose();
  }

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

  void _calculate() {
    setState(() {
      errorMessage = null;
      _suggestedAlpha = null;
      _resetResults();

      if (qController.text.trim().isEmpty ||
          alphaController.text.trim().isEmpty) {
        return;
      }

      try {
        final BigInt q = BigInt.parse(qController.text.trim());
        final BigInt alpha = BigInt.parse(alphaController.text.trim());

        if (q <= BigInt.from(3) || !_isPrime(q)) {
          errorMessage = 'Prime (q) must be a prime number > 3.';
          return;
        }

        if (!_isPrimitiveRoot(alpha, q)) {
          _suggestedAlpha = _findSmallestPrimitiveRoot(q);
          errorMessage = 'α = $alpha is not a primitive root of q = $q.';
          return;
        }

        _qVal = q;
        _alphaVal = alpha;

        // Calculate Alice's Public Key independently as soon as X_A is entered
        if (privateAController.text.trim().isNotEmpty) {
          final BigInt xA = BigInt.parse(privateAController.text.trim());
          if (xA <= BigInt.zero || xA >= q) {
            errorMessage =
                'Alice\'s Private Key (X_A) must be between 1 and ${q - BigInt.one}.';
            return;
          }
          _xAVal = xA;
          publicA = alpha.modPow(xA, q);
        }

        // Calculate Bob's Public Key independently as soon as X_B is entered
        if (privateBController.text.trim().isNotEmpty) {
          final BigInt xB = BigInt.parse(privateBController.text.trim());
          if (xB <= BigInt.zero || xB >= q) {
            errorMessage =
                'Bob\'s Private Key (X_B) must be between 1 and ${q - BigInt.one}.';
            return;
          }
          _xBVal = xB;
          publicB = alpha.modPow(xB, q);
        }

        // Once both Public Keys exist, exchange them to compute Shared Secrets!
        if (publicA != null && publicB != null && _xAVal != null && _xBVal != null) {
          sharedA = publicB!.modPow(_xAVal!, q);
          sharedB = publicA!.modPow(_xBVal!, q);
        }
      } catch (e) {
        _resetResults();
      }
    });
  }

  void _resetResults() {
    _qVal = null;
    _alphaVal = null;
    _xAVal = null;
    _xBVal = null;
    publicA = null;
    publicB = null;
    sharedA = null;
    sharedB = null;
  }

  void _generateGlobalParams() {
    final List<Map<String, int>> commonPairs = [
      {'q': 23, 'a': 5},
      {'q': 47, 'a': 5},
      {'q': 71, 'a': 7},
      {'q': 97, 'a': 5},
      {'q': 353, 'a': 3},
    ];
    final pair = commonPairs[Random().nextInt(commonPairs.length)];
    final int qInt = pair['q']!;
    setState(() {
      qController.text = qInt.toString();
      alphaController.text = pair['a'].toString();
      if (privateAController.text.trim().isEmpty ||
          (int.tryParse(privateAController.text) ?? 0) >= qInt) {
        privateAController.text = (Random().nextInt(qInt - 3) + 2).toString();
      }
      if (privateBController.text.trim().isEmpty ||
          (int.tryParse(privateBController.text) ?? 0) >= qInt) {
        privateBController.text = (Random().nextInt(qInt - 3) + 2).toString();
      }
      _calculate();
    });
  }

  void _generateKey(TextEditingController ctrl) {
    int maxKey = 90;
    if (qController.text.trim().isNotEmpty) {
      final int? parsedQ = int.tryParse(qController.text.trim());
      if (parsedQ != null && parsedQ > 4) {
        maxKey = min(parsedQ - 3, 200);
      }
    }
    setState(() {
      ctrl.text = (Random().nextInt(maxKey) + 2).toString();
      _calculate();
    });
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      qController.clear();
      alphaController.clear();
      privateAController.clear();
      privateBController.clear();
      _resetResults();
      errorMessage = null;
      _suggestedAlpha = null;
    });
  }

  void _copySecret() {
    if (sharedA == null) return;
    Clipboard.setData(ClipboardData(text: sharedA.toString()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared Secret K = $sharedA copied to clipboard!'),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgAlt(context),
      appBar: AppBar(
        title: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Icon(Icons.swap_horizontal_circle_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'D-H Key Exchange',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
              textAlign: TextAlign.center,
            ),
          ],
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. GLOBAL PARAMETERS CARD (q & α)
              _buildGlobalCard(),
              const SizedBox(height: 14),

              // 2. STAGE 1: ALICE & BOB PRIVATE KEYS + LOCAL PUBLIC KEYS
              _buildStage1LocalKeysRow(),

              // 3. STAGE 2: VISUAL PUBLIC CHANNEL CROSSOVER DIAGRAM
              _buildStage2CrossoverBridge(),

              // 4. STAGE 3: COLOR-CODED SHARED SECRET CALCULATION
              _buildStage3SharedSecretsRow(),

              // 5. VERIFIED MATCH BANNER
              if (sharedA != null && sharedA == sharedB) ...[
                const SizedBox(height: 14),
                _buildSuccessBanner(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalCard() {
    final bool isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppTheme.borderSubtle(context)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.public_rounded,
                        color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "1. Public Global Parameters",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _generateGlobalParams,
                icon: const Icon(Icons.auto_awesome, size: 15),
                label:
                    const Text("Auto Demo", style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.tealAccent(context),
                  backgroundColor: AppTheme.tealAccent(context)
                      .withValues(alpha: isDark ? 0.14 : 0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactField(
                  controller: qController,
                  label: "Prime (q)",
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactField(
                  controller: alphaController,
                  label: "Primitive Root (α)",
                  color: primaryColor,
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningBg(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningText(context), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: AppTheme.warningText(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_suggestedAlpha != null)
                    TextButton(
                      onPressed: () {
                        alphaController.text = _suggestedAlpha.toString();
                        _calculate();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }

  Widget _buildStage1LocalKeysRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildParticipantStage1Card(
            name: "Alice",
            keySuffix: "A",
            color: aliceColor,
            privateCtrl: privateAController,
            privateVal: _xAVal,
            publicVal: publicA,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildParticipantStage1Card(
            name: "Bob",
            keySuffix: "B",
            color: bobColor,
            privateCtrl: privateBController,
            privateVal: _xBVal,
            publicVal: publicB,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantStage1Card({
    required String name,
    required String keySuffix,
    required Color color,
    required TextEditingController privateCtrl,
    required BigInt? privateVal,
    required BigInt? publicVal,
  }) {
    final String substituted = (_alphaVal != null &&
            privateVal != null &&
            _qVal != null)
        ? "$_alphaVal^$privateVal mod $_qVal"
        : "α^X$keySuffix mod q";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Participant Header + Random Key Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color,
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _generateKey(privateCtrl),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino_outlined, size: 12, color: color),
                      const SizedBox(width: 3),
                      Text(
                        "Rand",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Private Key Input (Secret)
          _buildCompactField(
            controller: privateCtrl,
            label: "Private X_$keySuffix (Secret)",
            color: color,
          ),
          const SizedBox(height: 10),

          // Computed Local Public Key Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: publicVal != null
                    ? color.withValues(alpha: 0.45)
                    : AppTheme.borderSubtle(context),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Public Key Y_$keySuffix",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  substituted,
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: publicVal != null
                        ? color
                        : AppTheme.pillBg(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    publicVal != null ? "Y_$keySuffix = $publicVal" : "Y_$keySuffix = ?",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: publicVal != null
                          ? Colors.white
                          : AppTheme.textMuted(context),
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

  // Visual Public Channel Crossover Bridge (X-crossing arrows with Y_A and Y_B badges)
  Widget _buildStage2CrossoverBridge() {
    final bool hasBothPublic = publicA != null && publicB != null;

    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom Painted Crossing Diagonal Arrows
          Positioned.fill(
            child: CustomPaint(
              painter: _CrossoverArrowsPainter(
                aliceColor: aliceColor,
                bobColor: bobColor,
                inactiveColor: AppTheme.borderMedium(context),
                isActive: hasBothPublic,
              ),
            ),
          ),

          // Left-to-Right Travelling Badge: Alice's Pink Y_A going to Bob
          Positioned(
            left: 22,
            top: 12,
            child: _buildTravellingKeyBadge(
              label: publicA != null ? "Y_A = $publicA ↘" : "Y_A ↘",
              color: aliceColor,
              isActive: publicA != null,
            ),
          ),

          // Right-to-Left Travelling Badge: Bob's Blue Y_B going to Alice
          Positioned(
            right: 22,
            top: 12,
            child: _buildTravellingKeyBadge(
              label: publicB != null ? "↙ Y_B = $publicB" : "↙ Y_B",
              color: bobColor,
              isActive: publicB != null,
            ),
          ),

          // Center Exchange Hub Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasBothPublic
                    ? primaryColor
                    : AppTheme.borderMedium(context),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: hasBothPublic
                      ? primaryColor
                      : AppTheme.textMuted(context),
                ),
                const SizedBox(width: 5),
                Text(
                  "PUBLIC CHANNEL EXCHANGE",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: hasBothPublic
                        ? primaryColor
                        : AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),

          // Bottom arrival labels showing what each side receives
          Positioned(
            left: 16,
            bottom: 8,
            child: _buildReceivedLabel(
              text: publicB != null
                  ? "Alice receives Y_B = $publicB"
                  : "Alice receives Y_B",
              color: bobColor,
              isActive: publicB != null,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 8,
            child: _buildReceivedLabel(
              text: publicA != null
                  ? "Bob receives Y_A = $publicA"
                  : "Bob receives Y_A",
              color: aliceColor,
              isActive: publicA != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravellingKeyBadge({
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? color : AppTheme.pillBg(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : AppTheme.textMuted(context),
        ),
      ),
    );
  }

  Widget _buildReceivedLabel({
    required String text,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.14)
            : AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.45)
              : AppTheme.borderMedium(context),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: isActive ? color : AppTheme.textMuted(context),
        ),
      ),
    );
  }

  // Stage 3: Color-coded Shared Secret cards showing how Received Public Key + Own Private Key = K
  Widget _buildStage3SharedSecretsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSharedSecretCard(
            ownerName: "Alice",
            ownerColor: aliceColor,
            partnerColor: bobColor,
            receivedKeySymbol: "Y_B",
            receivedKeyVal: publicB,
            ownPrivateSymbol: "X_A",
            ownPrivateVal: _xAVal,
            sharedSecretVal: sharedA,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSharedSecretCard(
            ownerName: "Bob",
            ownerColor: bobColor,
            partnerColor: aliceColor,
            receivedKeySymbol: "Y_A",
            receivedKeyVal: publicA,
            ownPrivateSymbol: "X_B",
            ownPrivateVal: _xBVal,
            sharedSecretVal: sharedB,
          ),
        ),
      ],
    );
  }

  Widget _buildSharedSecretCard({
    required String ownerName,
    required Color ownerColor,
    required Color partnerColor,
    required String receivedKeySymbol,
    required BigInt? receivedKeyVal,
    required String ownPrivateSymbol,
    required BigInt? ownPrivateVal,
    required BigInt? sharedSecretVal,
  }) {
    final bool isReady = sharedSecretVal != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? AppTheme.successBorder(context)
              : AppTheme.borderMedium(context),
          width: isReady ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "$ownerName Computes Secret K",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),

          // Symbolic formula with color-coded base & exponent
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: "K = (",
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                TextSpan(
                  text: receivedKeySymbol,
                  style: TextStyle(color: partnerColor),
                ),
                TextSpan(
                  text: ")^",
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                TextSpan(
                  text: ownPrivateSymbol,
                  style: TextStyle(color: ownerColor),
                ),
                TextSpan(
                  text: " mod q",
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Color-coded plugged-in numbers: (Partner's Public Key)^(Own Private Key) mod q
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle(context)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: partnerColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      receivedKeyVal?.toString() ?? receivedKeySymbol,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: partnerColor,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(1, -5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: ownerColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ownPrivateVal?.toString() ?? ownPrivateSymbol,
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: ownerColor,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    " mod ${_qVal?.toString() ?? 'q'}",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Final Shared Secret Value
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isReady
                  ? AppTheme.successBg(context)
                  : AppTheme.surfaceSubtle(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isReady ? "K = $sharedSecretVal" : "K = ?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isReady ? successColor : AppTheme.textMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
        onChanged: (_) => _calculate(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            color: color.withValues(alpha: 0.85),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          filled: true,
          fillColor: AppTheme.surfaceSubtle(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.borderMedium(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withValues(alpha: 0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.successBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.successBorder(context), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: successColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Shared Secret Matched!  K = $sharedA",
                        style: TextStyle(
                          color: successColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Both equal α^(X_A × X_B) mod q = $_alphaVal^($_xAVal×$_xBVal) mod $_qVal",
                        style: TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: successColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _copySecret,
            icon: Icon(Icons.copy_rounded, color: successColor, size: 20),
            tooltip: 'Copy Shared Secret K',
          ),
        ],
      ),
    );
  }
}

// CustomPainter that draws the crossing diagonal public key exchange paths
class _CrossoverArrowsPainter extends CustomPainter {
  final Color aliceColor;
  final Color bobColor;
  final Color inactiveColor;
  final bool isActive;

  _CrossoverArrowsPainter({
    required this.aliceColor,
    required this.bobColor,
    required this.inactiveColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftX = size.width * 0.24;
    final double rightX = size.width * 0.76;
    final double topY = 4;
    final double bottomY = size.height - 4;

    final Paint alicePaint = Paint()
      ..color = isActive ? aliceColor : inactiveColor
      ..strokeWidth = isActive ? 2.5 : 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint bobPaint = Paint()
      ..color = isActive ? bobColor : inactiveColor
      ..strokeWidth = isActive ? 2.5 : 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Alice (Top-Left) -> Bob (Bottom-Right) S-Curve
    final Path alicePath = Path()
      ..moveTo(leftX, topY)
      ..cubicTo(
        leftX,
        size.height * 0.55,
        rightX,
        size.height * 0.45,
        rightX,
        bottomY - 22,
      );
    canvas.drawPath(alicePath, alicePaint);
    _drawArrowHead(
      canvas,
      Offset(rightX, bottomY - 22),
      isActive ? aliceColor : inactiveColor,
    );

    // 2. Bob (Top-Right) -> Alice (Bottom-Left) S-Curve
    final Path bobPath = Path()
      ..moveTo(rightX, topY)
      ..cubicTo(
        rightX,
        size.height * 0.55,
        leftX,
        size.height * 0.45,
        leftX,
        bottomY - 22,
      );
    canvas.drawPath(bobPath, bobPaint);
    _drawArrowHead(
      canvas,
      Offset(leftX, bottomY - 22),
      isActive ? bobColor : inactiveColor,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Color color) {
    final Paint headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path triangle = Path()
      ..moveTo(tip.dx, tip.dy + 4)
      ..lineTo(tip.dx - 5, tip.dy - 5)
      ..lineTo(tip.dx + 5, tip.dy - 5)
      ..close();

    canvas.drawPath(triangle, headPaint);
  }

  @override
  bool shouldRepaint(covariant _CrossoverArrowsPainter oldDelegate) {
    return oldDelegate.isActive != isActive ||
        oldDelegate.aliceColor != aliceColor ||
        oldDelegate.bobColor != bobColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
