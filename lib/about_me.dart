import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

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
    final bool isDark = AppTheme.isDark(context);
    final Color primaryColor = AppTheme.navyAccent(context);
    const Color headerTop = Color(0xFF1E3A8A);
    const Color headerBottom = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgAlt(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: headerTop,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                AppTheme.buildLanguageToggleButton(context),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [headerTop, headerBottom],
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
                      Text(
                        tr("Sultan Alfalah", "سلطان الفلاح"),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: isArabic ? 0 : 1,
                        ),
                      ),
                      Text(
                        tr("Junior Enthusiast Programmer", "مبرمج شغوف بتطوير البرمجيات"),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
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
                      context,
                      title: tr("About The App", "حول التطبيق"),
                      icon: Icons.info_outline,
                      color: primaryColor,
                      content: tr(
                        "This application is an educational tool designed to help students understand encryption algorithms (RSA, Diffie-Hellman, etc.) and the mathematical operations associated with them in a simple and interactive way.",
                        "هذا التطبيق هو أداة تعليمية مصممة لمساعدة الطلاب على فهم خوارزميات التشفير (مثل RSA و Diffie-Hellman وغيرها) والعمليات الرياضية المرتبطة بها بطريقة مبسطة وتفاعلية.",
                      ),
                    ),
                    const SizedBox(height: 25),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        tr("  Connect with me", "  تواصل معي"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      icon: Icons.alternate_email_rounded,
                      label: tr("Email", "البريد الإلكتروني"),
                      value: "sultan1rashid@gmail.com",
                      color: isDark
                          ? const Color(0xFFF87171)
                          : Colors.red.shade700,
                      onTap: () => _launchURL("mailto:sultan1rashid@gmail.com"),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: tr("WhatsApp", "واتساب"),
                      value: "+966 55 721 6567",
                      color: isDark
                          ? const Color(0xFF4ADE80)
                          : Colors.green.shade700,
                      onTap: () => _launchURL("https://wa.me/966557216567"),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      tr("Version 2.1.0", "الإصدار 2.1.0"),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted(context),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary(context),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.borderSubtle(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}
