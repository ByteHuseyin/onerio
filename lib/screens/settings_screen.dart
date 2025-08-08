import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart'; 
import 'history_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _dreamAnalysis = true;
  double _notificationOpacity = 0.8;
  String _selectedLanguage = "Türkçe";
  bool _isSigningOut = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Çıkış yap fonksiyonu
  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Çıkış yaparken hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılamadı: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  // Çıkış onay diyaloğu
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
            child: Text("İptal", style: TextStyle(
              color: _darkMode ? Colors.purple[200] : Colors.purple
            )),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF0F0525) : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _darkMode
                        ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                        : [Colors.purple[300]!, Colors.blue[300]!],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 15),
                    child: Text(
                      "Rüya Evrenini Yönet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: _darkMode
                            ? [const Shadow(blurRadius: 10, color: Colors.black)]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _darkMode ? Icons.nightlight_round : Icons.wb_sunny,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _darkMode = !_darkMode),
              ),
            ],
          ),

          // Kullanıcı Bilgisi Bölümü
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
                        ? Icon(Icons.person, size: 30, color: Colors.white)
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

          SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingCard(
                icon: Icons.palette,
                title: "Tema & Görünüm",
                children: [
                  _buildToggle("Karanlık Mod", _darkMode,
                      (v) => setState(() => _darkMode = v)),
                  _buildSlider("Parlaklık", _notificationOpacity,
                      (v) => setState(() => _notificationOpacity = v)),
                  _buildLanguageSelector(),
                ],
              ),
              
              // Tıklanabilir Rüya Geçmişi Kartı
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryScreen()),
                  );
                },
                child: _buildSettingCard(
                  icon: Icons.history,
                  title: "Rüya Geçmişi",
                  children: [
                    _buildHistoryPreview(),
                    const SizedBox(height: 12),
                    _buildStatRow(),
                  ],
                ),
              ),
              
              _buildSettingCard(
                icon: Icons.notifications_active,
                title: "Bildirimler",
                children: [
                  _buildToggle("Sabah Hatırlatıcı", true, (_) {}),
                  _buildToggle("Rüya Benzerlikleri", true, (_) {}),
                  _buildSlider("Bildirim Opaklığı", _notificationOpacity,
                      (v) => setState(() => _notificationOpacity = v)),
                ],
              ),

              // GELİŞMİŞ AYARLAR
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GELİŞMİŞ",
                      style: TextStyle(
                        color: _darkMode
                            ? Colors.purple[200]
                            : Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildActionTile("Veri Yedekleme", Icons.cloud_upload, () {}),
                    _buildActionTile("Gizlilik Ayarları", Icons.lock, () {}),
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
                              child: Text(
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
              )
            ]),
          ),
        ],
      ),
    );
  }

  // Geçmiş önizleme bileşeni
  Widget _buildHistoryPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _darkMode ? Colors.purple[900]!.withOpacity(0.3) : Colors.purple[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nights_stay, 
                  color: _darkMode ? Colors.amber[200] : Colors.amber[700]),
              const SizedBox(width: 10),
              Text(
                "Rüyalarım",
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: _darkMode ? Colors.deepPurple[800] : Colors.purple[100],
            color: Colors.amber,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 4),
          Text(
            "Hafıza Tamamlama: %70",
            style: TextStyle(
              fontSize: 12,
              color: _darkMode ? Colors.amber[100] : Colors.amber[800]
            ),
          )
        ],
      ),
    );
  }

  // İstatistik satırı
  Widget _buildStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.bookmark, "32", "Kayıtlı"),
        _buildStatItem(Icons.auto_awesome, "14", "Lucid"),
        _buildStatItem(Icons.psychology, "8.2", "Ort. Puan"),
      ],
    );
  }

  // İstatistik öğesi
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: _darkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16
        )),
        Text(label, style: TextStyle(
          color: _darkMode ? Colors.white60 : Colors.black54,
          fontSize: 12
        )),
      ],
    );
  }

  // Diğer yardımcı widget fonksiyonları
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.all(15),
      color: _darkMode ? const Color(0xFF1D0C3D) : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  color: _darkMode ? Colors.purple[200] : Colors.purple),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
            ]),
            const Divider(height: 25),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String text, bool value, ValueChanged<bool>? onChanged) {
    return ListTile(
      title: Text(
        text,
        style:
            TextStyle(color: _darkMode ? Colors.white70 : Colors.black87),
      ),
      trailing: Switch(
        activeColor: Colors.purple,
        activeTrackColor: Colors.purple[200],
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSlider(
      String text, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
              color: _darkMode ? Colors.white70 : Colors.black87,
              fontSize: 14),
        ),
        Slider(
          min: 0.1,
          max: 1.0,
          divisions: 10,
          value: value,
          activeColor: Colors.purple,
          inactiveColor: Colors.purple[100],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      title: Text(
        "Dil",
        style:
            TextStyle(color: _darkMode ? Colors.white70 : Colors.black87),
      ),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        dropdownColor:
            _darkMode ? const Color(0xFF2A1241) : Colors.white,
        items: ["Türkçe", "İngilizce", "Almanca", "Fransızca"]
            .map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: TextStyle(
                        color: _darkMode ? Colors.white : Colors.black),
                  ),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedLanguage = v!),
      ),
    );
  }

  Widget _buildActionTile(String text, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading:
          Icon(icon, color: _darkMode ? Colors.purple[200] : Colors.purple),
      title: Text(
        text,
        style:
            TextStyle(color: _darkMode ? Colors.white70 : Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showSensitivityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _darkMode ? const Color(0xFF1D0C3D) : Colors.white,
        title: Text(
          "Analiz Hassasiyeti",
          style:
              TextStyle(color: _darkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          "Rüyalarınızın psikolojik analiz derinliğini ayarlayın",
          style: TextStyle(
              color: _darkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}