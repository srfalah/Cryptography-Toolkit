import 'package:flutter/material.dart';
import 'dart:math';

class DiffieHellmanScreen extends StatefulWidget {
  const DiffieHellmanScreen({super.key});

  @override
  State<DiffieHellmanScreen> createState() => _DiffieHellmanScreenState();
}

class _DiffieHellmanScreenState extends State<DiffieHellmanScreen> {
  final Color primaryColor = const Color(0xFF1E3A8A);
  final Color aliceColor = Colors.pink.shade700;
  final Color bobColor = Colors.blue.shade800;
  final Color successColor = Colors.green.shade700;

  final TextEditingController qController = TextEditingController();
  final TextEditingController alphaController = TextEditingController();
  final TextEditingController privateAController = TextEditingController();
  final TextEditingController privateBController = TextEditingController();

  BigInt? publicA, publicB, sharedA, sharedB;
  String? errorMessage;

  bool _isPrimitiveRoot(BigInt alpha, BigInt q) {
    if (q <= BigInt.one) return false;
    if (alpha >= q || alpha < BigInt.two) return false;

    Set<BigInt> s = {};
    for (BigInt i = BigInt.one; i < q; i += BigInt.one) {
      s.add(alpha.modPow(i, q));
    }
    return s.length == (q - BigInt.one).toInt();
  }

  void _calculate() {
    setState(() {
      errorMessage = null;
      try {
        if (qController.text.isEmpty || alphaController.text.isEmpty) return;
        BigInt q = BigInt.parse(qController.text);
        BigInt alpha = BigInt.parse(alphaController.text);

        if (!_isPrimitiveRoot(alpha, q)) {
          errorMessage = "Note: α must be a primitive root of q to ensure the correctness of the exchange.";
          _resetResults();
          return;
        }

        if (privateAController.text.isNotEmpty && privateBController.text.isNotEmpty) {
          BigInt xA = BigInt.parse(privateAController.text);
          BigInt xB = BigInt.parse(privateBController.text);

          publicA = alpha.modPow(xA, q);
          publicB = alpha.modPow(xB, q);
          sharedA = publicB!.modPow(xA, q);
          sharedB = publicA!.modPow(xB, q);
        } else {
          _resetResults();
        }
      } catch (e) {
        _resetResults();
      }
    });
  }

  void _resetResults() {
    publicA = null; publicB = null; sharedA = null; sharedB = null;
  }

  void _generateGlobalParams() {
    final List<Map<String, int>> commonPairs = [
      {'q': 23, 'a': 5}, {'q': 97, 'a': 5}, {'q': 71, 'a': 7}, {'q': 353, 'a': 3},
    ];
    final pair = commonPairs[Random().nextInt(commonPairs.length)];
    setState(() {
      qController.text = pair['q'].toString();
      alphaController.text = pair['a'].toString();
      _calculate();
    });
  }

  void _generateKey(TextEditingController ctrl) {
    setState(() {
      ctrl.text = (Random().nextInt(90) + 10).toString();
      _calculate();
    });
  }


  void _clearAll() {
    FocusScope.of(context).unfocus() ;

    setState(() {
      qController.clear();
      alphaController.clear();
      privateAController.clear();
      privateBController.clear();
      _resetResults();
      errorMessage = null;
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
            Icon(Icons.swap_horizontal_circle_rounded, size: 22),
            SizedBox(width: 8),
            Text(
              'D-H Key Exchange',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(onPressed: _clearAll, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGlobalCard(),
              if (errorMessage != null) _buildErrorLabel(),
              const SizedBox(height: 35),
        
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildUserNode("Alice", aliceColor, privateAController, publicA, sharedA, "A")),
                      const SizedBox(width: 70),
                      Expanded(child: _buildUserNode("Bob", bobColor, privateBController, publicB, sharedB, "B")),
                    ],
                  ),
                  Positioned(top: 220, child: _buildExchangeIcon()),
                ],
              ),
              const SizedBox(height: 30),
              if (sharedA != null && sharedA == sharedB) _buildSuccessBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Global Parameters", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              IconButton(onPressed: _generateGlobalParams, icon: const Icon(Icons.auto_awesome, color: Colors.teal, size: 20)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildInput(qController, "Prime (q)")),
              const SizedBox(width: 15),
              Expanded(child: _buildInput(alphaController, "Root (α)")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserNode(String name, Color color, TextEditingController ctrl, BigInt? pub, BigInt? shared, String keySuffix) {
    String pubFormula = "Y$keySuffix = αˣ$keySuffix mod q";
    String sharedFormula = keySuffix == "A" ? "K = Yᵦˣᵃ mod q" : "K = Yₐˣᵇ mod q";

    return Column(
      children: [
        CircleAvatar(radius: 28, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        _buildInput(ctrl, "Private Key ($keySuffix)", color: color),
        TextButton.icon(
          onPressed: () => _generateKey(ctrl),
          icon: const Icon(Icons.auto_awesome, size: 14),
          label: const Text("Generate", style: TextStyle(fontSize: 10)),
          style: TextButton.styleFrom(foregroundColor: color, padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 25),
        _buildResultBox("Public Key", pubFormula, pub?.toString() ?? "?", color),
        const SizedBox(height: 30),
        _buildResultBox("Shared Secret", sharedFormula, shared?.toString() ?? "?", successColor, isBold: true),
      ],
    );
  }

  Widget _buildExchangeIcon() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
          child: Icon(Icons.swap_horizontal_circle, color: primaryColor, size: 38),
        ),
        const SizedBox(height: 4),
        const Text("EXCHANGE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildResultBox(String label, String formula, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(formula, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: value == "?" ? Colors.grey.shade200 : color, width: 2)),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, {Color? color}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => _calculate(),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: color?.withOpacity(0.8)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color ?? primaryColor, width: 2)),
      ),
    );
  }

  Widget _buildErrorLabel() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text("Keys Matched: K = $sharedA", style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
