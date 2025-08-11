import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _morningReminder = true;
  TimeOfDay _reminderTime = TimeOfDay(hour: 8, minute: 0);
  bool _darkMode = true;
  bool _dreamAnalysis = true;
  bool _isSigningOut = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('user_logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _darkMode ? const Color(0xFF1D0C3D) : Colors.white,
        title: Text(
          "Çıkış Yap",
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          "Hesabınızdan çıkmak istediğinize emin misiniz?",
          style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal",
                style: TextStyle(
                    color: _darkMode ? Colors.purple[200] : Colors.purple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _signOut();
            },
            child: const Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return "Bugün";
    } else if (difference == 1) {
      return "Dün";
    } else if (difference <= 7) {
      return "$difference gün önce";
    } else {
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF0F0525) : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _darkMode ? const Color(0xFF6A11CB) : Colors.purple[300],
            centerTitle: true,
            title: Text(
              "Rüya Evrenini Yönet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows:
                    _darkMode ? [const Shadow(blurRadius: 10, color: Colors.black)] : null,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _darkMode
                        ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                        : [Colors.purple[300]!, Colors.blue[300]!],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple[200],
                    backgroundImage: _currentUser?.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.displayName ?? "Misafir Kullanıcı",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.email ?? "email@example.com",
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _historyStream(),
              builder: (context, snapshot) {
                int dreamCount = 0;
                DateTime? lastDreamDate;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  dreamCount = docs.length;
                  if (dreamCount > 0) {
                    final ts = docs.first.data()['timestamp'] as Timestamp?;
                    if (ts != null) lastDreamDate = ts.toDate();
                  }
                }

                double progressPercent = (dreamCount / 7);
                if (progressPercent > 1.0) progressPercent = 1.0;
                final progressPercentStr = (progressPercent * 100).toStringAsFixed(0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: _buildSettingCard(
                    icon: Icons.history,
                    title: "Rüya Geçmişi",
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _darkMode
                              ? Colors.purple[900]!.withOpacity(0.3)
                              : Colors.purple[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.nights_stay,
                                    color: _darkMode
                                        ? Colors.amber[200]
                                        : Colors.amber[700]),
                                const SizedBox(width: 10),
                                Text(
                                  "Rüyalarım",
                                  style: TextStyle(
                                      color: _darkMode ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progressPercent,
                              backgroundColor:
                                  _darkMode ? Colors.deepPurple[800] : Colors.purple[100],
                              color: Colors.amber,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Hafıza Tamamlama: %$progressPercentStr",
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _darkMode ? Colors.amber[100] : Colors.amber[800]),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        dreamCount: dreamCount,
                        progressPercentStr: progressPercentStr,
                        lastDreamDate: lastDreamDate,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingCard(
                icon: Icons.notifications_active,
                title: "Bildirimler",
                children: [
                  _buildToggle(
                    "Sabah Hatırlatıcı",
                    _morningReminder,
                    (val) => setState(() => _morningReminder = val),
                  ),
                  _buildTimePickerTile(
                    title: "Hatırlatıcı Saati",
                    selectedTime: _reminderTime,
                    onTimePicked: (time) => setState(() => _reminderTime = time),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GELİŞMİŞ",
                      style: TextStyle(
                        color: _darkMode ? Colors.purple[200] : Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile("Gizlilik Politikası", Icons.lock, () {}),
                    _buildActionTile("Hakkında", Icons.info, () {}),
                    const SizedBox(height: 10),
                    Center(
                      child: _isSigningOut
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkMode
                                    ? Colors.red[800]!.withOpacity(0.8)
                                    : Colors.red[400],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _showLogoutConfirmation,
                              child: const Text(
                                "HESAPTAN ÇIKIŞ YAP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required int dreamCount,
    required String progressPercentStr,
    required DateTime? lastDreamDate,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.bookmark, dreamCount.toString(), "Kayıtlı"),
        _buildStatItem(Icons.auto_awesome, "$progressPercentStr%", "Gelişim"),
        _buildStatItem(
            Icons.history,
            lastDreamDate != null ? _formatRelativeDate(lastDreamDate) : "-",
            "Son Rüya"),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: _darkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: TextStyle(
                color: _darkMode ? Colors.white60 : Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required TimeOfDay selectedTime,
    required ValueChanged<TimeOfDay> onTimePicked,
  }) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      trailing: Text(
        selectedTime.format(context),
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) onTimePicked(picked);
      },
    );
  }

  Widget _buildToggle(String text, bool value, ValueChanged<bool>? onChanged) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black87),
      ),
      trailing: Switch(
        activeColor: Colors.purple,
        activeTrackColor: Colors.purple[200],
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(String text, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _darkMode ? Colors.purple[200] : Colors.purple),
      title: Text(
        text,
        style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // EKSİK OLAN BU FONKSİYON:
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: _darkMode ? const Color(0xFF1D0C3D) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Colors.purpleAccent),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _darkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
