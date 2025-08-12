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
            role: "system",
            content: "Sen bir rüya yorumlama uzmanısın.",
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
export const sendScheduledReminders = onSchedule(
  { schedule: "every 1 minutes", timeZone: "Europe/Istanbul" },
  async () => {
    const now = new Date();
    const hh = now.getHours().toString().padStart(2, "0");
    const mm = now.getMinutes().toString().padStart(2, "0");
    const currentTime = `${hh}:${mm}`; // Kullanıcının hatırlatma zamanı formatı

    // Hatırlatma açık ve zamanı eşleşen kullanıcıları çek
    const snapshot = await db
      .collection("users")
      .where("notificationsEnabled", "==", true)
      .where("reminderTime", "==", currentTime)
      .get();

    if (snapshot.empty) {
      console.log("Bildirim gönderecek kullanıcı yok.");
      return;
    }

    // Tokenları ve kullanıcı ID'lerini eşleştir (tokenMap ile başarısız token temizlemek için)
    const tokenMap = new Map<string, string>();
    const tokens: string[] = [];

    snapshot.docs.forEach(doc => {
      const token = doc.data().fcmToken;
      if (typeof token === "string") {
        tokens.push(token);
        tokenMap.set(token, doc.id);
      }
    });

    if (tokens.length === 0) {
      console.log("Geçerli fcmToken bulunamadı.");
      return;
    }

    // Bildirim mesajını hazırla
    const message: MulticastMessage = {
      tokens,
      notification: {
        title: "Rüya Hatırlatıcı 🌙",
        body: "Bugünkü rüyanı yazmayı unutma!",
      },
    };

    try {
      // Toplu bildirim gönder (sendEachForMulticast kullanılır)
      const response = await getMessaging().sendEachForMulticast(message);

      console.log(`${response.successCount} kullanıcıya bildirim gönderildi.`);

      // Başarısız olan tokenları kontrol et ve temizle
      if (response.failureCount > 0) {
        response.responses.forEach((sendResponse, idx) => {
          if (!sendResponse.success) {
            const failedToken = tokens[idx];
            const userId = tokenMap.get(failedToken);
            console.error(`Token: ${failedToken} için hata:`, sendResponse.error);

            // Geçersiz token ise Firestore'dan temizle
            if (
              sendResponse.error?.code === "messaging/invalid-registration-token" ||
              sendResponse.error?.code === "messaging/registration-token-not-registered"
            ) {
              if (userId) {
                db.collection("users").doc(userId).update({ fcmToken: null })
                  .then(() => console.log(`Geçersiz token temizlendi: ${userId}`))
                  .catch(err => console.error(`Token temizleme hatası (${userId}):`, err));
              }
            }
          }
        });
      }
    } catch (error) {
      console.error("Bildirim gönderilirken hata:", error);
    }
  }
);