import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildStaticScreen(
      context,
      title: "Hakkımızda",
      content: [
        _buildSectionTitle("Biz Kimiz?"),
        _buildSectionContent(
          "Oneiro ekibi olarak, rüyaların gizemli dünyasını anlamlandırmak için yapay zeka teknolojisini kullanıyoruz. "
          "Amacımız, rüyalarınızı anlamanıza ve onlardan anlam çıkarmanıza yardımcı olmaktır."
        ),
        _buildSectionTitle("Teknolojimiz"),
        _buildSectionContent(
          "Uygulamamız gelişmiş doğal dil işleme modelleri kullanır. "
          "Rüya açıklamalarınızı analiz ederek psikolojik ve sembolik açıdan zengin yorumlar sunarız."
        ),
        _buildSectionTitle("Misyonumuz"),
        _buildSectionContent(
          "Rüyaların bilinçaltının kapıları olduğuna inanıyoruz. "
          "Misyonumuz, bu kapıları aralayarak kişisel keşif yolculuğunuzda size rehberlik etmektir."
        ),
        _buildSectionTitle("İletişim"),
        _buildSectionContent(
          "Sorularınız ve geri bildirimleriniz için bize ulaşın:\n"
          "Email: destek@oneiro.app\n"
          "Telefon: +90 212 555 01 23"
        ),
      ],
    );
  }
}

Widget _buildStaticScreen(BuildContext context, {required String title, required List<Widget> content}) {
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
  );
}

Widget _buildSectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        color: Colors.purpleAccent,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget _buildSectionContent(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        color: Colors.white70,
        fontSize: 15,
        height: 1.6,
      ),
    ),
  );
}