import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'inverse_calc_screen.dart';

enum CalcMode { modPow, powerOnly, modOnly }

// Keypad modes: choose which crypto function keys are shown
enum CalcUiMode { basic, modular, numberTheory }

enum MathOp {
  none,
  power, // a^b (or a^b mod n)
  modInverse, // a^-1 mod n
  gcd, // gcd(a, b)
  primitiveRoot, // Smart Primitive Root: root(q) or isRoot(α, q)
  nextPrime, // smallest prime > n
  prevPrime, // largest prime < n
  add, // a + b
  subtract, // a − b
  multiply, // a × b
  divide, // a ÷ b
}

class CalcHistoryEntry {
  final String expression;
  final String result;
  final String? note;

  // Snapshot of the whole expression so it can be reloaded later
  final String baseText;
  final String exponentText;
  final String modText;
  final MathOp op;
  final bool hasMod;
  bool pinned;

  CalcHistoryEntry({
    required this.expression,
    required this.result,
    this.note,
    this.baseText = '',
    this.exponentText = '',
    this.modText = '',
    this.op = MathOp.none,
    this.hasMod = false,
    this.pinned = false,
  });
}

// Content of the "Steps" sheet
class _StepsData {
  final String title;
  final List<String> intro;
  final List<String> headers;
  final List<List<String>> rows;
  final String conclusion;
  final String? inverseE;
  final String? inverseN;

  _StepsData({
    required this.title,
    required this.intro,
    required this.headers,
    required this.rows,
    required this.conclusion,
    this.inverseE,
    this.inverseN,
  });
}

class ModCalculatorScreen extends StatefulWidget {
  const ModCalculatorScreen({super.key});

  @override
  State<ModCalculatorScreen> createState() => _ModCalculatorScreenState();
}

class _ModCalculatorScreenState extends State<ModCalculatorScreen>
    with SingleTickerProviderStateMixin {
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

  CalcUiMode _uiMode = CalcUiMode.modular;
  String _verifyNote = '';

  // Shakes the display card when "=" gives an error
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool get _isSingleOperandOp =>
      _currentOp == MathOp.primitiveRoot ||
      _currentOp == MathOp.nextPrime ||
      _currentOp == MathOp.prevPrime;

  // Signature screen theme color matching the rest of the app
  Color get primaryColor => AppTheme.orangeAccent(context);

  @override
  void dispose() {
    baseController.dispose();
    exponentController.dispose();
    modController.dispose();
    _shakeController.dispose();
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
    _verifyNote = '';
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

        final BigInt normA = ((a % n) + n) % n;
        final BigInt g = normA.gcd(n.abs());
        if (g != BigInt.one) {
          setState(() {
            _isError = true;
            result = 'No inverse (gcd = $g ≠ 1)';
          });
          return;
        }

        final BigInt inv = normA.modInverse(n);
        final String resStr = inv.toString();

        setState(() {
          _isError = false;
          result = resStr;
          _helperNote = 'gcd(a,n) = 1 (Coprime)  •  Inverse exists';
          _verifyNote = '($a × $inv) mod $n = 1 ✓';
          if (commitToHistory) {
            _justCalculated = true;
            _recordHistory(_buildPlainExpression(), resStr, _helperNote);
          }
        });
      } catch (_) {
        setState(() {
          if (commitToHistory) {
            _isError = true;
            result = 'Invalid input!';
          } else {
            _isError = false;
            result = '';
            _helperNote = '';
          }
        });
      }
      return;
    }

    // 2. Smart Primitive Root (α):
    // - 1st slot (baseController) = Prime modulus q
    // - 2nd slot (exponentController) = Optional candidate root α to verify against q
    // - If 1 number (q) is entered: Finds the smallest primitive root of prime q & lists all roots!
    // - If 2 numbers (q, α) are entered: Checks if α is a primitive root of prime q!
    if (_currentOp == MathOp.primitiveRoot) {
      final bool hasFirst =
          baseController.text.isNotEmpty && baseController.text != '-';
      final bool hasSecond =
          exponentController.text.isNotEmpty && exponentController.text != '-';

      if (!hasFirst && !hasSecond) {
        if (commitToHistory) {
          setState(() {
            _isError = true;
            result = 'Enter a prime q (and optional α)';
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
        // Subcase 2A: Only 1st number (q) entered -> Find primitive roots of prime q
        if (hasFirst && !hasSecond) {
          final BigInt q = BigInt.parse(baseController.text);
          _evaluateFindPrimitiveRoots(q, commitToHistory: commitToHistory);
          return;
        } else if (!hasFirst && hasSecond) {
          setState(() {
            _isError = true;
            result = 'Enter prime modulus q in the 1st box';
          });
          return;
        }

        // Subcase 2B: Both numbers entered (1st = q, 2nd = α) -> Check if α is a primitive root of q
        final BigInt q = BigInt.parse(baseController.text);
        final BigInt alpha = BigInt.parse(exponentController.text);

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
            result = 'q = $q is NOT Prime';
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
            result = 'α must be between 1 and ${q - BigInt.one} (q−1)';
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
        final List<BigInt> roots = _findPrimitiveRoots(q, factors, maxCount: 50);
        _lastPrimitiveRoots = roots;
        _lastRootPrime = q;

        final String rootsPreview = roots.take(6).map((e) => e.toString()).join(', ') +
            (roots.length > 6 ? '...' : '');
        final String resStr = isRoot ? 'YES (α = $alpha)' : 'NO (α = $alpha)';
        _verifyNote = _rootVerifyNote(alpha, q, factors);

        setState(() {
          _isError = false;
          result = resStr;
          _helperNote = isRoot
              ? '✓ α = $alpha is a Primitive Root of q = $q  •  Roots: [$rootsPreview]'
              : '✗ α = $alpha is NOT a root of q = $q  •  Valid roots: [$rootsPreview]';
          if (commitToHistory) {
            _justCalculated = true;
            _recordHistory('isRoot(q=$q, α=$alpha)', resStr, _helperNote);
          }
        });
      } catch (_) {
        setState(() {
          if (commitToHistory) {
            _isError = true;
            result = 'Invalid input!';
          } else {
            _isError = false;
            result = '';
            _helperNote = '';
          }
        });
      }
      return;
    }

    // 2b. Next / Previous prime
    if (_currentOp == MathOp.nextPrime || _currentOp == MathOp.prevPrime) {
      _evaluateNearbyPrime(
        next: _currentOp == MathOp.nextPrime,
        commitToHistory: commitToHistory,
      );
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
            if (mod <= BigInt.zero) {
              setState(() {
                _isError = true;
                result = 'Modulus n must be > 0';
              });
              return;
            }
            if (exponent < BigInt.zero) {
              if (mod == BigInt.one) {
                finalResult = BigInt.zero;
              } else {
                final BigInt normBase = ((base % mod) + mod) % mod;
                final BigInt g = normBase.gcd(mod);
                if (g != BigInt.one) {
                  setState(() {
                    _isError = true;
                    result = 'No inverse for negative exponent (gcd = $g ≠ 1)';
                  });
                  return;
                }
                final BigInt inv = normBase.modInverse(mod);
                finalResult = inv.modPow(-exponent, mod);
              }
            } else {
              final BigInt normBase = ((base % mod) + mod) % mod;
              finalResult = normBase.modPow(exponent, mod);
            }
            _helperNote = _buildModInsight(base, mod);
            if (exponent >= BigInt.zero) {
              final String bin = exponent.toRadixString(2);
              _verifyNote =
                  'Square-and-Multiply: $exponent = $bin₂ (${bin.length} bits) ✓';
            }
            break;
          case CalcMode.powerOnly:
            int exponent = int.parse(exponentController.text);
            if (exponent < 0) {
              setState(() {
                _isError = true;
                result = 'Tap MOD for negative exponents (a⁻ᵇ mod n)';
              });
              return;
            }
            if (!commitToHistory && exponent > 1000) {
              return;
            }
            finalResult = base.pow(exponent);
            _helperNote = '${finalResult.toString().length} digits';
            break;
          case CalcMode.modOnly:
            BigInt mod = BigInt.parse(modController.text);
            if (mod <= BigInt.zero) {
              setState(() {
                _isError = true;
                result = 'Modulus n must be > 0';
              });
              return;
            }
            finalResult = ((base % mod) + mod) % mod;
            _helperNote = _buildModInsight(base, mod);
            _verifyNote =
                '$base = ${(base - finalResult) ~/ mod} × $mod + $finalResult ✓';
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
        setState(() {
          if (commitToHistory) {
            _isError = true;
            result = "Invalid input!";
          } else {
            _isError = false;
            result = '';
            _helperNote = '';
          }
        });
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
          _verifyNote =
              '$finalResult × $b + $rem = ${finalResult * b + rem} ✓';
          break;
        case MathOp.gcd:
          finalResult = a.abs().gcd(b.abs());
          _helperNote = finalResult == BigInt.one
              ? 'Coprime (gcd = 1) • Modular inverse exists'
              : 'Not Coprime (Share factor $finalResult)';
          if (finalResult > BigInt.zero) {
            _verifyNote =
                '${a.abs()} ÷ $finalResult = ${a.abs() ~/ finalResult} and ${b.abs()} ÷ $finalResult = ${b.abs() ~/ finalResult} (both exact ✓)';
          }
          break;
        default:
          return;
      }

      if (_hasMod) {
        final BigInt mod = BigInt.parse(modController.text);
        if (mod <= BigInt.zero) {
          setState(() {
            _isError = true;
            result = 'Modulus n must be > 0';
          });
          return;
        }
        finalResult = ((finalResult % mod) + mod) % mod;
        _helperNote = _buildModInsight(finalResult, mod);
        _verifyNote = '';
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
      setState(() {
        if (commitToHistory) {
          _isError = true;
          result = "Invalid input!";
        } else {
          _isError = false;
          result = '';
          _helperNote = '';
        }
      });
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
    _verifyNote = _rootVerifyNote(roots.first, q, factors);
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
        baseText: baseController.text,
        exponentText: exponentController.text,
        modText: modController.text,
        op: _currentOp,
        hasMod: _hasMod,
      ),
    );
    if (_history.length > 25) {
      final int idx = _history.lastIndexWhere((e) => !e.pinned);
      if (idx != -1) _history.removeAt(idx);
    }
  }

  // Shows why a candidate α is (or is not) a primitive root of q
  String _rootVerifyNote(BigInt alpha, BigInt q, List<BigInt> factors) {
    if (q <= BigInt.two || factors.isEmpty) return '';
    final BigInt phi = q - BigInt.one;
    final List<String> parts = [];
    bool noneIsOne = true;
    for (final BigInt p in factors) {
      final BigInt e = phi ~/ p;
      final BigInt v = alpha.modPow(e, q);
      if (v == BigInt.one) noneIsOne = false;
      parts.add('$alpha^$e = $v');
    }
    return noneIsOne
        ? '${parts.join(',  ')}  (none equals 1 → order is q−1 ✓)'
        : '${parts.join(',  ')}  (one equals 1 → not a primitive root)';
  }

  // Next / previous prime around n
  void _evaluateNearbyPrime({
    required bool next,
    required bool commitToHistory,
  }) {
    final String text = baseController.text;
    if (text.isEmpty || text == '-') {
      setState(() {
        if (commitToHistory) {
          _isError = true;
          result = 'Enter a number n';
        } else {
          _isError = false;
          result = '';
          _helperNote = '';
        }
      });
      return;
    }

    BigInt n;
    try {
      n = BigInt.parse(text);
    } catch (_) {
      setState(() {
        _isError = true;
        result = 'Invalid input!';
      });
      return;
    }

    final BigInt limit = BigInt.parse('1000000000000');
    if (n.abs() > limit) {
      setState(() {
        _isError = true;
        result = 'Number is too large (max 10¹²)';
      });
      return;
    }

    BigInt? found;
    if (next) {
      BigInt c = n + BigInt.one;
      if (c < BigInt.two) c = BigInt.two;
      while (true) {
        final bool? p = _isPrimeQuick(c);
        if (p == null) break;
        if (p) {
          found = c;
          break;
        }
        c += BigInt.one;
      }
    } else {
      BigInt c = n - BigInt.one;
      while (c >= BigInt.two) {
        if (_isPrimeQuick(c) == true) {
          found = c;
          break;
        }
        c -= BigInt.one;
      }
    }

    if (found == null) {
      setState(() {
        _isError = true;
        result = next ? 'No prime found' : 'No prime below $n';
      });
      return;
    }

    final String resStr = found.toString();
    setState(() {
      _isError = false;
      result = resStr;
      _helperNote = _buildSingleNumberInsight(n);
      _verifyNote = next
          ? '$found is prime ✓  •  no prime between $n and $found'
          : '$found is prime ✓  •  no prime between $found and $n';
      if (commitToHistory) {
        _justCalculated = true;
        _recordHistory(_buildPlainExpression(), resStr, _helperNote);
      }
    });
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
            : 'isRoot(q=$a, α=$b)';
        break;
      case MathOp.nextPrime:
        core = 'nextPrime($a)';
        break;
      case MathOp.prevPrime:
        core = 'prevPrime($a)';
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
      if (_currentOp != MathOp.primitiveRoot &&
          _justCalculated &&
          result.isNotEmpty &&
          !_isError &&
          !result.startsWith('YES') &&
          !result.startsWith('NO')) {
        baseController.text = result;
        exponentController.clear();
        modController.clear();
        _hasMod = false;
        _justCalculated = false;
      }
      _currentOp = MathOp.primitiveRoot;
      _hasMod = false;
      modController.clear();
      // 1st slot (baseController) = prime q
      // 2nd slot (exponentController) = optional candidate α to verify against q
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

  void _onNearbyPrimePressed(MathOp op) {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_isSingleOperandOp &&
          _justCalculated &&
          result.isNotEmpty &&
          !_isError &&
          !result.startsWith('YES') &&
          !result.startsWith('NO')) {
        baseController.text = result;
        _justCalculated = false;
      } else if ((_currentOp == MathOp.nextPrime ||
              _currentOp == MathOp.prevPrime) &&
          _justCalculated &&
          result.isNotEmpty &&
          !_isError) {
        // Pressing NEXT P / PREV P again steps to the next prime in sequence!
        baseController.text = result;
        _justCalculated = false;
      }
      _currentOp = op;
      _hasMod = false;
      exponentController.clear();
      modController.clear();
      _activePart = 0;
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
      if (_currentOp == MathOp.primitiveRoot ||
          _currentOp == MathOp.nextPrime ||
          _currentOp == MathOp.prevPrime) {
        _currentOp = MathOp.none;
        exponentController.clear();
      }
      if (baseController.text.isEmpty) {
        baseController.text = '0';
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
        } else if (_isSingleOperandOp) {
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
      _verifyNote = "";
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
    final bool isDark = AppTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
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
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary(context)),
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
                              : (isDark
                                  ? primaryColor.withValues(alpha: 0.14)
                                  : const Color(0xFFFFF7ED)),
                          side: BorderSide(
                            color: isSmallest
                                ? primaryColor
                                : primaryColor.withValues(alpha: 0.35),
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
        return _hasMod ? 'Modulo • a mod n' : 'Crypto Calculator';
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
            : 'Verify Primitive Root • isRoot(q, α)';
      case MathOp.nextPrime:
        return 'Next Prime • Smallest Prime > n';
      case MathOp.prevPrime:
        return 'Previous Prime • Largest Prime < n';
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

  void _onEqualsPressed() {
    _performCalculation(commitToHistory: true);
    if (_isError) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
    }
  }

  // Builds step-by-step tables for Modular Exponentiation, GCD, and Modular Inverse
  _StepsData? _buildStepsData() {
    if (_isError || result.isEmpty) return null;

    try {
      // 1. Modular Exponentiation: Square-and-Multiply Table
      if (_currentOp == MathOp.power && _hasMod) {
        if (baseController.text.isEmpty ||
            exponentController.text.isEmpty ||
            modController.text.isEmpty) {
          return null;
        }
        final BigInt a = BigInt.parse(baseController.text);
        final BigInt b = BigInt.parse(exponentController.text);
        final BigInt n = BigInt.parse(modController.text);
        if (b < BigInt.zero || n <= BigInt.zero) return null;
        final String bits = b.toRadixString(2);
        if (bits.length > 64) return null;

        final BigInt baseMod = ((a % n) + n) % n;
        BigInt acc = BigInt.one;
        final List<List<String>> rows = [];

        for (int i = 0; i < bits.length; i++) {
          final String bit = bits[i];
          final BigInt sq = (acc * acc) % n;
          String multStr = '—';
          if (bit == '1') {
            acc = (sq * baseMod) % n;
            multStr = '($sq × $baseMod) mod $n = $acc';
          } else {
            acc = sq;
          }
          rows.add([
            '${i + 1}',
            bit,
            '$sq',
            multStr,
            '$acc',
          ]);
        }

        return _StepsData(
          title: 'Square-and-Multiply Steps',
          intro: [
            'Expression: $a^$b mod $n',
            'Exponent in binary: $b = $bits₂ (${bits.length} bits, MSB → LSB)',
            'Start with result R = 1. For each bit: square R mod $n, and if bit = 1, multiply by ${a != baseMod ? "($a mod $n = $baseMod)" : "$baseMod"} mod $n.',
          ],
          headers: ['#', 'Bit', 'Square mod n', 'Multiply (if bit=1)', 'R'],
          rows: rows,
          conclusion: 'Final Answer: $a^$b mod $n = $acc',
        );
      }

      // 2. GCD: Euclidean Division Chain
      if (_currentOp == MathOp.gcd && !_hasMod) {
        if (baseController.text.isEmpty || exponentController.text.isEmpty) {
          return null;
        }
        BigInt a = BigInt.parse(baseController.text).abs();
        BigInt b = BigInt.parse(exponentController.text).abs();
        if (a == BigInt.zero && b == BigInt.zero) return null;

        final List<List<String>> rows = [];
        int step = 1;
        while (b > BigInt.zero && step <= 60) {
          final BigInt q = a ~/ b;
          final BigInt r = a % b;
          rows.add([
            '$step',
            '$a',
            '$b',
            '$q',
            '$r',
            '$a = $q × $b + $r',
          ]);
          a = b;
          b = r;
          step++;
        }

        return _StepsData(
          title: 'Euclidean Algorithm (GCD Steps)',
          intro: [
            'Repeatedly divide A by B:  A = Q × B + R, then shift (A ← B, B ← R) until R = 0.',
          ],
          headers: ['#', 'A', 'B', 'Q', 'R', 'Division Equation'],
          rows: rows,
          conclusion:
              'Last non-zero remainder = gcd = $a  (${a == BigInt.one ? "Coprime ✓" : "Not Coprime"})',
        );
      }

      // 3. Modular Inverse: Extended Euclidean Table + Shortcut to Extended Euclid Screen
      if (_currentOp == MathOp.modInverse) {
        if (baseController.text.isEmpty || modController.text.isEmpty) {
          return null;
        }
        final BigInt eOrig = BigInt.parse(baseController.text);
        final BigInt phi = BigInt.parse(modController.text);
        if (phi <= BigInt.one) return null;
        final BigInt e = ((eOrig % phi) + phi) % phi;

        BigInt a = phi;
        BigInt b = e;
        BigInt x = BigInt.zero;
        BigInt y = BigInt.one;
        final List<List<String>> rows = [];
        int step = 1;

        while (b > BigInt.zero && step <= 60) {
          final BigInt q = a ~/ b;
          final BigInt r = a % b;
          final BigInt z = x - (q * y);
          rows.add(['$step', '$q', '$a', '$b', '$r', '$x', '$y', '$z']);
          a = b;
          b = r;
          x = y;
          y = z;
          step++;
        }
        rows.add(['$step', '-', '$a', '0', '-', '$x', '-', '-']);

        final BigInt d = x < BigInt.zero ? x + phi : x;
        final String conclusion = x < BigInt.zero
            ? 'x = $x is negative → d = $x + $phi = $d  •  Verify: ($eOrig × $d) mod $phi = 1 ✓'
            : 'd = x = $d  •  Verify: ($eOrig × $d) mod $phi = 1 ✓';

        return _StepsData(
          title: 'Extended Euclidean Inverse Steps',
          intro: [
            'Solving: $eOrig⁻¹ mod $phi',
            'Update rule: z = x − Q × y, then shift B→A, R→B, y→x, z→y.',
          ],
          headers: ['#', 'Q', 'A', 'B', 'R', 'x', 'y', 'z'],
          rows: rows,
          conclusion: conclusion,
          inverseE: e.toString(),
          inverseN: phi.toString(),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _showStepsSheet() {
    final _StepsData? data = _buildStepsData();
    if (data == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.fact_check_rounded, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.title,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data.inverseE != null && data.inverseN != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InverseCalcScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: const Text(
                            'Extended Euclid',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.tealAccent(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in data.intro)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 34,
                          dataRowMaxHeight: 40,
                          columnSpacing: 18,
                          headingRowColor: WidgetStateProperty.all(
                            primaryColor.withValues(alpha: 0.14),
                          ),
                          columns: [
                            for (final h in data.headers)
                              DataColumn(
                                label: Text(
                                  h,
                                  style: TextStyle(
                                    fontFamily: 'Courier New',
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                          ],
                          rows: [
                            for (final r in data.rows)
                              DataRow(
                                cells: [
                                  for (final cell in r)
                                    DataCell(
                                      Text(
                                        cell,
                                        style: TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.successBorder(context)),
                    ),
                    child: Text(
                      data.conclusion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _reloadHistoryEntry(CalcHistoryEntry item) {
    HapticFeedback.selectionClick();
    setState(() {
      baseController.text = item.baseText;
      exponentController.text = item.exponentText;
      modController.text = item.modText;
      _currentOp = item.op;
      _hasMod = item.hasMod;
      if (_hasMod && modController.text.isNotEmpty) {
        _activePart = 2;
      } else if (_hasSecondOperand && exponentController.text.isNotEmpty) {
        _activePart = 1;
      } else {
        _activePart = 0;
      }
      _justCalculated = false;
      _isError = false;
    });
    _performCalculation(commitToHistory: false);
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.75,
                ),
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
                                setState(() {
                                  _history.removeWhere((e) => !e.pinned);
                                });
                                setModalState(() {});
                              },
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.errorText(context), size: 18),
                              label: Text(
                                'Clear Unpinned',
                                style: TextStyle(
                                  color: AppTheme.errorText(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any entry to reload the full expression into the calculator.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                      const Divider(height: 18),
                      if (_history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Press "=" on any calculation to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted(context)),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _history.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: item.pinned
                                      ? primaryColor.withValues(alpha: 0.08)
                                      : AppTheme.surfaceSubtle(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: item.pinned
                                        ? primaryColor.withValues(alpha: 0.45)
                                        : AppTheme.borderSubtle(context),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  title: Text(
                                    item.expression,
                                    style: TextStyle(
                                      fontFamily: 'Courier New',
                                      fontSize: 13.5,
                                      color: AppTheme.textSecondary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '= ${item.result}',
                                        style: TextStyle(
                                          fontFamily: 'Courier New',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      if (item.note != null)
                                        Text(
                                          item.note!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppTheme.textSecondary(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: item.pinned
                                            ? 'Unpin'
                                            : 'Pin to keep',
                                        icon: Icon(
                                          item.pinned
                                              ? Icons.push_pin_rounded
                                              : Icons.push_pin_outlined,
                                          color: item.pinned
                                              ? primaryColor
                                              : AppTheme.textMuted(context),
                                          size: 19,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            item.pinned = !item.pinned;
                                            _history.sort((a, b) {
                                              if (a.pinned == b.pinned) {
                                                return 0;
                                              }
                                              return a.pinned ? -1 : 1;
                                            });
                                          });
                                          setModalState(() {});
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Copy as homework text',
                                        icon: Icon(
                                          Icons.description_outlined,
                                          color: primaryColor,
                                          size: 19,
                                        ),
                                        onPressed: () {
                                          final String fullText = item.note !=
                                                  null
                                              ? '${item.expression} = ${item.result} (${item.note})'
                                              : '${item.expression} = ${item.result}';
                                          Clipboard.setData(
                                              ClipboardData(text: fullText));
                                          Navigator.pop(modalContext);
                                          ScaffoldMessenger.of(this.context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Copied: $fullText'),
                                              backgroundColor:
                                                  Colors.green.shade700,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    _reloadHistoryEntry(item);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Crypto Calculator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.orangeAppBar(context),
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
              textColor: AppTheme.orangeAppBar(context),
              child: const Icon(Icons.history_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. PREMIUM DISPLAY SCREEN CARD (with shake feedback on error)
            Expanded(
              flex: 40,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double dx =
                      math.sin(_shakeController.value * math.pi * 4) *
                          (1.0 - _shakeController.value) *
                          10.0;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: _buildDisplayCard(),
              ),
            ),

            // 2. PROFESSIONAL CRYPTOGRAPHIC & ARITHMETIC KEYPAD
            Expanded(
              flex: 60,
              child: _buildKeypadSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayCard() {
    final bool hasValidResult = result.isNotEmpty && !_isError;
    final bool isDark = AppTheme.isDark(context);
    final Color tealColor = AppTheme.tealAccent(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.32),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.14 : 0.08),
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
                    primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
                    primaryColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withValues(alpha: 0.15),
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
                          color: AppTheme.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'ANS = ${_history.first.result}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Courier New',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary(context),
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

            // Contextual Crypto Insight & Verify Strip
            if ((_helperNote.isNotEmpty || _verifyNote.isNotEmpty) && !_isError)
              GestureDetector(
                onTap: _lastPrimitiveRoots.isNotEmpty
                    ? _showAllPrimitiveRootsSheet
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  color: tealColor.withValues(alpha: isDark ? 0.14 : 0.1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_helperNote.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _lastPrimitiveRoots.isNotEmpty
                                  ? Icons.touch_app_rounded
                                  : Icons.verified_outlined,
                              size: 13,
                              color: tealColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _helperNote,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? tealColor : Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_verifyNote.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Verify: $_verifyNote',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successText(context),
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
                    ? AppTheme.errorBg(context)
                    : (hasValidResult
                        ? (isDark
                            ? primaryColor.withValues(alpha: 0.12)
                            : const Color(0xFFFFF7ED))
                        : AppTheme.surfaceSubtle(context)),
                border: Border(
                  top: BorderSide(
                    color: _isError
                        ? AppTheme.errorBorder(context)
                        : (hasValidResult
                            ? primaryColor.withValues(alpha: 0.28)
                            : AppTheme.borderSubtle(context)),
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
                          ? AppTheme.errorText(context).withValues(alpha: 0.16)
                          : primaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isError ? '!' : '=',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isError
                            ? AppTheme.errorText(context)
                            : primaryColor,
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
                              ? AppTheme.errorText(context)
                              : (result.isEmpty
                                  ? AppTheme.textMuted(context)
                                  : AppTheme.textPrimary(context)),
                        ),
                      ),
                    ),
                  ),
                  if (_buildStepsData() != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: AppTheme.tealAccent(context),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _showStepsSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_chart_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Steps',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final bool isDark = AppTheme.isDark(context);

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
                ? primaryColor.withValues(alpha: 0.15)
                : (isEmpty
                    ? AppTheme.surfaceSubtle(context)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? primaryColor
                  : (isEmpty
                      ? AppTheme.borderMedium(context)
                      : Colors.transparent),
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
                  ? (isActive ? primaryColor : AppTheme.textMuted(context))
                  : AppTheme.textPrimary(context),
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
      // 1st slot = Prime modulus q, 2nd optional slot = Candidate root α when verifying isRoot(q, α)
      final bool isVerifying = exponentController.text.isNotEmpty;

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
                ? 'q?'
                : 'q=${baseController.text}',
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
            fontSize: 24,
          ),
          if (isSecondActive || isVerifying || baseController.text.isNotEmpty) ...[
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
                  ? 'α?'
                  : 'α=${exponentController.text}',
              isEmpty: exponentController.text.isEmpty,
              isActive: isSecondActive,
              onTap: () => setState(() => _activePart = 1),
              fontSize: 24,
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
    } else if (_currentOp == MathOp.nextPrime ||
        _currentOp == MathOp.prevPrime) {
      final String fnLabel =
          _currentOp == MathOp.nextPrime ? 'nextPrime(' : 'prevPrime(';
      coreWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fnLabel,
            style: TextStyle(
              fontFamily: 'Courier New',
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          buildToken(
            text: baseController.text.isEmpty ? 'n?' : baseController.text,
            isEmpty: baseController.text.isEmpty,
            isActive: isBaseActive,
            onTap: () => setState(() => _activePart = 0),
            fontSize: 25,
          ),
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
                      ? primaryColor.withValues(alpha: 0.18)
                      : (isDark
                          ? primaryColor.withValues(alpha: 0.1)
                          : const Color(0xFFFFF7ED)),
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
                        ? primaryColor.withValues(alpha: 0.55)
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
                color: AppTheme.textMuted(context),
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
                color: AppTheme.textMuted(context),
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
                color: primaryColor.withValues(alpha: 0.14),
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

  Widget _buildModeSelectorStrip() {
    Widget chip(String title, CalcUiMode mode, IconData icon) {
      final bool selected = _uiMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _uiMode = mode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color:
                      selected ? Colors.white : AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle(context)),
      ),
      child: Row(
        children: [
          chip('Basic', CalcUiMode.basic, Icons.dialpad_rounded),
          chip('Modular', CalcUiMode.modular, Icons.lock_clock_rounded),
          chip('Number Theory', CalcUiMode.numberTheory, Icons.hub_rounded),
        ],
      ),
    );
  }

  List<Widget> _buildModeFunctionKeys() {
    switch (_uiMode) {
      case CalcUiMode.basic:
        return [
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
        ];
      case CalcUiMode.modular:
        return [
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
        ];
      case CalcUiMode.numberTheory:
        return [
          _buildCryptoFunctionKey(
            label: 'ROOT',
            subtitle: 'Prim. α',
            isSelected: _currentOp == MathOp.primitiveRoot,
            onTap: _onPrimitiveRootPressed,
          ),
          _buildCryptoFunctionKey(
            label: 'PREV P',
            subtitle: 'Prime < n',
            isSelected: _currentOp == MathOp.prevPrime,
            onTap: () => _onNearbyPrimePressed(MathOp.prevPrime),
          ),
          _buildCryptoFunctionKey(
            label: 'NEXT P',
            subtitle: 'Prime > n',
            isSelected: _currentOp == MathOp.nextPrime,
            onTap: () => _onNearbyPrimePressed(MathOp.nextPrime),
          ),
        ];
    }
  }

  Widget _buildKeypadSection() {
    final bool isDark = AppTheme.isDark(context);
    final Color actionBtnBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color actionBtnText =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Mode Strip: Basic | Modular | Number Theory
          _buildModeSelectorStrip(),
          const SizedBox(height: 8),

          // 2. Mode-Specific Cryptographic Function Bar
          SizedBox(
            height: 48,
            child: Row(
              children: _buildModeFunctionKeys(),
            ),
          ),
          const SizedBox(height: 8),

          // Main 4x5 Calculator Keypad
          // Row 1: AC, ⌫, ANS, ÷
          Expanded(
            child: Row(
              children: [
                _buildKeyButton(
                  label: 'AC',
                  subtitle: 'Clear',
                  bgColor: AppTheme.errorBg(context),
                  borderColor: AppTheme.errorBorder(context),
                  textColor: AppTheme.errorText(context),
                  onTap: _resetFields,
                ),
                _buildKeyButton(
                  label: '⌫',
                  subtitle: 'Delete',
                  bgColor: actionBtnBg,
                  textColor: actionBtnText,
                  onTap: _onBackspace,
                ),
                _buildKeyButton(
                  label: 'ANS',
                  subtitle: 'Last',
                  bgColor: actionBtnBg,
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
                  bgColor: actionBtnBg,
                  textColor: actionBtnText,
                  onTap: _onToggleSign,
                ),
                _buildDigitButton('0'),
                _buildKeyButton(
                  label: 'PASTE',
                  icon: Icons.content_paste_rounded,
                  bgColor: actionBtnBg,
                  textColor: actionBtnText,
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
    final bool isDark = AppTheme.isDark(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.5),
        child: Material(
          color: isSelected
              ? primaryColor
              : (isDark
                  ? primaryColor.withValues(alpha: 0.12)
                  : const Color(0xFFFFF7ED)),
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
                      : primaryColor.withValues(alpha: 0.35),
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
                          : primaryColor.withValues(alpha: 0.8),
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
    final bool isDark = AppTheme.isDark(context);
    return _buildKeyButton(
      label: symbol,
      bgColor: isSelected
          ? primaryColor
          : (isDark
              ? primaryColor.withValues(alpha: 0.12)
              : const Color(0xFFFFF7ED)),
      borderColor:
          isSelected ? primaryColor : primaryColor.withValues(alpha: 0.3),
      textColor: isSelected ? Colors.white : primaryColor,
      isLarge: true,
      onTap: () => _onBinaryOpPressed(op),
    );
  }

  Widget _buildDigitButton(String digit) {
    return _buildKeyButton(
      label: digit,
      bgColor: AppTheme.surfaceSubtle(context),
      borderColor: AppTheme.borderSubtle(context),
      textColor: AppTheme.textPrimary(context),
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
              colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
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
              onTap: _onEqualsPressed,
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
                  color: borderColor ?? AppTheme.borderSubtle(context),
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
                          color: textColor.withValues(alpha: 0.75),
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
