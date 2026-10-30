import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CalcMode { modPow, powerOnly, modOnly }

enum MathOp {
  none,
  power, // a^b (or a^b mod n)
  modInverse, // a^-1 mod n
  gcd, // gcd(a, b)
  primitiveRoot, // Smart Primitive Root: root(q) or isRoot(α, q)
  add, // a + b
  subtract, // a − b
  multiply, // a × b
  divide, // a ÷ b
}

class CalcHistoryEntry {
  final String expression;
  final String result;
  final String? note;

  CalcHistoryEntry({
    required this.expression,
    required this.result,
    this.note,
  });
}

class ModCalculatorScreen extends StatefulWidget {
  const ModCalculatorScreen({super.key});

  @override
  State<ModCalculatorScreen> createState() => _ModCalculatorScreenState();
}

class _ModCalculatorScreenState extends State<ModCalculatorScreen> {
  // Backing controllers preserved for the core BigInt mathematical calculations
  final TextEditingController baseController = TextEditingController();
  final TextEditingController exponentController = TextEditingController();
  final TextEditingController modController = TextEditingController();

  CalcMode _selectedMode = CalcMode.modPow;
  MathOp _currentOp = MathOp.none;
  bool _hasMod = false;

  // 0 = first operand (a), 1 = second operand (b), 2 = modulus (n)
  int _activePart = 0;
  bool _justCalculated = false;

  String result = '';
  String _helperNote = '';
  bool _isError = false;
  List<BigInt> _lastPrimitiveRoots = [];
  BigInt? _lastRootPrime;
  final List<CalcHistoryEntry> _history = [];

  // Signature screen theme color matching the rest of the app
  final Color primaryColor = Colors.orange.shade800;

  @override
  void dispose() {
    baseController.dispose();
    exponentController.dispose();
    modController.dispose();
    super.dispose();
  }

  TextEditingController get _activeController {
    if (_activePart == 1) return exponentController;
    if (_activePart == 2) return modController;
    return baseController;
  }

  bool get _hasSecondOperand =>
      _currentOp == MathOp.power ||
      _currentOp == MathOp.gcd ||
      _currentOp == MathOp.primitiveRoot ||
      _currentOp == MathOp.add ||
      _currentOp == MathOp.subtract ||
      _currentOp == MathOp.multiply ||
      _currentOp == MathOp.divide;

  // Core BigInt mathematical calculation engine
  void _performCalculation({bool commitToHistory = true}) {
    if (commitToHistory) {
      HapticFeedback.mediumImpact();
    }

    _helperNote = '';
    _lastPrimitiveRoots = [];
    _lastRootPrime = null;

    // 1. Modular Multiplicative Inverse: a^-1 mod n
    if (_currentOp == MathOp.modInverse) {
      if (baseController.text.isEmpty || modController.text.isEmpty) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = 'Enter both a and modulus n';
          });
        } else {
          setState(() {
            _isError = false;
            result = '';
            _helperNote = '';
          });
        }
        return;
      }

      try {
        final BigInt a = BigInt.parse(baseController.text);
        final BigInt n = BigInt.parse(modController.text);

        if (n <= BigInt.one) {
          setState(() {
            _isError = true;
            result = 'Modulus n must be > 1';
          });
          return;
        }

        final BigInt g = a.abs().gcd(n.abs());
        if (g != BigInt.one) {
          setState(() {
            _isError = true;
            result = 'No inverse (gcd = $g ≠ 1)';
          });
          return;
        }

        final BigInt inv = a.modInverse(n);
        final String resStr = inv.toString();

        setState(() {
          _isError = false;
          result = resStr;
          _helperNote = 'Verify: ($a × $inv) mod $n = 1';
          if (commitToHistory) {
            _justCalculated = true;
            _recordHistory(_buildPlainExpression(), resStr, _helperNote);
          }
        });
      } catch (_) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = 'Invalid input!';
          });
        }
      }
      return;
    }

    // 2. Smart Primitive Root (α):
    // - If 1 number (q) is entered: Finds the smallest primitive root of prime q & lists all roots!
    // - If 2 numbers (α, q) are entered: Checks if α is a primitive root of prime q!
    if (_currentOp == MathOp.primitiveRoot) {
      final bool hasFirst =
          baseController.text.isNotEmpty && baseController.text != '-';
      final bool hasSecond =
          exponentController.text.isNotEmpty && exponentController.text != '-';

      if (!hasFirst && !hasSecond) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = 'Enter a prime q (or α and q)';
          });
        } else {
          setState(() {
            _isError = false;
            result = '';
            _helperNote = '';
          });
        }
        return;
      }

      try {
        // Subcase 2A: Only 1 number entered -> Find primitive roots of prime q
        if (hasFirst && !hasSecond) {
          final BigInt q = BigInt.parse(baseController.text);
          _evaluateFindPrimitiveRoots(q, commitToHistory: commitToHistory);
          return;
        } else if (!hasFirst && hasSecond) {
          final BigInt q = BigInt.parse(exponentController.text);
          _evaluateFindPrimitiveRoots(q, commitToHistory: commitToHistory);
          return;
        }

        // Subcase 2B: Both numbers entered (α and q) -> Check if α is a primitive root of q
        final BigInt alpha = BigInt.parse(baseController.text);
        final BigInt q = BigInt.parse(exponentController.text);

        if (q <= BigInt.one) {
          setState(() {
            _isError = true;
            result = 'q must be a prime > 1';
          });
          return;
        }

        final bool? isPrimeQ = _isPrimeQuick(q);
        if (isPrimeQ == false) {
          setState(() {
            _isError = true;
            result = '$q is NOT Prime';
            _helperNote = 'Primitive roots in DH/El-Gamal require a prime q';
          });
          return;
        }
        if (isPrimeQ == null) {
          setState(() {
            _isError = true;
            result = 'Prime q is too large';
          });
          return;
        }

        if (alpha <= BigInt.zero || alpha >= q) {
          setState(() {
            _isError = true;
            result = 'α must be between 1 and ${q - BigInt.one}';
          });
          return;
        }

        final List<BigInt>? factors = _primeFactorsOf(q - BigInt.one);
        if (factors == null) {
          setState(() {
            _isError = true;
            result = 'q is too large to factor';
          });
          return;
        }

        final bool isRoot = _isPrimitiveRootFast(alpha, q, factors);
        final List<BigInt> roots = _findPrimitiveRoots(q, factors, maxCount: 40);
        _lastPrimitiveRoots = roots;
        _lastRootPrime = q;

        final String rootsPreview = roots.take(6).map((e) => e.toString()).join(', ') +
            (roots.length > 6 ? '...' : '');
        final String resStr = isRoot ? 'YES (α = $alpha)' : 'NO (α = $alpha)';

        setState(() {
          _isError = false;
          result = resStr;
          _helperNote = isRoot
              ? '✓ $alpha is a Primitive Root of $q  •  Roots: $rootsPreview'
              : '✗ Not a root of $q  •  Valid roots: $rootsPreview';
          if (commitToHistory) {
            _justCalculated = true;
            _recordHistory('isRoot($alpha, $q)', resStr, _helperNote);
          }
        });
      } catch (_) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = 'Invalid input!';
          });
        }
      }
      return;
    }

    // 3. Original Core Modes: modPow (a^b mod n), powerOnly (a^b), modOnly (a mod n)
    if (_currentOp == MathOp.power || _currentOp == MathOp.none) {
      if (_currentOp == MathOp.none && !_hasMod) {
        if (baseController.text.isNotEmpty && baseController.text != '-') {
          try {
            final BigInt a = BigInt.parse(baseController.text);
            setState(() {
              _isError = false;
              result = a.toString();
              _helperNote = _buildSingleNumberInsight(a);
              if (commitToHistory) _justCalculated = true;
            });
          } catch (_) {}
        } else {
          setState(() {
            result = '';
            _helperNote = '';
            _isError = false;
          });
        }
        return;
      }

      if (_currentOp == MathOp.power && _hasMod) {
        _selectedMode = CalcMode.modPow;
      } else if (_currentOp == MathOp.power) {
        _selectedMode = CalcMode.powerOnly;
      } else {
        _selectedMode = CalcMode.modOnly;
      }

      bool isInputValid = false;
      switch (_selectedMode) {
        case CalcMode.modPow:
          isInputValid = baseController.text.isNotEmpty &&
              exponentController.text.isNotEmpty &&
              modController.text.isNotEmpty;
          break;
        case CalcMode.powerOnly:
          isInputValid = baseController.text.isNotEmpty &&
              exponentController.text.isNotEmpty;
          break;
        case CalcMode.modOnly:
          isInputValid =
              baseController.text.isNotEmpty && modController.text.isNotEmpty;
          break;
      }

      if (!isInputValid) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = "Please fill in the required fields";
          });
        } else {
          setState(() {
            _isError = false;
            result = '';
            _helperNote = '';
          });
        }
        return;
      }

      try {
        BigInt base = BigInt.parse(baseController.text);
        BigInt finalResult;

        switch (_selectedMode) {
          case CalcMode.modPow:
            BigInt exponent = BigInt.parse(exponentController.text);
            BigInt mod = BigInt.parse(modController.text);
            finalResult = base.modPow(exponent, mod);
            _helperNote = _buildModInsight(base, mod);
            break;
          case CalcMode.powerOnly:
            int exponent = int.parse(exponentController.text);
            if (!commitToHistory && exponent > 1000) {
              return;
            }
            finalResult = base.pow(exponent);
            _helperNote = '${finalResult.toString().length} digits';
            break;
          case CalcMode.modOnly:
            BigInt mod = BigInt.parse(modController.text);
            finalResult = base % mod;
            _helperNote = _buildModInsight(base, mod);
            break;
        }

        final String resStr = finalResult.toString();
        setState(() {
          _isError = false;
          result = resStr;
          if (commitToHistory) {
            _justCalculated = true;
            _recordHistory(_buildPlainExpression(), resStr, _helperNote);
          }
        });
      } catch (e) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = "Invalid input!";
          });
        }
      }
      return;
    }

    // 4. Binary Arithmetic & GCD Operations (+, −, ×, ÷, GCD) with optional mod n
    final bool hasBoth =
        baseController.text.isNotEmpty && exponentController.text.isNotEmpty;
    final bool hasRequiredMod = !_hasMod || modController.text.isNotEmpty;

    if (!hasBoth || !hasRequiredMod) {
      if (commitToHistory) {
        setState(() {
          _isError = true;
          result = "Please fill in the required fields";
        });
      } else {
        setState(() {
          _isError = false;
          result = '';
          _helperNote = '';
        });
      }
      return;
    }

    try {
      final BigInt a = BigInt.parse(baseController.text);
      final BigInt b = BigInt.parse(exponentController.text);
      BigInt finalResult;

      switch (_currentOp) {
        case MathOp.add:
          finalResult = a + b;
          break;
        case MathOp.subtract:
          finalResult = a - b;
          break;
        case MathOp.multiply:
          finalResult = a * b;
          break;
        case MathOp.divide:
          if (b == BigInt.zero) {
            setState(() {
              _isError = true;
              result = 'Cannot divide by zero';
            });
            return;
          }
          finalResult = a ~/ b;
          final BigInt rem = a.remainder(b);
          _helperNote = 'Quotient: $finalResult  •  Remainder: $rem';
          break;
        case MathOp.gcd:
          finalResult = a.abs().gcd(b.abs());
          _helperNote = finalResult == BigInt.one
              ? 'Coprime (gcd = 1) • Modular inverse exists'
              : 'Not Coprime (Share factor $finalResult)';
          break;
        default:
          return;
      }

      if (_hasMod) {
        final BigInt mod = BigInt.parse(modController.text);
        finalResult = finalResult % mod;
        _helperNote = _buildModInsight(finalResult, mod);
      }

      final String resStr = finalResult.toString();
      setState(() {
        _isError = false;
        result = resStr;
        if (commitToHistory) {
          _justCalculated = true;
          _recordHistory(_buildPlainExpression(), resStr, _helperNote);
        }
      });
    } catch (e) {
      if (commitToHistory) {
        setState(() {
          _isError = true;
          result = "Invalid input!";
        });
      }
    }
  }

  void _evaluateFindPrimitiveRoots(BigInt q, {required bool commitToHistory}) {
    if (q <= BigInt.one) {
      setState(() {
        _isError = true;
        result = 'Enter a prime q > 1';
      });
      return;
    }

    final bool? isPrimeQ = _isPrimeQuick(q);
    if (isPrimeQ == false) {
      setState(() {
        _isError = true;
        result = '$q is NOT Prime';
        _helperNote = 'Enter a prime number q to find its primitive roots';
      });
      return;
    }
    if (isPrimeQ == null) {
      setState(() {
        _isError = true;
        result = 'Prime q is too large';
      });
      return;
    }

    final List<BigInt>? factors = _primeFactorsOf(q - BigInt.one);
    if (factors == null) {
      setState(() {
        _isError = true;
        result = 'Prime q is too large';
      });
      return;
    }

    final List<BigInt> roots = _findPrimitiveRoots(q, factors, maxCount: 50);
    if (roots.isEmpty) {
      setState(() {
        _isError = true;
        result = 'No primitive root found';
      });
      return;
    }

    _lastPrimitiveRoots = roots;
    _lastRootPrime = q;

    final String smallestRoot = roots.first.toString();
    final String allPreview =
        roots.take(7).map((r) => r.toString()).join(', ') +
            (roots.length > 7 ? '...' : '');

    setState(() {
      _isError = false;
      result = smallestRoot;
      _helperNote =
          'Smallest α = $smallestRoot  •  Roots: [$allPreview] (Tap to view all)';
      if (commitToHistory) {
        _justCalculated = true;
        _recordHistory('root($q)', smallestRoot, 'Roots of $q: $allPreview');
      }
    });
  }

  List<BigInt>? _primeFactorsOf(BigInt n) {
    if (n > BigInt.parse('1000000000000')) return null;
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

  bool _isPrimitiveRootFast(BigInt alpha, BigInt q, List<BigInt> primeFactors) {
    if (alpha <= BigInt.zero || alpha >= q) return false;
    if (q == BigInt.two) return alpha == BigInt.one;
    final BigInt phi = q - BigInt.one;
    for (final BigInt p in primeFactors) {
      if (alpha.modPow(phi ~/ p, q) == BigInt.one) {
        return false;
      }
    }
    return true;
  }

  List<BigInt> _findPrimitiveRoots(
    BigInt q,
    List<BigInt> primeFactors, {
    int maxCount = 50,
  }) {
    if (q == BigInt.two) return [BigInt.one];
    final List<BigInt> roots = [];
    // Cap search range so huge primes never freeze UI
    final BigInt limit =
        q > BigInt.from(5000) ? BigInt.from(5000) : q - BigInt.one;
    for (BigInt a = BigInt.two; a <= limit; a += BigInt.one) {
      if (_isPrimitiveRootFast(a, q, primeFactors)) {
        roots.add(a);
        if (roots.length >= maxCount) break;
      }
    }
    return roots;
  }

  void _recordHistory(String expr, String res, String note) {
    _history.insert(
      0,
      CalcHistoryEntry(
        expression: expr,
        result: res,
        note: note.isEmpty ? null : note,
      ),
    );
    if (_history.length > 25) {
      _history.removeLast();
    }
  }

  String _buildSingleNumberInsight(BigInt a) {
    if (a <= BigInt.one) return '';
    final bool? prime = _isPrimeQuick(a);
    if (prime == null) return '${a.toString().length} digits';
    return prime ? '$a is a Prime number' : '$a is a Composite number';
  }

  String _buildModInsight(BigInt a, BigInt n) {
    if (n <= BigInt.one) return '';
    final List<String> notes = [];
    final BigInt g = a.abs().gcd(n.abs());
    if (g == BigInt.one) {
      notes.add('gcd(a,n) = 1 (Coprime)');
    } else {
      notes.add('gcd(a,n) = $g');
    }
    final bool? primeN = _isPrimeQuick(n);
    if (primeN != null) {
      notes.add(primeN ? 'n is Prime' : 'n is Composite');
    }
    return notes.join('  •  ');
  }

  bool? _isPrimeQuick(BigInt n) {
    if (n <= BigInt.one) return false;
    if (n == BigInt.two || n == BigInt.from(3)) return true;
    if (n.isEven || n % BigInt.from(3) == BigInt.zero) return false;
    if (n > BigInt.parse('1000000000000')) return null;
    BigInt i = BigInt.from(5);
    while (i * i <= n) {
      if (n % i == BigInt.zero || n % (i + BigInt.two) == BigInt.zero) {
        return false;
      }
      i += BigInt.from(6);
    }
    return true;
  }

  String _buildPlainExpression() {
    final String a = baseController.text.isEmpty ? 'a' : baseController.text;
    final String b =
        exponentController.text.isEmpty ? 'b' : exponentController.text;
    final String n = modController.text.isEmpty ? 'n' : modController.text;

    if (_currentOp == MathOp.modInverse) {
      return '$a⁻¹ mod $n';
    }

    String core;
    switch (_currentOp) {
      case MathOp.none:
        core = a;
        break;
      case MathOp.power:
        core = '$a^$b';
        break;
      case MathOp.add:
        core = _hasMod ? '($a + $b)' : '$a + $b';
        break;
      case MathOp.subtract:
        core = _hasMod ? '($a − $b)' : '$a − $b';
        break;
      case MathOp.multiply:
        core = _hasMod ? '($a × $b)' : '$a × $b';
        break;
      case MathOp.divide:
        core = _hasMod ? '($a ÷ $b)' : '$a ÷ $b';
        break;
      case MathOp.gcd:
        core = 'gcd($a, $b)';
        break;
      case MathOp.primitiveRoot:
        core = exponentController.text.isEmpty
            ? 'root($a)'
            : 'isRoot($a, $b)';
        break;
      case MathOp.modInverse:
        core = '$a⁻¹';
        break;
    }

    if (_hasMod) {
      return '$core mod $n';
    }
    return core;
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justCalculated) {
        if (_activePart == 0 && _currentOp == MathOp.none && !_hasMod) {
          baseController.clear();
        }
        _justCalculated = false;
      }

      if (_isError) {
        _isError = false;
        result = '';
      }

      final ctrl = _activeController;
      if (ctrl.text == '0') {
        ctrl.text = digit;
      } else if (ctrl.text == '-0') {
        ctrl.text = '-$digit';
      } else {
        ctrl.text += digit;
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onBinaryOpPressed(MathOp op) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated && result.isNotEmpty && !_isError && !result.startsWith('YES') && !result.startsWith('NO')) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _hasMod = false;
        _justCalculated = false;
      }
      if (baseController.text.isEmpty) {
        baseController.text = '0';
      }
      _currentOp = op;
      _activePart = 1;
      if (_isError) {
        _isError = false;
        result = '';
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onModInversePressed() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated && result.isNotEmpty && !_isError && !result.startsWith('YES') && !result.startsWith('NO')) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _justCalculated = false;
      }
      if (baseController.text.isEmpty) {
        baseController.text = '0';
      }
      _currentOp = MathOp.modInverse;
      exponentController.clear();
      _hasMod = true;
      _activePart = 2;
      if (_isError) {
        _isError = false;
        result = '';
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onPrimitiveRootPressed() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated && result.isNotEmpty && !_isError && !result.startsWith('YES') && !result.startsWith('NO')) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _hasMod = false;
        _justCalculated = false;
      }
      _currentOp = MathOp.primitiveRoot;
      _hasMod = false;
      modController.clear();
      // If user already typed a number (e.g. 23), evaluate root(23) immediately
      // and also allow typing a 2nd number if they want to check isRoot(a, q)!
      if (baseController.text.isNotEmpty) {
        _activePart = 1;
      } else {
        _activePart = 0;
      }
      if (_isError) {
        _isError = false;
        result = '';
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onModOperatorPressed() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated && result.isNotEmpty && !_isError && !result.startsWith('YES') && !result.startsWith('NO')) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _currentOp = MathOp.none;
        _justCalculated = false;
      }
      if (_currentOp == MathOp.primitiveRoot) {
        _currentOp = MathOp.none;
      }
      if (baseController.text.isEmpty) {
        baseController.text = '0';
      }
      if (_hasSecondOperand && exponentController.text.isEmpty) {
        exponentController.text = '1';
      }
      _hasMod = true;
      _activePart = 2;
      if (_isError) {
        _isError = false;
        result = '';
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _justCalculated = false;
      if (_isError) {
        _isError = false;
        result = '';
      }

      if (_activePart == 2) {
        if (modController.text.isNotEmpty) {
          modController.text =
              modController.text.substring(0, modController.text.length - 1);
        } else {
          _hasMod = false;
          if (_currentOp == MathOp.modInverse) {
            _currentOp = MathOp.none;
            _activePart = 0;
          } else {
            _activePart = _hasSecondOperand ? 1 : 0;
          }
        }
      } else if (_activePart == 1) {
        if (exponentController.text.isNotEmpty) {
          exponentController.text = exponentController.text
              .substring(0, exponentController.text.length - 1);
        } else {
          _currentOp = MathOp.none;
          _activePart = 0;
        }
      } else {
        if (baseController.text.isNotEmpty) {
          baseController.text =
              baseController.text.substring(0, baseController.text.length - 1);
        } else if (_currentOp == MathOp.primitiveRoot) {
          _currentOp = MathOp.none;
        }
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _onToggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      final ctrl = _activeController;
      if (ctrl.text.startsWith('-')) {
        ctrl.text = ctrl.text.substring(1);
      } else if (ctrl.text.isNotEmpty) {
        ctrl.text = '-${ctrl.text}';
      } else {
        ctrl.text = '-';
      }
    });
    _performCalculation(commitToHistory: false);
  }

  void _resetFields() {
    HapticFeedback.mediumImpact();
    setState(() {
      baseController.clear();
      exponentController.clear();
      modController.clear();
      _currentOp = MathOp.none;
      _hasMod = false;
      _activePart = 0;
      _justCalculated = false;
      result = "";
      _helperNote = "";
      _lastPrimitiveRoots = [];
      _lastRootPrime = null;
      _isError = false;
    });
  }

  void _useAns() {
    if (result.isEmpty || _isError || result.startsWith('YES') || result.startsWith('NO')) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      if (_justCalculated) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _currentOp = MathOp.none;
        _hasMod = false;
        _activePart = 0;
        _justCalculated = false;
      } else {
        _activeController.text = result;
      }
    });
    _performCalculation(commitToHistory: false);
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim() ?? '';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9-]'), '');
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Clipboard does not contain a valid number'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _justCalculated = false;
      _activeController.text = cleaned;
    });
    _performCalculation(commitToHistory: false);
  }

  void _copyResult() {
    if (result.isEmpty || _isError) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Result copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAllPrimitiveRootsSheet() {
    if (_lastPrimitiveRoots.isEmpty || _lastRootPrime == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_rounded, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Primitive Roots of q = $_lastRootPrime',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap any primitive root α below to copy it to your clipboard:',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                ),
                const Divider(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _lastPrimitiveRoots.map((rootVal) {
                        final bool isSmallest =
                            rootVal == _lastPrimitiveRoots.first;
                        return ActionChip(
                          backgroundColor: isSmallest
                              ? primaryColor
                              : const Color(0xFFFFF7ED),
                          side: BorderSide(
                            color: isSmallest
                                ? primaryColor
                                : primaryColor.withValues(alpha: 0.3),
                          ),
                          label: Text(
                            isSmallest ? '$rootVal (Smallest)' : '$rootVal',
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontWeight: FontWeight.bold,
                              color: isSmallest ? Colors.white : primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: rootVal.toString()));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Copied primitive root α = $rootVal'),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDetectedOperationTitle() {
    switch (_currentOp) {
      case MathOp.none:
        return _hasMod ? 'Modulo • a mod n' : 'Modular & Crypto Calculator';
      case MathOp.power:
        return _hasMod
            ? 'Modular Exponentiation • a^b mod n'
            : 'Exponentiation • a^b';
      case MathOp.modInverse:
        return 'Modular Multiplicative Inverse • a⁻¹ mod n';
      case MathOp.gcd:
        return 'Greatest Common Divisor • gcd(a, b)';
      case MathOp.primitiveRoot:
        return exponentController.text.isEmpty
            ? 'Find Primitive Roots • root(q)'
            : 'Verify Primitive Root • isRoot(α, q)';
      case MathOp.add:
        return _hasMod ? 'Modular Addition • (a + b) mod n' : 'Addition • a + b';
      case MathOp.subtract:
        return _hasMod
            ? 'Modular Subtraction • (a − b) mod n'
            : 'Subtraction • a − b';
      case MathOp.multiply:
        return _hasMod
            ? 'Modular Multiplication • (a × b) mod n'
            : 'Multiplication • a × b';
      case MathOp.divide:
        return _hasMod
            ? 'Integer Division • (a ÷ b) mod n'
            : 'Integer Division • a ÷ b';
    }
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Calculation History',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _history.clear());
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.delete_outline_rounded,
                            color: Colors.red.shade700, size: 18),
                        label: Text(
                          'Clear',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                if (_history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Press "=" on any calculation to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              item.expression,
                              style: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '= ${item.result}',
                                  style: TextStyle(
                                    fontFamily: 'Courier New',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                if (item.note != null)
                                  Text(
                                    item.note!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.copy_rounded,
                                  color: primaryColor, size: 20),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: item.result));
                                Navigator.pop(context);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Copied ${item.result} to clipboard'),
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              if (!item.result.startsWith('YES') &&
                                  !item.result.startsWith('NO')) {
                                setState(() {
                                  baseController.text = item.result;
                                  exponentController.clear();
                                  modController.clear();
                                  _currentOp = MathOp.none;
                                  _hasMod = false;
                                  _activePart = 0;
                                  result = item.result;
                                  _isError = false;
                                });
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
            Icon(Icons.speed_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'Modular Exponentiation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showHistoryModal,
            tooltip: 'Calculation History',
            icon: Badge(
              isLabelVisible: _history.isNotEmpty,
              label: Text('${_history.length}'),
              backgroundColor: Colors.white,
              textColor: primaryColor,
              child: const Icon(Icons.history_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. PREMIUM DISPLAY SCREEN CARD
            Expanded(
              flex: 41,
              child: _buildDisplayCard(),
            ),

            // 2. PROFESSIONAL CRYPTOGRAPHIC & ARITHMETIC KEYPAD
            Expanded(
              flex: 59,
              child: _buildKeypadSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayCard() {
    final bool hasValidResult = result.isNotEmpty && !_isError;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtle Top Header Strip inside Display Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.1),
                    primaryColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.functions_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getDetectedOperationTitle(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_history.isNotEmpty)
                    GestureDetector(
                      onTap: _showHistoryModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'ANS = ${_history.first.result}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Courier New',
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Center Interactive Formula Canvas
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: _buildInteractiveFormulaStream(),
                ),
              ),
            ),

            // Contextual Crypto Insight Strip (tappable when showing Primitive Roots list!)
            if (_helperNote.isNotEmpty && !_isError)
              GestureDetector(
                onTap: _lastPrimitiveRoots.isNotEmpty
                    ? _showAllPrimitiveRootsSheet
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  color: Colors.teal.shade50.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _lastPrimitiveRoots.isNotEmpty
                            ? Icons.touch_app_rounded
                            : Icons.verified_outlined,
                        size: 13,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _helperNote,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Result Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _isError
                    ? const Color(0xFFFEF2F2)
                    : (hasValidResult
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFF8FAFC)),
                border: Border(
                  top: BorderSide(
                    color: _isError
                        ? Colors.red.shade200
                        : (hasValidResult
                            ? primaryColor.withValues(alpha: 0.25)
                            : Colors.grey.shade200),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.shade100
                          : primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isError ? '!' : '=',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isError ? Colors.red.shade800 : primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: SelectableText(
                        result.isEmpty ? '0' : result,
                        style: TextStyle(
                          fontFamily: _isError ? 'Roboto' : 'Courier New',
                          fontSize: _isError ? 14 : 26,
                          fontWeight: FontWeight.bold,
                          color: _isError
                              ? Colors.red.shade700
                              : (result.isEmpty
                                  ? Colors.grey.shade400
                                  : const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                  ),
                  if (_lastPrimitiveRoots.length > 1 && !_isError) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _showAllPrimitiveRootsSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.list_alt_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'All (${_lastPrimitiveRoots.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (hasValidResult) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _copyResult,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveFormulaStream() {
    final bool isBaseActive = _activePart == 0;
    final bool isSecondActive = _activePart == 1;
    final bool isModActive = _activePart == 2;

    final String aText =
        baseController.text.isEmpty ? 'a' : baseController.text;
    final String bText =
        exponentController.text.isEmpty ? 'b' : exponentController.text;
    final String nText = modController.text.isEmpty ? 'n' : modController.text;

    Widget buildToken({
      required String text,
      required bool isEmpty,
      required bool isActive,
      required VoidCallback onTap,
      double fontSize = 32,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: 0.12)
                : (isEmpty ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? primaryColor
                  : (isEmpty ? Colors.grey.shade300 : Colors.transparent),
              width: 1.8,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isEmpty
                  ? (isActive ? primaryColor : Colors.grey.shade400)
                  : const Color(0xFF0F172A),
            ),
          ),
        ),
      );
    }

    Widget coreWidget;

    if (_currentOp == MathOp.modInverse) {
      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          buildToken(
            text: aText,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
          ),
          Transform.translate(
            offset: const Offset(2, -16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '−1',
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_currentOp == MathOp.primitiveRoot) {
      // Smart display:
      // 1st slot = q (or α if 2nd slot used), 2nd optional slot = q when verifying isRoot(α, q)
      final bool isVerifying = exponentController.text.isNotEmpty;
      final String firstPlaceholder = isVerifying ? 'α' : 'q';
      final String secondPlaceholder = isVerifying ? 'q' : 'q?';

      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isVerifying ? 'isRoot(' : 'root(',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          buildToken(
            text: baseController.text.isEmpty
                ? firstPlaceholder
                : baseController.text,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
            fontSize: 25,
          ),
          if (isSecondActive || isVerifying) ...[
            Text(
              ', ',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            buildToken(
              text: exponentController.text.isEmpty
                  ? secondPlaceholder
                  : exponentController.text,
              isEmpty: exponentController.text.isEmpty,
              isActive: isSecondActive,
              onTap: () => setState(() => _activePart = 1),
              fontSize: 25,
            ),
          ],
          Text(
            ')',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      );
    } else if (_currentOp == MathOp.gcd) {
      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'gcd(',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          buildToken(
            text: aText,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
            fontSize: 26,
          ),
          Text(
            ', ',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          buildToken(
            text: bText,
            isEmpty: exponentController.text.isEmpty,
            isActive: isSecondActive,
            onTap: () => setState(() => _activePart = 1),
            fontSize: 26,
          ),
          Text(
            ')',
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      );
    } else if (_currentOp == MathOp.power) {
      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          buildToken(
            text: aText,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
          ),
          Transform.translate(
            offset: const Offset(3, -15),
            child: GestureDetector(
              onTap: () => setState(() => _activePart = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSecondActive
                      ? primaryColor.withValues(alpha: 0.16)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSecondActive
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.35),
                    width: 1.6,
                  ),
                ),
                child: Text(
                  bText,
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: exponentController.text.isEmpty
                        ? primaryColor.withValues(alpha: 0.5)
                        : primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_hasSecondOperand) {
      String opSymbol = '+';
      switch (_currentOp) {
        case MathOp.add:
          opSymbol = '+';
          break;
        case MathOp.subtract:
          opSymbol = '−';
          break;
        case MathOp.multiply:
          opSymbol = '×';
          break;
        case MathOp.divide:
          opSymbol = '÷';
          break;
        default:
          break;
      }

      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasMod)
            Text(
              '(',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          buildToken(
            text: aText,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              opSymbol,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          buildToken(
            text: bText,
            isEmpty: exponentController.text.isEmpty,
            isActive: isSecondActive,
            onTap: () => setState(() => _activePart = 1),
          ),
          if (_hasMod)
            Text(
              ')',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      );
    } else {
      coreWidget = buildToken(
        text: aText,
        isEmpty: baseController.text.isEmpty,
        isActive: isBaseActive,
        onTap: () => setState(() => _activePart = 0),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        coreWidget,
        if (_hasMod) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'mod',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          buildToken(
            text: nText,
            isEmpty: modController.text.isEmpty,
            isActive: isModActive,
            onTap: () => setState(() => _activePart = 2),
          ),
        ],
      ],
    );
  }

  Widget _buildKeypadSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Cryptographic Function Bar: x^y, MOD, e^-1, GCD, ROOT (α)
          SizedBox(
            height: 50,
            child: Row(
              children: [
                _buildCryptoFunctionKey(
                  label: 'xʸ',
                  subtitle: 'Power',
                  isSelected: _currentOp == MathOp.power,
                  onTap: () => _onBinaryOpPressed(MathOp.power),
                ),
                _buildCryptoFunctionKey(
                  label: 'MOD',
                  subtitle: 'a mod n',
                  isSelected: _hasMod && _currentOp != MathOp.modInverse,
                  onTap: _onModOperatorPressed,
                ),
                _buildCryptoFunctionKey(
                  label: 'e⁻¹',
                  subtitle: 'Inverse',
                  isSelected: _currentOp == MathOp.modInverse,
                  onTap: _onModInversePressed,
                ),
                _buildCryptoFunctionKey(
                  label: 'GCD',
                  subtitle: 'Coprime',
                  isSelected: _currentOp == MathOp.gcd,
                  onTap: () => _onBinaryOpPressed(MathOp.gcd),
                ),
                _buildCryptoFunctionKey(
                  label: 'ROOT',
                  subtitle: 'Prim. α',
                  isSelected: _currentOp == MathOp.primitiveRoot,
                  onTap: _onPrimitiveRootPressed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Main 4x5 Calculator Keypad
          // Row 1: AC, ⌫, ANS, ÷
          Expanded(
            child: Row(
              children: [
                _buildKeyButton(
                  label: 'AC',
                  subtitle: 'Clear',
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: Colors.red.shade200,
                  textColor: Colors.red.shade700,
                  onTap: _resetFields,
                ),
                _buildKeyButton(
                  label: '⌫',
                  subtitle: 'Delete',
                  bgColor: const Color(0xFFF1F5F9),
                  textColor: const Color(0xFF334155),
                  onTap: _onBackspace,
                ),
                _buildKeyButton(
                  label: 'ANS',
                  subtitle: 'Last',
                  bgColor: const Color(0xFFF1F5F9),
                  textColor: primaryColor,
                  onTap: _useAns,
                ),
                _buildArithmeticOpKey('÷', MathOp.divide),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: 7, 8, 9, ×
          Expanded(
            child: Row(
              children: [
                _buildDigitButton('7'),
                _buildDigitButton('8'),
                _buildDigitButton('9'),
                _buildArithmeticOpKey('×', MathOp.multiply),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: 4, 5, 6, −
          Expanded(
            child: Row(
              children: [
                _buildDigitButton('4'),
                _buildDigitButton('5'),
                _buildDigitButton('6'),
                _buildArithmeticOpKey('−', MathOp.subtract),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 4: 1, 2, 3, +
          Expanded(
            child: Row(
              children: [
                _buildDigitButton('1'),
                _buildDigitButton('2'),
                _buildDigitButton('3'),
                _buildArithmeticOpKey('+', MathOp.add),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 5: ±, 0, PASTE, =
          Expanded(
            child: Row(
              children: [
                _buildKeyButton(
                  label: '±',
                  bgColor: const Color(0xFFF1F5F9),
                  textColor: const Color(0xFF334155),
                  onTap: _onToggleSign,
                ),
                _buildDigitButton('0'),
                _buildKeyButton(
                  label: 'PASTE',
                  icon: Icons.content_paste_rounded,
                  bgColor: const Color(0xFFF1F5F9),
                  textColor: const Color(0xFF334155),
                  onTap: _pasteFromClipboard,
                ),
                _buildEqualsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoFunctionKey({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: Material(
          color: isSelected ? primaryColor : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          elevation: isSelected ? 2 : 0,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : primaryColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArithmeticOpKey(String symbol, MathOp op) {
    final bool isSelected = _currentOp == op;
    return _buildKeyButton(
      label: symbol,
      bgColor: isSelected ? primaryColor : const Color(0xFFFFF7ED),
      borderColor:
          isSelected ? primaryColor : primaryColor.withValues(alpha: 0.25),
      textColor: isSelected ? Colors.white : primaryColor,
      isLarge: true,
      onTap: () => _onBinaryOpPressed(op),
    );
  }

  Widget _buildDigitButton(String digit) {
    return _buildKeyButton(
      label: digit,
      bgColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      textColor: const Color(0xFF0F172A),
      isLarge: true,
      onTap: () => _onDigitPressed(digit),
    );
  }

  Widget _buildEqualsButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _performCalculation(commitToHistory: true),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Text(
                  '=',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton({
    required String label,
    String? subtitle,
    IconData? icon,
    required Color bgColor,
    Color? borderColor,
    required Color textColor,
    required VoidCallback onTap,
    int flex = 1,
    bool isLarge = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: primaryColor.withValues(alpha: 0.15),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor ?? const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Icon(icon, size: 17, color: textColor)
                    else
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: isLarge ? 'Courier New' : 'Roboto',
                          fontSize: isLarge ? 24 : 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    if (subtitle != null || icon != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle ?? label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
