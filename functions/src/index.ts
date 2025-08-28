import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import OpenAI from "openai";
import { onSchedule } from "firebase-functions/v2/scheduler";

initializeApp();
const db = getFirestore();
const auth = getAuth();

/**
 * Bildirim gönderme fonksiyonu.
 * Her dakika çalışarak, bildirimleri açık olan ve saati uyan kullanıcılara bildirim gönderir.
 */
export const bildirim = onSchedule(
  { schedule: "every minute", region: "europe-west1", timeZone: "Europe/Istanbul" },
  async () => {
    try {
      // Date nesnesini alıp, Intl.DateTimeFormat ile Istanbul saat diliminde HH:mm formatına dönüştürüyoruz.
      const now = new Date();
      const currentTime = new Intl.DateTimeFormat('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
        timeZone: 'Europe/Istanbul'
      }).format(now);

      console.log(`Şu anki saat: ${currentTime}`);

      // Firebase Firestore'dan bildirim zamanı uyan kullanıcıları sorgula
      const snapshot = await db
        .collection("user_table")
        .where("notificationsEnabled", "==", true)
        .where("reminderTime", "==", currentTime)
        .get();

      if (snapshot.empty) {
        console.log("Bildirim gönderecek kullanıcı bulunamadı.");
        return;
      }

      // Kullanıcıların token'larını ve ID'lerini toplar
      const tokens: string[] = [];
      const tokenMap = new Map<string, string>();
      snapshot.docs.forEach(doc => {
        const token = doc.data().fcmToken;
        if (typeof token === "string" && token) {
          tokens.push(token);
          tokenMap.set(token, doc.id);
        }
      });

      if (tokens.length === 0) {
        console.log("Geçerli token yok, bildirim gönderilemiyor.");
        return;
      }

      // Bildirim mesajı oluşturur
      const message: MulticastMessage = {
        tokens,
        notification: {
          title: "Rüya Hatırlatıcı 🌙",
          body: "Bugünkü rüyanı yazmayı unutma!",
        },
      };

      // Toplu bildirimleri gönderir
      const response = await getMessaging().sendEachForMulticast(message);
      console.log(`${response.successCount} kullanıcıya başarıyla bildirim gönderildi.`);

      // Başarısız olan tokenları temizler
      if (response.failureCount > 0) {
        response.responses.forEach((sendResponse, idx) => {
          if (!sendResponse.success) {
            const failedToken = tokens[idx];
            const userId = tokenMap.get(failedToken);
            console.error(`Token: ${failedToken} için hata: ${sendResponse.error}`);

            if (userId && (sendResponse.error?.code === "messaging/invalid-registration-token" ||
                sendResponse.error?.code === "messaging/registration-token-not-registered")) {
              db.collection("user_table").doc(userId).update({ fcmToken: null })
                .then(() => console.log(`Geçersiz token silindi: ${userId}`))
                .catch(err => console.error(`Token silme hatası (${userId}):`, err));
            }
          }
        });
      }
    } catch (error) {
      console.error("Fonksiyon çalışırken genel bir hata oluştu:", error);
    }
  }
);




export const chatWithOpenAI = onRequest(
  { region: "europe-west1" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Sadece POST istekleri kabul edilir.");
      return;
    }

    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).send("Yetkisiz erişim.");
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    try {
      const decodedToken = await auth.verifyIdToken(idToken);
      const uid = decodedToken.uid;
      console.log("Kullanıcı UID:", uid);
    } catch (err) {
      res.status(401).send("Geçersiz kimlik doğrulama.");
      return;
    }

    const prompt = req.body?.prompt?.trim();
    if (!prompt) {
      res.status(400).send("Prompt boş olamaz.");
      return;
    }

    try {
      const doc = await db.collection("api_keys").doc("openai").get();
      const apiKey = doc.exists ? doc.data()?.key : null;

      if (!apiKey) {
        res.status(500).send("OpenAI API anahtarı bulunamadı.");
        return;
      }

      const openai = new OpenAI({ apiKey });

      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            "role": "system",
            "content": "Sen SADECE rüya tabiri yapan bir asistansın.\n\nKAPSAM:\n- Yalnızca kullanıcının ANLATTIĞI RÜYALARI yorumla.\n- Rüya dışı her talebi, tek cümlelik kibar bir uyarıyla reddet ve rüyasını kısaca anlatmasını iste: \"Bu asistan yalnızca rüya yorumları yapar; lütfen rüyanızı kısaca anlatın.\" Başka içerik üretme.\n\nİLKELER:\n- Olasılık dili kullan (\"şu anlama gelebilir\", \"işaret ediyor olabilir\"). Kesin hükümler verme.\n- Tıbbi/hukuki/finansal teşhis veya yönlendirme verme. Gerekirse genel uyarı ekle (\"bu konular uzman görüşü gerektirebilir\").\n- Kültürel ve kişisel farklılıklara saygılı, yargılayıcı olmayan bir ton kullan.\n- Girdi yetersizse en fazla 2 net ve kısa soru sor (ör. güçlü duygular, öne çıkan semboller). Yeterliyse soru sorma.\n\nÇIKTI BİÇİMİ (Türkçe ve öz):\n1) Özet: Rüyanın kısa özeti.\n2) Temalar/Semboller: Maddeler halinde.\n3) Olası Anlamlar: 2–4 madde; farklı yorum yolları.\n4) Nazik Öneri: Günlük hayatta işe yarar, yönlendirmesiz öneri.\n\nSTİL:\n- 150–250 kelimeyi geçme, net ve anlaşılır yaz.\n- Sadece rüya yorumuyla ilgili içerik üret; doğruluk dışı iddialardan, metafizik vaatlerden kaçın.\n"
          },
          {
            role: "user",
            content: prompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 400,
      });

      const reply = completion.choices[0]?.message?.content?.trim() ?? "";
      const usage = completion.usage ?? {};
      res.status(200).json({ 
      reply,
      usage  // usage objesini ekle
      });
    } catch (err) {
      console.error("OpenAI hatası:", err);
      res.status(500).send("Rüya yorumu oluşturulamadı.");
    }
  }
);


