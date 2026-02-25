import 'package:flutter/material.dart';

enum CalcMode { modPow, powerOnly, modOnly }

class ModCalculatorScreen extends StatefulWidget {
  const ModCalculatorScreen({super.key});

  @override
  State<ModCalculatorScreen> createState() => _ModCalculatorScreenState();
}

class _ModCalculatorScreenState extends State<ModCalculatorScreen> {
  final TextEditingController baseController = TextEditingController();
  final TextEditingController exponentController = TextEditingController();
  final TextEditingController modController = TextEditingController();

  CalcMode _selectedMode = CalcMode.modPow;
  String result = '';

  final Color primaryColor = Colors.orange.shade800;

  void _performCalculation() {
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
        isInputValid = baseController.text.isNotEmpty && modController.text.isNotEmpty;
        break;
    }

    if (!isInputValid) {
      setState(() { result = "Please fill in the required fields"; });
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
          break;
        case CalcMode.powerOnly:
          int exponent = int.parse(exponentController.text);
          finalResult = base.pow(exponent);
          break;
        case CalcMode.modOnly:
          BigInt mod = BigInt.parse(modController.text);
          finalResult = base % mod;
          break;
      }

      setState(() { result = finalResult.toString(); });
    } catch (e) {
      setState(() { result = "Invalid input!"; });
    }
  }

  void _resetFields() {
    FocusScope.of(context).unfocus() ;

    setState(() {
      baseController.clear();
      exponentController.clear();
      modController.clear();
      result = "";
    });
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
            Icon(Icons.speed_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Modular Exponentiation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _resetFields, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomTextField(baseController, 'Base Number (a)', Icons.numbers, true),
                const SizedBox(height: 16.0),
                _buildCustomTextField(
                    exponentController,
                    'Exponent (b)',
                    Icons.superscript,
                    _selectedMode != CalcMode.modOnly
                ),
                const SizedBox(height: 16),
                _buildCustomTextField(
                    modController,
                    'Modulus (n)',
                    Icons.percent,
                    _selectedMode != CalcMode.powerOnly
                ),
                const SizedBox(height: 24),
        
                Text(
                  'Select Operation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                ),
        
                _buildRadioOption('Full: a^b mod n', CalcMode.modPow),
                _buildRadioOption('Power Only: a^b', CalcMode.powerOnly),
                _buildRadioOption('Modulo Only: a mod n', CalcMode.modOnly),
        
                const SizedBox(height: 32),
        
                ElevatedButton(
                  onPressed: _performCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
        
                _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField(TextEditingController controller, String label, IconData icon, bool enabled) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? primaryColor : Colors.grey),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildRadioOption(String title, CalcMode value) {
    return RadioListTile<CalcMode>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _selectedMode,
      onChanged: (val) => setState(() => _selectedMode = val!),
      activeColor: primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2.0),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text("Result", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          SelectableText(
            result.isEmpty ? '---' : result,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Courier New'),
          ),
        ],
      ),
    );
  }
}