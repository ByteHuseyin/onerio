import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneiro/screens/home/home_screen.dart';
import 'package:oneiro/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('user_logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<bool> _onWillPop() async {
    // Firestore’dan rüya sayısını alıp geri dön
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context, 0);
      return false;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('user_logs')
        .where('userId', isEqualTo: user.uid)
        .get();
    final dreamCount = snapshot.docs.length;
    Navigator.pop(context, dreamCount);
    return false; // manuel pop yaptık, false dön
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
          title: Text(
            AppLocalizations.of(context)!.history,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _historyStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Veri alınırken hata oluştu:\n${snap.error}',
                    style: GoogleFonts.nunito(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.purpleAccent,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.loading,
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nights_stay,
                          size: 60,
                          color: Colors.purple[200],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.noDreamsYet,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.startAnalyzing,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.analyzeDream,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data();
                  return _HistoryCard(
                    prompt: data['prompt'] as String? ?? '',
                    interpretation: data['response'] as String? ?? '',
                    timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Senin mevcut _HistoryCard widget'ını buraya olduğu gibi alabilirsin
// (Kodun uzun olduğu için burada kısaltıyorum ama aynı kalacak)
class _HistoryCard extends StatefulWidget {
  final String prompt;
  final String interpretation;
  final DateTime? timestamp;

  const _HistoryCard({
    Key? key,
    required this.prompt,
    required this.interpretation,
    this.timestamp,
  }) : super(key: key);

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heightAnimation = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    );
  }

  void _toggle() {
    setState(() {
      if (_expanded) {
        _ctrl.reverse();
      } else {
        _ctrl.forward();
      }
      _expanded = !_expanded;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.timestamp != null
        ? '${widget.timestamp!.day.toString().padLeft(2, '0')}/'
            '${widget.timestamp!.month.toString().padLeft(2, '0')} '
            '${widget.timestamp!.hour.toString().padLeft(2, '0')}:'
            '${widget.timestamp!.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
              // Tarih ve genişletme butonu üstte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.nunito(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_ctrl),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.purple[200],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Rüya inputu ve ikon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.nightlight_round,
                    color: Colors.amber[300],
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  // Tüm inputu göstermek için genişletilmiş alan
                  Expanded(
                    child: Text(
                      widget.prompt,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // Açılır yorum
              SizeTransition(
                sizeFactor: _heightAnimation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rüya Analizi',
                        style: GoogleFonts.nunito(
                          color: Colors.purple[200],
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(
                          widget.interpretation,
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}