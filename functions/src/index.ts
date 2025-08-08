import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import OpenAI from "openai";

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
