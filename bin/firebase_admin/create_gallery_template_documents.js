import admin from "firebase-admin";
import { applicationDefault } from "firebase-admin/app";
import fs from "fs/promises";
import path from "path";
import yaml from "js-yaml";

const templatesDir = path.join("../../templates");

await admin.initializeApp({
  credential: applicationDefault(),
  storageBucket: "tc-write-story.appspot.com",
});

const db = admin.firestore();

async function createTemplateDocuments() {
  try {
    const files = await fs.readdir(templatesDir);
    const yamlFiles = files.filter((file) => file.endsWith(".yaml"));

    for (const file of yamlFiles) {
      const filePath = path.join(templatesDir, file);
      const fileContent = await fs.readFile(filePath, "utf-8");
      const doc = yaml.load(fileContent);

      if (doc && doc.templates) {
        for (const template of doc.templates) {
          if (template.id) {
            const templateId = template.id;
            const docRef = db.collection("templates").doc(templateId);

            console.log(`Setting document for template ${templateId}...`);
            await docRef.set(
              {
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
                name: template.name,
                purpose: template.purpose,
              },
              { merge: true }
            );

            docRef
              .collection("devices")
              .doc("placeholder")
              .set({ initialized: true });

            console.log(`Document for template ${templateId} set.`);
          }
        }
      }
    }
    console.log("Finished processing all templates.");
  } catch (error) {
    console.error("Error processing templates:", error);
  }
}

createTemplateDocuments();
