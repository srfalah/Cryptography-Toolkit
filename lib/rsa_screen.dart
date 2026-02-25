import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class RsaScreen extends StatefulWidget {
  const RsaScreen({super.key});

  @override
  State<RsaScreen> createState() => _RsaScreenState();
}

class _RsaScreenState extends State<RsaScreen> {
  final Color primaryColor = const Color(0xFF1E3A8A);
  final Color accentColor = Colors.orange.shade800;

  final TextEditingController pController = TextEditingController();
  final TextEditingController qController = TextEditingController();
  final TextEditingController nController = TextEditingController();
  final TextEditingController phiController = TextEditingController();
  final TextEditingController eController = TextEditingController();
  final TextEditingController dController = TextEditingController();

  final TextEditingController messageController = TextEditingController();
  final TextEditingController encryptedController = TextEditingController();
  final TextEditingController decryptedController = TextEditingController();

  bool isEncryptionReady = false;


  bool _isPrime(BigInt number) {
    if (number <= BigInt.one) return false;
    if (number == BigInt.two || number == BigInt.from(3)) return true;
    if (number % BigInt.two == BigInt.zero || number % BigInt.from(3) == BigInt.zero) return false;
    BigInt i = BigInt.from(5);
    while (i * i <= number) {
      if (number % i == BigInt.zero || number % (i + BigInt.two) == BigInt.zero) return false;
      i += BigInt.from(6);
    }
    return true;
  }

  void _generatePrimes() {
    final random = Random.secure();
    BigInt generateRandomPrime() {
      BigInt candidate;
      do { candidate = BigInt.from(random.nextInt(900) + 10); } while (!_isPrime(candidate));
      return candidate;
    }
    setState(() {
      pController.text = generateRandomPrime().toString();
      qController.text = generateRandomPrime().toString();
      _onPrimeFieldsChanged();
    });
  }

  void _onPrimeFieldsChanged() {
    if (pController.text.isEmpty || qController.text.isEmpty) return;
    try {
      BigInt p = BigInt.parse(pController.text);
      BigInt q = BigInt.parse(qController.text);
      if (_isPrime(p) && _isPrime(q)) {
        nController.text = (p * q).toString();
        phiController.text = ((p - BigInt.one) * (q - BigInt.one)).toString();
        _onEFieldChanged();
      }
    } catch (e) {}
  }

  void _suggestE() {
    if (phiController.text.isEmpty) {
      _showError('يجب توليد قيم p و q أولاً');
      return;
    }
    try {
      BigInt phi = BigInt.parse(phiController.text);
      List<BigInt> candidates = [BigInt.from(3), BigInt.from(17), BigInt.from(65537)];

      for (BigInt e in candidates) {
        if (e < phi && e.gcd(phi) == BigInt.one) {
          setState(() {
            eController.text = e.toString();
            _onEFieldChanged();
          });
          return;
        }
      }


      BigInt start = BigInt.from(3);
      while (start < phi) {
        if (start.gcd(phi) == BigInt.one) {
          setState(() {
            eController.text = start.toString();
            _onEFieldChanged();
          });
          break;
        }
        start += BigInt.two;
      }
    } catch (e) {}
  }

  void _onEFieldChanged() {
    if (eController.text.isEmpty || phiController.text.isEmpty) {
      setState(() => isEncryptionReady = false);
      return;
    }
    try {
      BigInt e = BigInt.parse(eController.text);
      BigInt phi = BigInt.parse(phiController.text);
      if (e > BigInt.one && e < phi && e.gcd(phi) == BigInt.one) {
        dController.text = e.modInverse(phi).toString();
        setState(() => isEncryptionReady = true);
      } else {
        dController.clear();
        setState(() => isEncryptionReady = false);
      }
    } catch (err) { setState(() => isEncryptionReady = false); }
  }

  void _encryptMessage() {
    try {
      BigInt m = BigInt.parse(messageController.text);
      BigInt n = BigInt.parse(nController.text);
      BigInt e = BigInt.parse(eController.text);
      if (m >= n) { _showError('Message m must be less than n'); return; }
      setState(() => encryptedController.text = m.modPow(e, n).toString());
    } catch (e) { _showError('Input error'); }
  }

  void _decryptMessage() {
    try {
      BigInt c = BigInt.parse(encryptedController.text);
      BigInt n = BigInt.parse(nController.text);
      BigInt d = BigInt.parse(dController.text);
      setState(() => decryptedController.text = c.modPow(d, n).toString());
    } catch (e) { _showError('Decryption failed'); }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _clearAll() {
    FocusScope.of(context).unfocus() ;

    setState(() {
      pController.clear();
      qController.clear();
      nController.clear();
      phiController.clear();
      eController.clear();
      dController.clear();
      messageController.clear();
      encryptedController.clear();
      decryptedController.clear();
      isEncryptionReady = false;
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
            Icon(Icons.key_outlined, size: 30),
            SizedBox(width: 8),
            Text(
              'RSA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
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
                icon: Icons.settings_suggest,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput(pController, "Prime (p)", onChanged: (_)=> _onPrimeFieldsChanged())),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput(qController, "Prime (q)", onChanged: (_)=> _onPrimeFieldsChanged())),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generatePrimes,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Generate Random Primes"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                      ),
                    ),
                    const Divider(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildInput(nController, "Modulus (n)", readOnly: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput(phiController, "Totient φ(n)", readOnly: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
        
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                              eController,
                              "Public Exponent (e)",
                              icon: Icons.public,
                              onChanged: (_)=> _onEFieldChanged()
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _suggestE,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInput(dController, "Private Exponent (d)", icon: Icons.lock_person, readOnly: true, color: accentColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),
        
              if (isEncryptionReady) ...[
                _buildStepCard(
                  title: "2. Encryption",
                  icon: Icons.lock,
                  child: Column(
                    children: [
                      _buildInput(messageController, "Message (m)", icon: Icons.tag),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _encryptMessage,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size(double.infinity, 50)),
                        child: const Text("ENCRYPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      _buildInput(encryptedController, "Ciphertext (c)", readOnly: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildStepCard(
                  title: "3. Decryption",
                  icon: Icons.lock_open,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _decryptMessage,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, minimumSize: const Size(double.infinity, 50)),
                        child: const Text("DECRYPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      _buildInput(decryptedController, "Recovered (m)", readOnly: true, color: Colors.green.shade700),
                    ],
                  ),
                ),
              ] else
                _buildWarningCard(),
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

  Widget _buildInput(TextEditingController ctrl, String label, {bool readOnly = false, IconData? icon, Color? color, Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: TextStyle(color: color, fontWeight: readOnly ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: primaryColor) : null,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
      child: Row(children: [Icon(Icons.info_outline, color: Colors.amber.shade900), const SizedBox(width: 12), const Expanded(child: Text("Complete the key generation to enable encryption.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))]),
    );
  }
}
