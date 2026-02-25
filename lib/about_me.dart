import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});


  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw 'Could not launch $urlString';
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color accentColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor, accentColor],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Sultan Alfalah",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "Junior Enthusiast Programmer",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: "About The App",
                      icon: Icons.info_outline,
                      color: primaryColor,
                      content: "This application is an educational tool designed to help students understand encryption algorithms (RSA, Diffie-Hellman, etc.) and the mathematical operations associated with them in a simple and interactive way.",
                    ),
        
                    const SizedBox(height: 25),
        
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "  Connect with me",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
        
        
                    _buildContactCard(
                      icon: Icons.alternate_email_rounded,
                      label: "Email",
                      value: "sultan1rashid@gmail.com",
                      color: Colors.red.shade700,
                      onTap: () => _launchURL("mailto:sultan1rashid@gmail.com"),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: "WhatsApp",
                      value: "+966 55 721 6567",
                      color: Colors.green.shade700,
                      onTap: () => _launchURL("https://wa.me/966557216567"),
                    ),
        
                    const SizedBox(height: 50),
                    const Text(
                      "Version 2.1.0",
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String label, required String value, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}