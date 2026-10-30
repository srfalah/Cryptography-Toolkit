import 'package:crypto_calc/about_me.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'caesar_screen.dart';
import 'diffie_hellman_screen.dart';
import 'inverse_calc_screen.dart';
import 'mod_calculator_screen.dart';
import 'rsa_screen.dart';
import 'vigenere_screen.dart';
import 'elgamal_screen.dart';
import 'rail_fence_screen.dart';
import 'row_transposition_screen.dart';
import 'playfair_screen.dart';
import 'route_cipher_screen.dart';

void main() {
  runApp(const CryptographyApp());
}

enum WorkbenchFilter {
  all,
  math,
  symmetric,
  asymmetric,
}

enum SymmetricSubFilter {
  all,
  substitution,
  transposition,
}

class CryptographyApp extends StatelessWidget {
  const CryptographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Crypto Toolkit',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: currentMode,
          home: const DashboardScreen(),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WorkbenchFilter _selectedFilter = WorkbenchFilter.all;
  SymmetricSubFilter _symmetricSubFilter = SymmetricSubFilter.all;

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppTheme.isDark(context);
    final Color brandAccent = AppTheme.navyAccent(context);
    final Color tealColor = AppTheme.tealAccent(context);
    final Color orangeColor = AppTheme.orangeAccent(context);
    final Color purpleColor = AppTheme.purpleAccent(context);
    final Color transColor = AppTheme.transpositionAccent(context);

    final bool showMath = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.math;
    final bool showSymmetricSection = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.symmetric;
    final bool showSubstitution = showSymmetricSection &&
        (_selectedFilter == WorkbenchFilter.all ||
            _symmetricSubFilter == SymmetricSubFilter.all ||
            _symmetricSubFilter == SymmetricSubFilter.substitution);
    final bool showTransposition = showSymmetricSection &&
        (_selectedFilter == WorkbenchFilter.all ||
            _symmetricSubFilter == SymmetricSubFilter.all ||
            _symmetricSubFilter == SymmetricSubFilter.transposition);
    final bool showAsymmetric = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.asymmetric;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Cryptography Toolkit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.navyAppBar(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Dark / Light Mode Toggle Button (left of About Me button)
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: toggleAppTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
                color: isDark ? const Color(0xFFFBBF24) : Colors.white,
              ),
            ),
          ),
          // About Developer Button
          IconButton(
            tooltip: 'About Developer',
            icon: const Icon(Icons.person_pin_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutMeScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. COMPACT WORKBENCH HERO HEADER + FILTER RIBBON
              _buildWorkbenchHeroHeader(
                context,
                brandAccent: brandAccent,
                tealColor: tealColor,
                purpleColor: purpleColor,
                transColor: transColor,
              ),

              const SizedBox(height: 14),

              // 2. MATHEMATICAL TOOLS SECTION
              if (showMath) ...[
                _buildSectionTitle(
                  context,
                  title: "Mathematical Tools",
                  icon: Icons.calculate_outlined,
                  countLabel: "2 Tools",
                ),
                _buildMenuCard(
                  context,
                  title: "Extended Euclidean",
                  formulaBadge: "a⁻¹ mod n",
                  subtitle: "Find Modular Inverse & GCD step-by-step",
                  icon: Icons.view_comfortable_rounded,
                  color: tealColor,
                  destination: const InverseCalcScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "Crypto Calculator",
                  formulaBadge: "a^b mod n",
                  subtitle: "Modular power, inverse, GCD, primes & roots",
                  icon: Icons.calculate_rounded,
                  color: orangeColor,
                  destination: const ModCalculatorScreen(),
                ),
                const SizedBox(height: 8),
              ],

              // 3. SYMMETRIC CIPHERS SECTION (SUBSTITUTION + TRANSPOSITION)
              if (showSymmetricSection) ...[
                _buildSectionTitle(
                  context,
                  title: "Symmetric Ciphers",
                  icon: Icons.vpn_key_rounded,
                  countLabel: showSubstitution && showTransposition
                      ? "6 Ciphers"
                      : "3 Ciphers",
                ),
                if (_selectedFilter == WorkbenchFilter.symmetric) ...[
                  _buildSymmetricSubFilterBar(
                    context,
                    purpleColor: purpleColor,
                    transColor: transColor,
                  ),
                  const SizedBox(height: 10),
                ],
                if (showSubstitution)
                  _buildSubSectionGroup(
                    context,
                    title: "Substitution",
                    subtitle: "Replace characters or digraphs using a key",
                    icon: Icons.find_replace_rounded,
                    color: purpleColor,
                    children: [
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Caesar Cipher",
                        formulaBadge: "(P + K) mod 26",
                        subtitle: "Classic monoalphabetic shift cipher",
                        icon: Icons.text_fields_rounded,
                        color: purpleColor,
                        destination: const CaesarScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Vigenère Cipher",
                        formulaBadge: "(Pᵢ + Kᵢ) mod 26",
                        subtitle: "Polyalphabetic keyword shift method",
                        icon: Icons.lock_open_rounded,
                        color: purpleColor,
                        destination: const VigenereScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        isLastInGroup: true,
                        title: "Playfair Cipher",
                        formulaBadge: "5×5 Matrix",
                        subtitle: "Digraph substitution on a 5×5 key grid",
                        icon: Icons.grid_on_rounded,
                        color: purpleColor,
                        destination: const PlayfairScreen(),
                      ),
                    ],
                  ),
                if (showSubstitution && showTransposition)
                  const SizedBox(height: 12),
                if (showTransposition)
                  _buildSubSectionGroup(
                    context,
                    title: "Transposition",
                    subtitle:
                        "Rearrange character positions via geometric paths",
                    icon: Icons.swap_calls_rounded,
                    color: transColor,
                    children: [
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Rail-Fence Cipher",
                        formulaBadge: "Zigzag Rails",
                        subtitle: "Diagonal wave transposition across rails",
                        icon: Icons.fence_rounded,
                        color: transColor,
                        destination: const RailFenceScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Row Transposition",
                        formulaBadge: "Keyed Columns",
                        subtitle: "Columnar readout ordered by numeric key",
                        icon: Icons.view_column_rounded,
                        color: transColor,
                        destination: const RowTranspositionScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        isLastInGroup: true,
                        title: "Route Cipher",
                        formulaBadge: "Spiral & Snake",
                        subtitle: "Spiral ↻ and snake ⇅ grid path traversal",
                        icon: Icons.route_rounded,
                        color: transColor,
                        destination: const RouteCipherScreen(),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],

              // 4. ASYMMETRIC ENCRYPTION SECTION
              if (showAsymmetric) ...[
                _buildSectionTitle(
                  context,
                  title: "Asymmetric Encryption",
                  icon: Icons.security_rounded,
                  countLabel: "3 Protocols",
                ),
                _buildMenuCard(
                  context,
                  title: "RSA Algorithm",
                  formulaBadge: "C = M^e mod n",
                  subtitle: "Prime key generation, encryption & decryption",
                  icon: Icons.key_rounded,
                  color: brandAccent,
                  destination: const RsaScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "Diffie-Hellman",
                  formulaBadge: "K = Y^X mod q",
                  subtitle: "Visual public-channel key exchange crossover",
                  icon: Icons.swap_horizontal_circle_rounded,
                  color: brandAccent,
                  destination: const DiffieHellmanScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "El-Gamal Cipher",
                  formulaBadge: "(C₁, C₂) Pair",
                  subtitle:
                      "Probabilistic public-key encryption & discrete logs",
                  icon: Icons.shield_outlined,
                  color: brandAccent,
                  destination: const ElGamalScreen(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkbenchHeroHeader(
    BuildContext context, {
    required Color brandAccent,
    required Color tealColor,
    required Color purpleColor,
    required Color transColor,
  }) {
    final bool isDark = AppTheme.isDark(context);

    // Harmonious multi-stop theme gradient tailored for Light & Dark modes
    final List<Color> headerGradient = isDark
        ? const [
            Color(0xFF172554), // Deep royal midnight navy
            Color(0xFF1E293B), // Rich slate surface
            Color(0xFF112A34), // Subtle deep teal-slate accent
          ]
        : const [
            Color(0xFFE0E7FF), // Soft royal indigo-navy mist
            Color(0xFFEFF6FF), // Airy ice-blue center
            Color(0xFFE0F2FE), // Soft sky-teal glow
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: brandAccent.withValues(alpha: isDark ? 0.38 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : brandAccent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Algorithm Workbench",
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: brandAccent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Select a tool or filter by main category",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: brandAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  "11 Tools",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: brandAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4 Main Category Chips fitted across the full width with zero scrolling
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  context,
                  label: "All",
                  filter: WorkbenchFilter.all,
                  activeColor: brandAccent,
                  icon: Icons.apps_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFilterChip(
                  context,
                  label: "Math",
                  filter: WorkbenchFilter.math,
                  activeColor: tealColor,
                  icon: Icons.functions_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFilterChip(
                  context,
                  label: "Symmetric",
                  filter: WorkbenchFilter.symmetric,
                  activeColor: purpleColor,
                  icon: Icons.vpn_key_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFilterChip(
                  context,
                  label: "Asymmetric",
                  filter: WorkbenchFilter.asymmetric,
                  activeColor: brandAccent,
                  icon: Icons.security_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymmetricSubFilterBar(
    BuildContext context, {
    required Color purpleColor,
    required Color transColor,
  }) {
    final bool isDark = AppTheme.isDark(context);

    Widget subPill({
      required String label,
      required SymmetricSubFilter subFilter,
      required Color color,
    }) {
      final bool selected = _symmetricSubFilter == subFilter;
      final Color activeText =
          isDark && color.computeLuminance() > 0.45
              ? const Color(0xFF0F172A)
              : Colors.white;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _symmetricSubFilter = subFilter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? activeText
                      : AppTheme.textSecondary(context),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle(context)),
      ),
      child: Row(
        children: [
          subPill(
            label: "All Symmetric (6)",
            subFilter: SymmetricSubFilter.all,
            color: purpleColor,
          ),
          subPill(
            label: "Substitution (3)",
            subFilter: SymmetricSubFilter.substitution,
            color: purpleColor,
          ),
          subPill(
            label: "Transposition (3)",
            subFilter: SymmetricSubFilter.transposition,
            color: transColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required WorkbenchFilter filter,
    required Color activeColor,
    required IconData icon,
  }) {
    final bool isSelected = _selectedFilter == filter;
    final bool isDark = AppTheme.isDark(context);
    final Color chipFill = isSelected
        ? activeColor
        : (isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85));
    final Color activeTextColor =
        isDark && activeColor.computeLuminance() > 0.45
            ? const Color(0xFF0F172A)
            : Colors.white;

    return Material(
      color: chipFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = filter),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : brandAccentOrSubtleBorder(context, isDark),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? activeTextColor
                      : AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? activeTextColor
                        : AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color brandAccentOrSubtleBorder(BuildContext context, bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFCBD5E1);
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String countLabel,
  }) {
    final bool isDark = AppTheme.isDark(context);
    final Color bannerStart =
        isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1E3A8A);
    final Color bannerEnd = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFF1E3A8A).withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerStart,
            bannerStart.withValues(alpha: 0.85),
            bannerEnd,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionGroup(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final bool isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.22),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${children.length}",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String formulaBadge,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    bool isSubItem = false,
    bool isLastInGroup = false,
  }) {
    final bool isDark = AppTheme.isDark(context);
    return Container(
      margin: EdgeInsets.only(
        bottom: isSubItem ? (isLastInGroup ? 0 : 8) : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.06),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: isDark ? 0.22 : 0.16),
                        color.withValues(alpha: isDark ? 0.08 : 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 13),

                // Line 1: Title, Line 2: Math Symbol Badge, Line 3: Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                color.withValues(alpha: isDark ? 0.4 : 0.25),
                          ),
                        ),
                        child: Text(
                          formulaBadge,
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron Pill
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
