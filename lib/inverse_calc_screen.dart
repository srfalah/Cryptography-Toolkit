import 'package:flutter/material.dart';
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
  String finalResult = "";

  Color _accent(BuildContext context) => AppTheme.tealAccent(context);

  void _calculateInverse() {
    tableRows.clear();
    setState(() {
      finalResult = "";
    });

    try {
      BigInt e = BigInt.parse(eController.text);
      BigInt phi = BigInt.parse(phiController.text);

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

      if (a == BigInt.one) {
        BigInt d = x < BigInt.zero ? x + phi : x;
        finalResult = "Multiplicative Inverse (d) = $d";
      } else {
        finalResult = "No inverse exists (GCD != 1)";
      }
      setState(() {});
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numerical values")),
      );
    }
  }

  void _resetFields() {
    FocusScope.of(context).unfocus();

    setState(() {
      eController.clear();
      phiController.clear();
      tableRows.clear();
      finalResult = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _accent(context);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            Icon(Icons.view_comfortable, size: 22),
            SizedBox(width: 8),
            Text(
              'Extended Euclidean Algorithm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.tealAppBar(context),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _resetFields, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
              _buildTextField(context, eController, 'Enter Value (e)', primaryColor),
              const SizedBox(height: 16),
              _buildTextField(context, phiController, 'Enter Modulus (phi)', primaryColor),
              const SizedBox(height: 20),
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
              const SizedBox(height: 32),
              if (tableRows.isNotEmpty) ...[
                Text(
                  "Calculation Steps",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildModernTable(context, primaryColor),
                const SizedBox(height: 24),
                _buildResultCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    Color primaryColor,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildModernTable(BuildContext context, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderMedium(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Table(
              children: const [
                TableRow(
                  children: [
                    Center(
                      child: Text(
                        'Q',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '𝑥',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '𝑦',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '𝑧',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tableRows.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppTheme.borderSubtle(context),
            ),
            itemBuilder: (context, index) {
              final row = tableRows[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Table(
                  children: [
                    TableRow(
                      children: [
                        _buildCell(context, row['q'].toString(), primaryColor),
                        _buildCell(context, row['a'].toString(), primaryColor),
                        _buildCell(context, row['b'].toString(), primaryColor),
                        _buildCell(context, row['r'].toString(), primaryColor),
                        _buildCell(
                          context,
                          row['x'].toString(),
                          primaryColor,
                          isBold: true,
                        ),
                        _buildCell(context, row['y'].toString(), primaryColor),
                        _buildCell(context, row['z'].toString(), primaryColor),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    String text,
    Color primaryColor, {
    bool isBold = false,
  }) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Courier New',
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? primaryColor : AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    bool isSuccess = finalResult.startsWith("Multiplicative");
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Text(
        finalResult,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isSuccess
              ? AppTheme.successText(context)
              : AppTheme.errorText(context),
        ),
      ),
    );
  }
}
