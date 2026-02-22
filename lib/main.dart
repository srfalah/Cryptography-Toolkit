import 'package:crypto_calc/about_me.dart';
import 'package:flutter/material.dart';
import 'caesar_screen.dart';
import 'diffie_hellman_screen.dart';
import 'inverse_calc_screen.dart';
import 'mod_calculator_screen.dart';
import 'rsa_screen.dart';
import 'vigenere_screen.dart';
//import 'about_me_screen.dart';

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
              const Text(
                "Security Laboratory",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const Text("Select a tool to start learning", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
        
              _buildSectionTitle("Mathematical Tools"),
              _buildMenuCard(
                context,
                title: "Extended Euclidean",
                subtitle: "Find Modular Inverse step-by-step",
                icon: Icons.calculate_rounded,
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
        
              _buildSectionTitle("Classical Ciphers"),
              _buildMenuCard(
                context,
                title: "Caesar Cipher",
                subtitle: "The classic shift substitution cipher",
                icon: Icons.text_fields_rounded,
                color: Colors.indigo.shade600,
                destination: const CaesarScreen(),
              ),
              _buildMenuCard(
                context,
                title: "Vigenère Cipher",
                subtitle: "Polyalphabetic substitution method",
                icon: Icons.grid_on_rounded,
                color: Colors.deepPurple.shade600,
                destination: const VigenereScreen(),
              ),
        
              const SizedBox(height: 20),
        
              _buildSectionTitle("Asymmetric Encryption"),
              _buildMenuCard(
                context,
                title: "RSA Algorithm",
                subtitle: "Key generation, encryption & decryption",
                icon: Icons.security_rounded,
                color: const Color(0xFF1E3A8A),
                destination: const RsaScreen(),
              ),
              _buildMenuCard(
                context,
                title: "Diffie-Hellman",
                subtitle: "Key exchange & Alice-Bob simulation",
                icon: Icons.swap_horizontal_circle_rounded,
                color: const Color(0xFFBE185D),
                destination: const DiffieHellmanScreen(),
              ),
        
              const SizedBox(height: 20),
        
              _buildSectionTitle("Developer"),
              _buildMenuCard(
                context,
                title: "About Me",
                subtitle: "Information about the developer",
                icon: Icons.person_pin_rounded,
                color: Colors.blueGrey.shade800,
                destination: const AboutMeScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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