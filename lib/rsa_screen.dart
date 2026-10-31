import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'app_theme.dart';

class RsaScreen extends StatefulWidget {
  const RsaScreen({super.key});

  @override
  State<RsaScreen> createState() => _RsaScreenState();
}

class _RsaScreenState extends State<RsaScreen> {
  Color get primaryColor => AppTheme.navyAccent(context);
  Color get accentColor => AppTheme.orangeAccent(context);

  // Step 1: Key Generation Controllers
  final TextEditingController pController = TextEditingController();
  final TextEditingController qController = TextEditingController();
  final TextEditingController nController = TextEditingController();
  final TextEditingController phiController = TextEditingController();
  final TextEditingController eController = TextEditingController();
  final TextEditingController dController = TextEditingController();

  // Step 2 & 3: Encryption / Decryption Controllers
  final TextEditingController messageController = TextEditingController();
  final TextEditingController encryptedController = TextEditingController();
  final TextEditingController decryptedController = TextEditingController();

  bool isPrimesValid = false;
  bool isEncryptionReady = false;
  bool isEncrypted = false;
  bool isDecrypted = false;

  String? _primeValidationMessage;
  String? _eValidationMessage;
  String? _encryptErrorMessage;
  String? _decryptErrorMessage;
  List<BigInt> _suggestedEValues = [];

  @override
  void dispose() {
    pController.dispose();
    qController.dispose();
    nController.dispose();
    phiController.dispose();
    eController.dispose();
    dController.dispose();
    messageController.dispose();
    encryptedController.dispose();
    decryptedController.dispose();
    super.dispose();
  }

  bool _isPrime(BigInt number) {
    if (number <= BigInt.one) return false;
    if (number == BigInt.two || number == BigInt.from(3)) return true;
    if (number.isEven || number % BigInt.from(3) == BigInt.zero) {
      return false;
    }
    BigInt i = BigInt.from(5);
    while (i * i <= number) {
      if (number % i == BigInt.zero ||
          number % (i + BigInt.two) == BigInt.zero) {
        return false;
      }
      i += BigInt.from(6);
    }
    return true;
  }

  void _resetDownstreamResults() {
    encryptedController.clear();
    decryptedController.clear();
    isEncrypted = false;
    isDecrypted = false;
    _encryptErrorMessage = null;
    _decryptErrorMessage = null;
  }

  void _generatePrimes() {
    final random = Random.secure();
    BigInt generateRandomPrime() {
      BigInt candidate;
      do {
        candidate = BigInt.from(random.nextInt(150) + 11);
      } while (!_isPrime(candidate));
      return candidate;
    }

    final BigInt p = generateRandomPrime();
    BigInt q;
    do {
      q = generateRandomPrime();
    } while (q == p); // Guarantee distinct primes p != q

    setState(() {
      pController.text = p.toString();
      qController.text = q.toString();
      _onPrimeFieldsChanged(autoPickEIfInvalid: true);
    });
  }

  List<BigInt> _computeSuggestedEValues(BigInt phi) {
    final List<BigInt> suggestions = [];
    BigInt candidate = BigInt.from(3);
    while (candidate < phi && suggestions.length < 5) {
      if (candidate.gcd(phi) == BigInt.one) {
        suggestions.add(candidate);
      }
      candidate += BigInt.two;
    }
    final BigInt fermat = BigInt.from(65537);
    if (fermat < phi &&
        fermat.gcd(phi) == BigInt.one &&
        !suggestions.contains(fermat)) {
      suggestions.add(fermat);
    }
    return suggestions;
  }

  void _onPrimeFieldsChanged({bool autoPickEIfInvalid = false}) {
    _resetDownstreamResults();

    if (pController.text.trim().isEmpty || qController.text.trim().isEmpty) {
      setState(() {
        isPrimesValid = false;
        isEncryptionReady = false;
        nController.clear();
        phiController.clear();
        dController.clear();
        _suggestedEValues = [];
        _primeValidationMessage = null;
        _eValidationMessage = null;
      });
      return;
    }

    try {
      final BigInt p = BigInt.parse(pController.text.trim());
      final BigInt q = BigInt.parse(qController.text.trim());

      final bool pPrime = _isPrime(p);
      final bool qPrime = _isPrime(q);

      if (!pPrime || !qPrime) {
        String msg;
        if (!pPrime && !qPrime) {
          msg = tr(
            'Both p ($p) and q ($q) must be prime numbers.',
            'يجب أن يكون كل من p ($p) و q ($q) عددين أوليين.',
          );
        } else if (!pPrime) {
          msg = tr(
            'p = $p is not a prime number.',
            'العدد p = $p ليس عدداً أولياً.',
          );
        } else {
          msg = tr(
            'q = $q is not a prime number.',
            'العدد q = $q ليس عدداً أولياً.',
          );
        }
        setState(() {
          isPrimesValid = false;
          isEncryptionReady = false;
          nController.clear();
          phiController.clear();
          dController.clear();
          _suggestedEValues = [];
          _primeValidationMessage = msg;
          _eValidationMessage = null;
        });
        return;
      }

      if (p == q) {
        setState(() {
          isPrimesValid = false;
          isEncryptionReady = false;
          nController.clear();
          phiController.clear();
          dController.clear();
          _suggestedEValues = [];
          _primeValidationMessage = tr(
            'Primes p and q must be distinct (p ≠ q) for RSA.',
            'يجب أن يكون العددان الأوليان مختلفين (p ≠ q) في RSA.',
          );
          _eValidationMessage = null;
        });
        return;
      }

      final BigInt n = p * q;
      final BigInt phi = (p - BigInt.one) * (q - BigInt.one);

      nController.text = n.toString();
      phiController.text = phi.toString();
      _suggestedEValues = _computeSuggestedEValues(phi);
      isPrimesValid = true;
      _primeValidationMessage = null;

      if (autoPickEIfInvalid && _suggestedEValues.isNotEmpty) {
        eController.text = _suggestedEValues.first.toString();
      }

      _onEFieldChanged();
    } catch (e) {
      setState(() {
        isPrimesValid = false;
        isEncryptionReady = false;
        nController.clear();
        phiController.clear();
        dController.clear();
        _suggestedEValues = [];
        _primeValidationMessage = tr(
          'Please enter valid integer primes.',
          'يرجى إدخال أعداد أولية صحيحة.',
        );
      });
    }
  }

  void _suggestE() {
    if (!isPrimesValid || phiController.text.isEmpty) {
      setState(() {
        _primeValidationMessage = tr(
          'Please enter valid primes p and q first.',
          'يرجى إدخال العددين الأوليين p و q أولاً.',
        );
      });
      return;
    }
    if (_suggestedEValues.isEmpty) return;

    final String currentE = eController.text.trim();
    int nextIndex = 0;
    for (int i = 0; i < _suggestedEValues.length; i++) {
      if (_suggestedEValues[i].toString() == currentE) {
        nextIndex = (i + 1) % _suggestedEValues.length;
        break;
      }
    }
    setState(() {
      eController.text = _suggestedEValues[nextIndex].toString();
      _onEFieldChanged();
    });
  }

  void _onEFieldChanged() {
    _resetDownstreamResults();

    if (!isPrimesValid || phiController.text.isEmpty) {
      setState(() {
        isEncryptionReady = false;
        dController.clear();
        _eValidationMessage = null;
      });
      return;
    }

    if (eController.text.trim().isEmpty) {
      setState(() {
        isEncryptionReady = false;
        dController.clear();
        _eValidationMessage = null;
      });
      return;
    }

    try {
      final BigInt e = BigInt.parse(eController.text.trim());
      final BigInt phi = BigInt.parse(phiController.text.trim());

      if (e <= BigInt.one || e >= phi) {
        setState(() {
          isEncryptionReady = false;
          dController.clear();
          _eValidationMessage = tr(
            'Public exponent e must satisfy 1 < e < φ(n) ($phi).',
            'يجب أن يحقق الأس العام الشرط: 1 < e < φ(n) ($phi).',
          );
        });
        return;
      }

      final BigInt g = e.gcd(phi);
      if (g != BigInt.one) {
        setState(() {
          isEncryptionReady = false;
          dController.clear();
          _eValidationMessage = tr(
            'gcd($e, $phi) = $g ≠ 1. e must be coprime to φ(n).',
            'gcd($e, $phi) = $g ≠ 1. يجب أن يكون e أولياً نسبياً مع φ(n).',
          );
        });
        return;
      }

      final BigInt d = e.modInverse(phi);
      setState(() {
        dController.text = d.toString();
        isEncryptionReady = true;
        _eValidationMessage = null;
      });
    } catch (err) {
      setState(() {
        isEncryptionReady = false;
        dController.clear();
        _eValidationMessage = tr(
          'Invalid number format for e.',
          'صيغة الرقم e غير صالحة.',
        );
      });
    }
  }

  void _encryptMessage() {
    FocusScope.of(context).unfocus();
    setState(() => _encryptErrorMessage = null);

    if (messageController.text.trim().isEmpty) {
      setState(() {
        _encryptErrorMessage = tr(
          'Please enter a numeric Message (M) to encrypt.',
          'يرجى إدخال الرسالة الرقمية (M) لتشفيرها.',
        );
      });
      return;
    }

    try {
      final BigInt m = BigInt.parse(messageController.text.trim());
      final BigInt n = BigInt.parse(nController.text.trim());
      final BigInt e = BigInt.parse(eController.text.trim());

      if (m < BigInt.zero || m >= n) {
        setState(() {
          _encryptErrorMessage = tr(
            'Message (M) must be between 0 and ${n - BigInt.one} (M < n).',
            'يجب أن تكون الرسالة (M) بين 0 و ${n - BigInt.one} (أصغر من n).',
          );
        });
        return;
      }

      final BigInt c = m.modPow(e, n);
      setState(() {
        encryptedController.text = c.toString();
        isEncrypted = true;
        isDecrypted = false;
        decryptedController.clear();
      });
    } catch (e) {
      setState(() {
        _encryptErrorMessage = tr(
          'Invalid message input.',
          'مدخل الرسالة غير صالح.',
        );
      });
    }
  }

  void _decryptMessage() {
    FocusScope.of(context).unfocus();
    setState(() => _decryptErrorMessage = null);

    if (encryptedController.text.trim().isEmpty) {
      setState(() {
        _decryptErrorMessage = tr(
          'Enter Ciphertext (C) (or encrypt a message in Step 2).',
          'أدخل النص المشفر (C) (أو قم بتشفير رسالة في الخطوة 2).',
        );
      });
      return;
    }

    try {
      final BigInt c = BigInt.parse(encryptedController.text.trim());
      final BigInt n = BigInt.parse(nController.text.trim());
      final BigInt d = BigInt.parse(dController.text.trim());

      if (c < BigInt.zero || c >= n) {
        setState(() {
          _decryptErrorMessage = tr(
            'Ciphertext (C) must be less than Modulus n ($n).',
            'يجب أن يكون النص المشفر (C) أصغر من المعيار n ($n).',
          );
        });
        return;
      }

      final BigInt m = c.modPow(d, n);
      setState(() {
        decryptedController.text = m.toString();
        isDecrypted = true;
      });
    } catch (e) {
      setState(() {
        _decryptErrorMessage = tr(
          'Decryption failed: check ciphertext input.',
          'فشل فك التشفير: تحقق من قيمة النص المشفر.',
        );
      });
    }
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(
          '$label copied to clipboard!',
          'تم نسخ $label إلى الحافظة!',
        )),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      pController.clear();
      qController.clear();
      nController.clear();
      phiController.clear();
      eController.clear();
      dController.clear();
      messageController.clear();
      _resetDownstreamResults();
      isPrimesValid = false;
      isEncryptionReady = false;
      _primeValidationMessage = null;
      _eValidationMessage = null;
      _suggestedEValues = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgAlt(context),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tr('RSA Algorithm', 'خوارزمية RSA'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.navyAppBar(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AppTheme.buildLanguageToggleButton(context),
          IconButton(
            onPressed: _clearAll,
            tooltip: tr('Reset All', 'إعادة تعيين الكل'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // STEP 1: KEY GENERATION
              _buildKeyGenerationCard(),
              const SizedBox(height: 16),

              if (isEncryptionReady) ...[
                // STEP 2: ENCRYPTION
                _buildEncryptionCard(),
                const SizedBox(height: 16),

                // STEP 3: DECRYPTION (Directly usable for decryption-only problems too!)
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
    final String pMinus1 = isPrimesValid
        ? (BigInt.parse(pController.text.trim()) - BigInt.one).toString()
        : 'p−1';
    final String qMinus1 = isPrimesValid
        ? (BigInt.parse(qController.text.trim()) - BigInt.one).toString()
        : 'q−1';

    return _buildStepCard(
      title: tr("1. Key Generation", "1. توليد المفاتيح"),
      subtitle: tr(
        "Public Key: {e, n}  •  Private Key: {d, n}",
        "المفتاح العام: {e, n}  •  المفتاح الخاص: {d, n}",
      ),
      icon: Icons.settings_suggest_rounded,
      trailing: TextButton.icon(
        onPressed: _generatePrimes,
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tr("Auto Primes", "تلقائي"),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
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
          // Primes p and q Row
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  pController,
                  tr("Prime (p)", "العدد الأولي (p)"),
                  onChanged: (_) => _onPrimeFieldsChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInput(
                  qController,
                  tr("Prime (q)", "العدد الأولي (q)"),
                  onChanged: (_) => _onPrimeFieldsChanged(),
                ),
              ),
            ],
          ),

          // Inline Prime Validation Banner
          if (_primeValidationMessage != null) ...[
            const SizedBox(height: 12),
            _buildInlineValidationBanner(_primeValidationMessage!),
          ],

          // Computed n and φ(n) Live Breakdown Rows (Equal-sized squares)
          if (isPrimesValid) ...[
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildEqualMetricSquare(
                      label: tr("Modulus (n)", "المعيار (n)"),
                      symbolicFormula: "n = p × q",
                      substitutedFormula:
                          "${pController.text} × ${qController.text}",
                      resultValue: nController.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEqualMetricSquare(
                      label: tr("Totient φ(n)", "دالة أويلر φ(n)"),
                      symbolicFormula: "φ(n) = (p−1)(q−1)",
                      substitutedFormula: "$pMinus1 × $qMinus1",
                      resultValue: phiController.text,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 26),

            // Public Exponent (e) Row + Suggest Button
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    eController,
                    tr("Public Exponent (e)", "الأس العام (e)"),
                    icon: Icons.public_rounded,
                    onChanged: (_) => _onEFieldChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _suggestE,
                    icon: const Icon(Icons.lightbulb_outline_rounded,
                        color: Colors.white, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tr("Suggest e", "اقتراح e"),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Clickable Valid e Suggestion Chips
            if (_suggestedEValues.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      tr("Valid coprime e: ", "قيم e المقترحة: "),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    ..._suggestedEValues.map((val) {
                      final bool isSelected =
                          eController.text.trim() == val.toString();
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              eController.text = val.toString();
                              _onEFieldChanged();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : primaryColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              val.toString(),
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            if (_eValidationMessage != null) ...[
              const SizedBox(height: 10),
              _buildInlineValidationBanner(_eValidationMessage!),
            ],

            // Computed Private Exponent (d) & Key Summary
            if (isEncryptionReady) ...[
              const SizedBox(height: 12),
              _buildCompactCalcRow(
                label: tr("Private Exponent (d)", "الأس الخاص (d)"),
                symbolicFormula: "d = e⁻¹ mod φ(n)",
                substitutedFormula:
                    "${eController.text}⁻¹ mod ${phiController.text}",
                resultValue: dController.text,
                highlightColor: accentColor,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "PU = {${eController.text}, ${nController.text}}",
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "PR = {${dController.text}, ${nController.text}}",
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEncryptionCard() {
    return _buildStepCard(
      title: tr("2. Encryption", "2. عملية التشفير"),
      subtitle: tr(
        "Encrypts Message M < ${nController.text} using Public Key {e, n}",
        "تشفير الرسالة M < ${nController.text} باستخدام المفتاح العام {e, n}",
      ),
      icon: Icons.lock_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInput(
            messageController,
            tr("Plaintext Message (M)", "الرسالة الأصلية الرقمية (M)"),
            icon: Icons.tag_rounded,
          ),
          if (_encryptErrorMessage != null) ...[
            const SizedBox(height: 8),
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tr("ENCRYPT (C = M^e mod n)", "تشفير (C = M^e mod n)"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
            const Divider(height: 22),
            _buildCompactCalcRow(
              label: tr("Ciphertext Calculation", "حساب النص المشفر"),
              symbolicFormula: "C = M^e mod n",
              substitutedFormula:
                  "${messageController.text}^${eController.text} mod ${nController.text}",
              resultValue: encryptedController.text,
              onCopy: () =>
                  _copyText(encryptedController.text, 'Ciphertext (C)'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecryptionCard() {
    return _buildStepCard(
      title: tr("3. Decryption", "3. عملية فك التشفير"),
      subtitle: tr(
        "Recovers M from Ciphertext C using Private Key {d, n}",
        "استرجاع الرسالة M من النص المشفر C باستخدام المفتاح الخاص {d, n}",
      ),
      icon: Icons.lock_open_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editable Ciphertext (C) so students can also solve Decryption-only exam problems!
          _buildInput(
            encryptedController,
            tr("Ciphertext (C)", "النص المشفر (C)"),
            icon: Icons.enhanced_encryption_outlined,
            onChanged: (_) => setState(() => isDecrypted = false),
          ),
          if (_decryptErrorMessage != null) ...[
            const SizedBox(height: 8),
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tr("DECRYPT (M = C^d mod n)", "فك التشفير (M = C^d mod n)"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
            const Divider(height: 22),
            _buildCompactCalcRow(
              label: tr("Plaintext Recovery", "استرجاع النص الأصلي"),
              symbolicFormula: "M = C^d mod n",
              substitutedFormula:
                  "${encryptedController.text}^${dController.text} mod ${nController.text}",
              resultValue: decryptedController.text,
              highlightColor: AppTheme.isDark(context)
                  ? const Color(0xFF4ADE80)
                  : Colors.green.shade700,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.successBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successBorder(context),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: AppTheme.successText(context), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(
                                  "Recovered Original Message (M)",
                                  "الرسالة الأصلية المسترجعة (M)",
                                ),
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
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyText(
                        decryptedController.text, 'Recovered Message M'),
                    icon: Icon(Icons.copy_rounded,
                        color: AppTheme.successText(context), size: 20),
                    tooltip: tr('Copy M', 'نسخ M'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineValidationBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningText(context),
              ),
            ),
          ),
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
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: color ?? primaryColor)
              : null,
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

  Widget _buildEqualMetricSquare({
    required String label,
    required String symbolicFormula,
    required String substitutedFormula,
    required String resultValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  symbolicFormula,
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "= $substitutedFormula",
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 11.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SelectableText(
                resultValue,
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalcRow({
    required String label,
    required String symbolicFormula,
    required String substitutedFormula,
    required String resultValue,
    Color? highlightColor,
    VoidCallback? onCopy,
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
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
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    "= $substitutedFormula",
                    style: TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 11.5,
                      color: AppTheme.textSecondary(context),
                    ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  resultValue,
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onCopy,
                    child: Icon(Icons.copy_rounded,
                        size: 15, color: activeColor),
                  ),
                ],
              ],
            ),
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
              tr(
                "Complete Step 1 (or tap 'Auto Primes') to unlock Encryption and Decryption.",
                "أكمل الخطوة 1 (أو اضغط على 'تلقائي') لفتح التشفير وفك التشفير.",
              ),
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
}
