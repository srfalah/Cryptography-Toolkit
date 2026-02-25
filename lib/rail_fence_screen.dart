import 'package:flutter/material.dart';

enum RailFenceMode { encrypt, decrypt }

class RailFenceScreen extends StatefulWidget {
  const RailFenceScreen({super.key});

  @override
  State<RailFenceScreen> createState() => _RailFenceScreenState();
}

class _RailFenceScreenState extends State<RailFenceScreen> {
  final TextEditingController messageController = TextEditingController();

  RailFenceMode _selectedMode = RailFenceMode.encrypt;
  int _selectedKey = 2;
  String result = '';



  final Color primaryColor = Colors.blueGrey.shade800;
  final Color highlightColor = Colors.blueGrey.shade100;


  List<List<String>> displayGrid = [];

  void _processCipher() {
    String text = messageController.text.replaceAll(' ', '').toUpperCase();
    if (text.isEmpty) {
      setState(() {
        result = '';
        displayGrid = [];
      });
      return;
    }

    if (_selectedMode == RailFenceMode.encrypt) {
      result = _encryptRailFence(text, _selectedKey);
    } else {
      result = _decryptRailFence(text, _selectedKey);
    }
  }

  String _encryptRailFence(String text, int key) {
    List<List<String>> rail = List.generate(
      key,
      (_) => List.filled(text.length, ''),
    );
    bool dirDown = false;
    int row = 0, col = 0;

    for (int i = 0; i < text.length; i++) {
      if (row == 0 || row == key - 1) dirDown = !dirDown;
      rail[row][col++] = text[i];
      dirDown ? row++ : row--;
    }

    setState(() {
      displayGrid = rail;
    });

    String res = "";
    for (int i = 0; i < key; i++) {
      for (int j = 0; j < text.length; j++) {
        if (rail[i][j] != '') res += rail[i][j];
      }
    }
    return res;
  }

  String _decryptRailFence(String cipher, int key) {
    List<List<String>> rail = List.generate(
      key,
      (_) => List.filled(cipher.length, ''),
    );
    bool dirDown = false;
    int row = 0, col = 0;

    for (int i = 0; i < cipher.length; i++) {
      if (row == 0) dirDown = true;
      if (row == key - 1) dirDown = false;
      rail[row][col++] = '*';
      dirDown ? row++ : row--;
    }

    int index = 0;
    for (int i = 0; i < key; i++) {
      for (int j = 0; j < cipher.length; j++) {
        if (rail[i][j] == '*' && index < cipher.length) {
          rail[i][j] = cipher[index++];
        }
      }
    }

    setState(() {
      displayGrid = rail;
    });

    String res = "";
    row = 0;
    col = 0;
    for (int i = 0; i < cipher.length; i++) {
      if (row == 0) dirDown = true;
      if (row == key - 1) dirDown = false;
      if (rail[row][col] != '*') {
        res += rail[row][col++];
        dirDown ? row++ : row--;
      }
    }
    return res;
  }

  void _clearAll() {
    FocusScope.of(context).unfocus() ;

    setState(() {
      messageController.clear();
      _selectedKey = 2;
      _selectedMode = RailFenceMode.encrypt;
      result = '';
      displayGrid = [];
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.fence),
            SizedBox(width: 10),
            Text('Rail Fence Cipher', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.message, color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("Select Key (Rails)"),
              Row(
                children: [
                  _buildKeyRadioTile("2 Rails", 2),
                  _buildKeyRadioTile("3 Rails", 3),
                ],
              ),
              const SizedBox(height: 10),

              _buildSectionTitle("Select Mode"),
              Row(
                children: [
                  _buildModeRadioTile("Encrypt", RailFenceMode.encrypt),
                  _buildModeRadioTile("Decrypt", RailFenceMode.decrypt),
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
        _buildSectionTitle("Visual Grid"),
        Container(
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
              children: displayGrid.map((row) {
                return Row(
                  children: row.map((char) {
                    bool isEmpty = char == '';
                    return Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isEmpty ? Colors.transparent : primaryColor,
                        border: Border.all(
                          color: isEmpty ? Colors.grey.shade300 : primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        char,
                        style: TextStyle(
                          color: isEmpty ? Colors.transparent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildKeyRadioTile(String title, int value) {
    return Expanded(
      child: RadioListTile<int>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: _selectedKey,
        onChanged: (val) {
          setState(() {
            _selectedKey = val!;
            _processCipher();
          });
        },
        activeColor: primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildModeRadioTile(String title, RailFenceMode mode) {
    return Expanded(
      child: RadioListTile<RailFenceMode>(
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
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
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
