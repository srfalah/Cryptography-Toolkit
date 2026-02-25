import 'package:crypto_calc/about_me.dart';
import 'package:flutter/material.dart';
import 'caesar_screen.dart';
import 'diffie_hellman_screen.dart';
import 'inverse_calc_screen.dart';
import 'mod_calculator_screen.dart';
import 'rsa_screen.dart';
import 'vigenere_screen.dart';
import 'elgamal_screen.dart';
import 'rail_fence_screen.dart';
import 'row_transposition_screen.dart';

void main() {
  runApp(const CryptographyApp());
}

class CryptographyApp extends StatelessWidget {
  const CryptographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Toolkit',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptography Toolkit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  children: const [
                    Icon(Icons.handyman, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Algorithm Workbench",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ]
              ),
              const Text("Select a tool to start learning", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),

              _buildSectionTitle("Mathematical Tools"),
              _buildMenuCard(
                context,
                title: "Extended Euclidean",
                subtitle: "Find Modular Inverse step-by-step",
                icon: Icons.view_comfortable,
                color: Colors.teal.shade700,
                destination: const InverseCalcScreen(),
              ),
              _buildMenuCard(
                context,
                title: "Modular Exponentiation",
                subtitle: "Calculation of (a^b mod n) efficiency",
                icon: Icons.speed_rounded,
                color: Colors.orange.shade800,
                destination: const ModCalculatorScreen(),
              ),

              const SizedBox(height: 20),


              _buildSectionTitle("Symmetric Ciphers"),

              _buildSubSectionTitle("Substitution", Colors.deepPurple.shade600),
              _buildMenuCard(
                context,
                isSubItem: true,
                title: "Caesar Cipher",
                subtitle: "The classic shift substitution cipher",
                icon: Icons.text_fields_rounded,
                color: Colors.deepPurple.shade600,
                destination: const CaesarScreen(),
              ),
              _buildMenuCard(
                context,
                isSubItem: true,
                title: "Vigenère Cipher",
                subtitle: "Polyalphabetic substitution method",
                icon: Icons.lock_open,
                color: Colors.deepPurple.shade600,
                destination: const VigenereScreen(),
              ),

              const SizedBox(height: 10),

              _buildSubSectionTitle("Transposition", Colors.blueGrey.shade800),
              _buildMenuCard(
                context,
                isSubItem: true,
                title: "Rail-Fence Cipher",
                subtitle: "Zigzag transposition method",
                icon: Icons.fence_rounded,
                color: Colors.blueGrey.shade800,
                destination: const RailFenceScreen(),
              ),
              _buildMenuCard(
                context,
                isSubItem: true,
                title: "Row Transposition",
                subtitle: "Columnar rearrangement technique",
                icon: Icons.view_column_rounded,
                color: Colors.blueGrey.shade800,
                destination: const RowTranspositionScreen(),
              ),

              const SizedBox(height: 20),


              _buildSectionTitle("Asymmetric Encryption"),
              _buildMenuCard(
                context,
                title: "RSA Algorithm",
                subtitle: "Key generation, encryption & decryption",
                icon: Icons.key_outlined,
                color: const Color(0xFF1E3A8A),
                destination: const RsaScreen(),
              ),
              _buildMenuCard(
                context,
                title: "Diffie-Hellman",
                subtitle: "Key exchange & Alice-Bob simulation",
                icon: Icons.swap_horizontal_circle_rounded,
                color: const Color(0xFF1E3A8A),
                destination: const DiffieHellmanScreen(),
              ),
              _buildMenuCard(
                context,
                title: "El-Gamal Cipher",
                subtitle: "Public-key cryptography & discrete logs",
                icon: Icons.shield_outlined,
                color: const Color(0xFF1E3A8A),
                destination: const ElGamalScreen(),
              ),

              const SizedBox(height: 20),


              _buildSectionTitle("Developer"),
              _buildMenuCard(
                context,
                title: "About Me",
                subtitle: "Information about the developer",
                icon: Icons.person_pin_rounded,
                color: Colors.blueGrey.shade900,
                destination: const AboutMeScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 20, bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A),
            const Color(0xFF1E3A8A).withOpacity(0.8),
            const Color(0xFF1E3A8A).withOpacity(0.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Colors.white, size: 24),
          const SizedBox(width: 5),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionTitle(String title, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(bottom: 10, left: 25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 5)),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    bool isSubItem = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: isSubItem ? 25 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}
