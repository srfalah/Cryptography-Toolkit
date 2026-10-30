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
import 'playfair_screen.dart';
import 'route_cipher_screen.dart';

void main() {
  runApp(const CryptographyApp());
}

enum WorkbenchFilter {
  all,
  math,
  substitution,
  transposition,
  asymmetric,
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WorkbenchFilter _selectedFilter = WorkbenchFilter.all;

  final Color _brandNavy = const Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    final bool showMath = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.math;
    final bool showSubstitution = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.substitution;
    final bool showTransposition = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.transposition;
    final bool showSymmetricHeader = showSubstitution || showTransposition;
    final bool showAsymmetric = _selectedFilter == WorkbenchFilter.all ||
        _selectedFilter == WorkbenchFilter.asymmetric;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.enhanced_encryption_rounded, size: 21),
            SizedBox(width: 8),
            Text(
              'Cryptography Toolkit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: _brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
              _buildWorkbenchHeroHeader(),

              const SizedBox(height: 14),

              // 2. MATHEMATICAL TOOLS SECTION
              if (showMath) ...[
                _buildSectionTitle(
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
                  color: Colors.teal.shade700,
                  destination: const InverseCalcScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "Modular Exponentiation",
                  formulaBadge: "a^b mod n",
                  subtitle: "Fast modular power, inverse & primitive roots",
                  icon: Icons.speed_rounded,
                  color: Colors.orange.shade800,
                  destination: const ModCalculatorScreen(),
                ),
                const SizedBox(height: 8),
              ],

              // 3. SYMMETRIC CIPHERS SECTION (SUBSTITUTION + TRANSPOSITION)
              if (showSymmetricHeader) ...[
                _buildSectionTitle(
                  title: "Symmetric Ciphers",
                  icon: Icons.vpn_key_rounded,
                  countLabel: showSubstitution && showTransposition
                      ? "6 Ciphers"
                      : "3 Ciphers",
                ),
                if (showSubstitution)
                  _buildSubSectionGroup(
                    title: "Substitution",
                    subtitle: "Replace characters or digraphs using a key",
                    icon: Icons.find_replace_rounded,
                    color: Colors.deepPurple.shade600,
                    children: [
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Caesar Cipher",
                        formulaBadge: "(P + K) mod 26",
                        subtitle: "Classic monoalphabetic shift cipher",
                        icon: Icons.text_fields_rounded,
                        color: Colors.deepPurple.shade600,
                        destination: const CaesarScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Vigenère Cipher",
                        formulaBadge: "(Pᵢ + Kᵢ) mod 26",
                        subtitle: "Polyalphabetic keyword shift method",
                        icon: Icons.lock_open_rounded,
                        color: Colors.deepPurple.shade600,
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
                        color: Colors.deepPurple.shade600,
                        destination: const PlayfairScreen(),
                      ),
                    ],
                  ),
                if (showSubstitution && showTransposition)
                  const SizedBox(height: 12),
                if (showTransposition)
                  _buildSubSectionGroup(
                    title: "Transposition",
                    subtitle: "Rearrange character positions via geometric paths",
                    icon: Icons.swap_calls_rounded,
                    color: Colors.blueGrey.shade800,
                    children: [
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Rail-Fence Cipher",
                        formulaBadge: "Zigzag Rails",
                        subtitle: "Diagonal wave transposition across rails",
                        icon: Icons.fence_rounded,
                        color: Colors.blueGrey.shade800,
                        destination: const RailFenceScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        isSubItem: true,
                        title: "Row Transposition",
                        formulaBadge: "Keyed Columns",
                        subtitle: "Columnar readout ordered by numeric key",
                        icon: Icons.view_column_rounded,
                        color: Colors.blueGrey.shade800,
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
                        color: Colors.blueGrey.shade800,
                        destination: const RouteCipherScreen(),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],

              // 4. ASYMMETRIC ENCRYPTION SECTION
              if (showAsymmetric) ...[
                _buildSectionTitle(
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
                  color: _brandNavy,
                  destination: const RsaScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "Diffie-Hellman",
                  formulaBadge: "K = Y^X mod q",
                  subtitle: "Visual public-channel key exchange crossover",
                  icon: Icons.swap_horizontal_circle_rounded,
                  color: _brandNavy,
                  destination: const DiffieHellmanScreen(),
                ),
                _buildMenuCard(
                  context,
                  title: "El-Gamal Cipher",
                  formulaBadge: "(C₁, C₂) Pair",
                  subtitle: "Probabilistic public-key encryption & discrete logs",
                  icon: Icons.shield_outlined,
                  color: _brandNavy,
                  destination: const ElGamalScreen(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkbenchHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _brandNavy.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _brandNavy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  gradient: LinearGradient(
                    colors: [
                      _brandNavy,
                      const Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
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
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _brandNavy,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Select a tool or filter by category below",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _brandNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "11 Tools",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _brandNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: "All",
                  filter: WorkbenchFilter.all,
                  activeColor: _brandNavy,
                  icon: Icons.apps_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: "Math",
                  filter: WorkbenchFilter.math,
                  activeColor: Colors.teal.shade700,
                  icon: Icons.functions_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: "Substitution",
                  filter: WorkbenchFilter.substitution,
                  activeColor: Colors.deepPurple.shade600,
                  icon: Icons.find_replace_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: "Transposition",
                  filter: WorkbenchFilter.transposition,
                  activeColor: Colors.blueGrey.shade800,
                  icon: Icons.route_rounded,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: "Asymmetric",
                  filter: WorkbenchFilter.asymmetric,
                  activeColor: _brandNavy,
                  icon: Icons.security_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required WorkbenchFilter filter,
    required Color activeColor,
    required IconData icon,
  }) {
    final bool isSelected = _selectedFilter == filter;
    return Material(
      color: isSelected ? activeColor : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = filter),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.blueGrey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : Colors.blueGrey.shade700,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required String countLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brandNavy,
            _brandNavy.withValues(alpha: 0.85),
            _brandNavy.withValues(alpha: 0.08),
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
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: _brandNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionGroup({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
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
                  color: color.withValues(alpha: 0.12),
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
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
    return Container(
      margin: EdgeInsets.only(
        bottom: isSubItem ? (isLastInGroup ? 0 : 8) : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
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
                        color.withValues(alpha: 0.16),
                        color.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: color.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 13),

                // Title + Formula Badge + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
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
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.blueGrey.shade600,
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
                    color: color.withValues(alpha: 0.08),
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
