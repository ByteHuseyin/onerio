import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/screens/home_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildStaticScreen(
      context,
      title: "Gizlilik Politikası",
      content: [
        _buildSectionTitle("Veri Toplama ve Kullanım"),
        _buildSectionContent(
          "Uygulamamız, rüya yorumlama hizmeti sunmak için temel kullanıcı verilerini toplar. "
          "Topladığımız veriler arasında rüya açıklamalarınız ve yorum geçmişiniz bulunur. "
          "Bu veriler sadece size kişiselleştirilmiş hizmet sunmak amacıyla kullanılır.",
        ),
        _buildSectionTitle("Veri Güvenliği"),
        _buildSectionContent(
          "Kullanıcı verileri şifrelenmiş bir şekilde saklanır ve yalnızca yetkili personelimiz tarafından erişilebilir. "
          "Verileriniz üçüncü şahıslarla asla paylaşılmaz ve reklam amaçlı kullanılmaz.",
        ),
        _buildSectionTitle("Çerezler"),
        _buildSectionContent(
          "Uygulamamız kullanıcı deneyimini iyileştirmek için çerezler kullanır. "
          "Bu çerezler kişisel tanımlayıcı bilgiler içermez ve oturum yönetimi ile sınırlıdır.",
        ),
        _buildSectionTitle("Değişiklikler"),
        _buildSectionContent(
          "Gizlilik politikamızdaki değişiklikler bu sayfada güncellenecektir. "
          "Önemli değişiklikler için kullanıcılarımıza bildirim gönderilecektir.",
        ),
      ],
    );
  }
}

// Ortak sayfa yapısı
Widget _buildStaticScreen(BuildContext context,
    {required String title, required List<Widget> content}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0F0525),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
        ),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D0C3D), Color(0xFF2A1241)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              ...content,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      label: Text(
        "Ana Sayfa",
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      icon: const Icon(Icons.home),
      backgroundColor: const Color(0xFF6A11CB),
    ),
  );
}

// Bölüm başlığı
Widget _buildSectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.purpleAccent,
      ),
    ),
  );
}

// Bölüm metni
Widget _buildSectionContent(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 15,
        height: 1.6,
        color: Colors.white70,
      ),
    ),
  );
}