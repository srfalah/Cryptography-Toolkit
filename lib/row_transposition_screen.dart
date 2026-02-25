import 'package:flutter/material.dart';

enum RowTransMode { encrypt, decrypt }

class RowTranspositionScreen extends StatefulWidget {
  const RowTranspositionScreen({super.key});

  @override
  State<RowTranspositionScreen> createState() => _RowTranspositionScreenState();
}

class _RowTranspositionScreenState extends State<RowTranspositionScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController keyController = TextEditingController();

  RowTransMode _selectedMode = RowTransMode.encrypt;
  String result = '';
  String? errorMessage;

  final Color primaryColor = Colors.blueGrey.shade800;
  final Color highlightColor = Colors.blueGrey.shade100;

  List<List<String>> displayGrid = [];

  void _processCipher() {
    String text = messageController.text.replaceAll(' ', '').toUpperCase();
    String key = keyController.text;

    if (text.isEmpty || key.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
        errorMessage = null;
      });
      return;
    }

    if (!_isValidKey(key)) {
      setState(() {
        result = '';
        displayGrid = [];
        errorMessage = "Invalid Key: Must be a sequence from 1 to ${key.length} without duplicates.";
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    if (_selectedMode == RowTransMode.encrypt) {
      result = _encryptRowTransposition(text, key);
    } else {
      result = _decryptRowTransposition(text, key);
    }
  }

  bool _isValidKey(String key) {
    if (key.isEmpty) return false;
    List<String> chars = key.split('');
    for (int i = 1; i <= key.length; i++) {
      if (!chars.contains(i.toString())) return false;
    }
    return true;
  }

  String _encryptRowTransposition(String text, String key) {
    while (text.length % key.length != 0) {
      text += 'X';
    }

    int cols = key.length;
    int rows = text.length ~/ cols;

    List<List<String>> grid = List.generate(rows, (_) => List.filled(cols, ''));
    int textIndex = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c] = text[textIndex++];
      }
    }

    List<List<String>> disp = [];
    disp.add(key.split(''));
    disp.addAll(grid);
    setState(() => displayGrid = disp);

    String res = "";
    for (int i = 1; i <= cols; i++) {
      int colIndex = key.indexOf(i.toString());
      if (colIndex != -1) {
        for (int r = 0; r < rows; r++) {
          res += grid[r][colIndex];
        }
      }
    }
    return res;
  }

  String _decryptRowTransposition(String cipher, String key) {
    while (cipher.length % key.length != 0) {
      cipher += 'X';
    }

    int cols = key.length;
    int rows = cipher.length ~/ cols;

    List<List<String>> grid = List.generate(rows, (_) => List.filled(cols, ''));

    int cipherIndex = 0;
    for (int i = 1; i <= cols; i++) {
      int colIndex = key.indexOf(i.toString());
      if (colIndex != -1) {
        for (int r = 0; r < rows; r++) {
          grid[r][colIndex] = cipher[cipherIndex++];
        }
      }
    }

    List<List<String>> disp = [];
    disp.add(key.split(''));
    disp.addAll(grid);
    setState(() => displayGrid = disp);

    String res = "";
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        res += grid[r][c];
      }
    }
    return res;
  }

  void _clearAll() {
    FocusScope.of(context).unfocus() ;

    setState(() {
      messageController.clear();
      keyController.clear();
      _selectedMode = RowTransMode.encrypt;
      result = '';
      displayGrid = [];
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.table_chart_rounded),
            SizedBox(width: 10),
            Text('Row Transposition', style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Input Message"),
              TextField(
                controller: messageController,
                maxLines: 3,
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: "Enter text here...",
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.message, color: primaryColor),
                ),
              ),
              const SizedBox(height: 15),

              _buildSectionTitle("Numeric Key"),
              TextField(
                controller: keyController,
                keyboardType: TextInputType.number,
                onChanged: (value) => _processCipher(),
                decoration: InputDecoration(
                  hintText: "E.g., 4312",
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.password, color: primaryColor),
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 5),
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 20),

              _buildSectionTitle("Select Mode"),
              Row(
                children: [
                  _buildModeRadioTile("Encrypt", RowTransMode.encrypt),
                  _buildModeRadioTile("Decrypt", RowTransMode.decrypt),
                ],
              ),
              const SizedBox(height: 20),

              if (displayGrid.isNotEmpty) _buildVisualizationGrid(),
              const SizedBox(height: 20),

              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildVisualizationGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Visual Grid (Key + Matrix)"),
        LayoutBuilder(
            builder: (context, constraints) {
              int colsCount = displayGrid[0].length + 1;
              double calculatedWidth = ((constraints.maxWidth - 20) / colsCount) - 4;
              double cellWidth = calculatedWidth < 35 ? 35 : calculatedWidth;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: highlightColor.withOpacity(0.3),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: displayGrid.asMap().entries.map((entry) {
                      int rowIndex = entry.key;
                      List<String> row = entry.value;
                      bool isHeader = rowIndex == 0;

                      return Row(
                        children: [
                          Container(
                            width: cellWidth,
                            height: 40,
                            margin: const EdgeInsets.all(2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isHeader ? Colors.blueGrey.shade900 : Colors.blueGrey.shade200,
                              border: Border.all(color: Colors.blueGrey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isHeader ? '#' : rowIndex.toString(),
                              style: TextStyle(
                                color: isHeader ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: isHeader ? 18 : 14,
                              ),
                            ),
                          ),

                          ...row.map((char) {
                            return Container(
                              width: cellWidth,
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isHeader ? Colors.blueGrey.shade900 : Colors.blueGrey.shade600,
                                border: Border.all(
                                  color: isHeader ? Colors.black : Colors.blueGrey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                char,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isHeader ? FontWeight.w900 : FontWeight.bold,
                                  fontSize: isHeader ? 18 : 16,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildModeRadioTile(String title, RowTransMode mode) {
    return Expanded(
      child: RadioListTile<RowTransMode>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: mode,
        groupValue: _selectedMode,
        onChanged: (val) {
          setState(() {
            _selectedMode = val!;
            _processCipher();
          });
        },
        activeColor: primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            "OUTPUT RESULT",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
          ),
          const SizedBox(height: 15),
          SelectableText(
            result.isEmpty ? 'Waiting for input...' : result,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: result.isEmpty ? Colors.grey : primaryColor,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
