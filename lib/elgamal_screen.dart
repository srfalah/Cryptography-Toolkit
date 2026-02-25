import 'package:flutter/material.dart';
import 'dart:math';

class ElGamalScreen extends StatefulWidget {
  const ElGamalScreen({super.key});

  @override
  State<ElGamalScreen> createState() => _ElGamalScreenState();
}

class _ElGamalScreenState extends State<ElGamalScreen> {
  final Color primaryColor = const Color(0xFF1E3A8A);
  final Color accentColor = Colors.orange.shade800;

  final TextEditingController qController = TextEditingController();
  final TextEditingController alphaController = TextEditingController();
  final TextEditingController xaController = TextEditingController();
  final TextEditingController yaController = TextEditingController();

  final TextEditingController messageController = TextEditingController();
  final TextEditingController kRandomController = TextEditingController();
  final TextEditingController c1Controller = TextEditingController();
  final TextEditingController c2Controller = TextEditingController();
  final TextEditingController kEncryptController = TextEditingController();

  final TextEditingController kDecryptController = TextEditingController();
  final TextEditingController kInverseController = TextEditingController();
  final TextEditingController decryptedController = TextEditingController();

  bool isKeyReady = false;
  bool isEncrypted = false;

  bool _isPrimitiveRoot(BigInt alpha, BigInt q) {
    if (q <= BigInt.one) return false;
    if (alpha >= q || alpha < BigInt.two) return false;

    Set<BigInt> s = {};
    for (BigInt i = BigInt.one; i < q; i += BigInt.one) {
      s.add(alpha.modPow(i, q));
    }
    return s.length == (q - BigInt.one).toInt();
  }

  void _generateGlobalParams() {
    final List<Map<String, int>> commonPairs = [
      {'q': 467, 'a': 2}, {'q': 257, 'a': 3}, {'q': 107, 'a': 2}, {'q': 89, 'a': 3},
    ];
    final pair = commonPairs[Random().nextInt(commonPairs.length)];
    setState(() {
      qController.text = pair['q'].toString();
      alphaController.text = pair['a'].toString();
      xaController.text = (Random().nextInt(pair['q']! - 2) + 1).toString();
      _calculatePublicKey();
    });
  }

  void _calculatePublicKey() {
    if (qController.text.isEmpty || alphaController.text.isEmpty || xaController.text.isEmpty) {
      setState(() => isKeyReady = false);
      return;
    }
    try {
      BigInt q = BigInt.parse(qController.text);
      BigInt alpha = BigInt.parse(alphaController.text);
      BigInt xa = BigInt.parse(xaController.text);

      if (!_isPrimitiveRoot(alpha, q)) {
        _showError("Note: α must be a primitive root of q.");
        return;
      }

      if (xa <= BigInt.one || xa >= q - BigInt.one) {
        _showError("Private Key X_A must be between 1 and q-1");
        return;
      }

      BigInt ya = alpha.modPow(xa, q);
      setState(() {
        yaController.text = ya.toString();
        isKeyReady = true;
      });
    } catch (e) {
      setState(() => isKeyReady = false);
    }
  }

  void _generateRandomK() {
    if (qController.text.isEmpty) return;
    try {
      BigInt q = BigInt.parse(qController.text);
      BigInt k = BigInt.from(Random().nextInt(q.toInt() - 2) + 1);
      setState(() {
        kRandomController.text = k.toString();
      });
    } catch (e) {}
  }

  void _encryptMessage() {
    if (messageController.text.isEmpty || kRandomController.text.isEmpty) return;
    try {
      BigInt m = BigInt.parse(messageController.text);
      BigInt q = BigInt.parse(qController.text);
      BigInt alpha = BigInt.parse(alphaController.text);
      BigInt ya = BigInt.parse(yaController.text);
      BigInt k = BigInt.parse(kRandomController.text);

      if (m >= q) {
        _showError("Message (m) must be less than Prime (q)");
        return;
      }

      BigInt c1 = alpha.modPow(k, q);
      BigInt K = ya.modPow(k, q);
      BigInt c2 = (K * m) % q;

      setState(() {
        kEncryptController.text = K.toString();
        c1Controller.text = c1.toString();
        c2Controller.text = c2.toString();
        isEncrypted = true;
      });
    } catch (e) {
      _showError("Encryption Error. Check inputs.");
    }
  }

  void _decryptMessage() {
    try {
      BigInt c1 = BigInt.parse(c1Controller.text);
      BigInt c2 = BigInt.parse(c2Controller.text);
      BigInt q = BigInt.parse(qController.text);
      BigInt xa = BigInt.parse(xaController.text);

      BigInt K = c1.modPow(xa, q);
      BigInt kInv = K.modInverse(q);
      BigInt m = (c2 * kInv) % q;

      setState(() {
        kDecryptController.text = K.toString();
        kInverseController.text = kInv.toString();
        decryptedController.text = m.toString();
      });
    } catch (e) {
      _showError("Decryption Error.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800));
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
      c1Controller.clear();
      c2Controller.clear();
      kEncryptController.clear();
      kDecryptController.clear();
      kInverseController.clear();
      decryptedController.clear();
      isKeyReady = false;
      isEncrypted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, size: 28),
            SizedBox(width: 8),
            Text(
              'El-Gamal Cipher',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _clearAll, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStepCard(
                title: "1. Key Generation",
                icon: Icons.vpn_key,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput(qController, "Prime (q)", onChanged: (_) => _calculatePublicKey())),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput(alphaController, "Root (α)", onChanged: (_) => _calculatePublicKey())),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInput(xaController, "Private (X_A)", icon: Icons.lock_person, onChanged: (_) => _calculatePublicKey(), color: accentColor)),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _generateGlobalParams,
                            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            label: const Text("Auto", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    _buildFormulaBadge("Public Key", "Y_A = α^(X_A) mod q", Icons.public),
                    _buildInput(yaController, "Public Key (Y_A)", readOnly: true, icon: Icons.public),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (isKeyReady) ...[
                _buildStepCard(
                  title: "2. Encryption (Bob)",
                  icon: Icons.lock,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInput(messageController, "Message (M)", icon: Icons.message)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInput(
                                kRandomController, "Random (k)",
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.auto_awesome, color: primaryColor, size: 18),
                                  onPressed: _generateRandomK,
                                )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _encryptMessage,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50)),
                        child: const Text("ENCRYPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      if (isEncrypted) ...[
                        const Divider(height: 30),
                        _buildFormulaBadge("Shared Key", "K = (Y_A)^k mod q", Icons.vpn_key),
                        _buildInput(kEncryptController, "Shared Key (K)", readOnly: true),
                        const SizedBox(height: 20),
                        _buildFormulaBadge("First Cipher", "C1 = α^k mod q", Icons.lock_outline),
                        _buildInput(c1Controller, "Cipher 1 (C1)", readOnly: true),
                        const SizedBox(height: 20),
                        _buildFormulaBadge("Second Cipher", "C2 = (K × M) mod q", Icons.lock_outline),
                        _buildInput(c2Controller, "Cipher 2 (C2)", readOnly: true),
                        const SizedBox(height: 20),
                        _buildCiphertextTuple(),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                _buildWarningCard(),

              if (isEncrypted) ...[
                _buildStepCard(
                  title: "3. Decryption (Alice)",
                  icon: Icons.lock_open,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _decryptMessage,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, minimumSize: const Size(double.infinity, 50)),
                        child: const Text("DECRYPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      _buildFormulaBadge("Recover Key", "K = (C1)^(X_A) mod q", Icons.key),
                      _buildInput(kDecryptController, "Recovered (K)", readOnly: true),
                      const SizedBox(height: 20),
                      _buildFormulaBadge("Key Inverse", "K^-1 mod q", Icons.calculate_outlined),
                      _buildInput(kInverseController, "Inverse (K^-1)", readOnly: true),
                      const SizedBox(height: 20),
                      _buildSuccessDecryptionBanner(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: primaryColor), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))]),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, {bool readOnly = false, IconData? icon, Widget? suffixIcon, Color? color, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: TextStyle(color: color, fontWeight: readOnly ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: color ?? primaryColor) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
      ),
    );
  }

  Widget _buildFormulaBadge(String title, String formula, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey.shade700),
            const SizedBox(width: 8),
            Text("$title:  ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
            Text(formula, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Courier New')),
          ],
        ),
      ),
    );
  }

  Widget _buildCiphertextTuple() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text("Final Ciphertext (C1, C2)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "(${c1Controller.text.isEmpty ? '?' : c1Controller.text}, ${c2Controller.text.isEmpty ? '?' : c2Controller.text})",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Courier New'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
      child: Row(children: [
        Icon(Icons.info_outline, color: Colors.amber.shade900),
        const SizedBox(width: 12),
        const Expanded(child: Text("Please complete the Key Generation step to enable the Encryption process.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)))
      ]),
    );
  }

  Widget _buildSuccessDecryptionBanner() {
    bool hasResult = decryptedController.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasResult ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasResult ? Colors.green.shade400 : Colors.grey.shade300, width: 2),
      ),
      child: Column(
        children: [
          _buildFormulaBadge("Original Msg", "M = (C2 × K^-1) mod q", Icons.message_outlined),
          if (hasResult) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text("Decryption Successful", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _buildInput(decryptedController, "Original Message (M)", readOnly: true, color: hasResult ? Colors.green.shade800 : Colors.black87),
        ],
      ),
    );
  }
}