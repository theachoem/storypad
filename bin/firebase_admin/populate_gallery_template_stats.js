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

/**
 * Calculates the total usage count for a template by summing all device usage records.
 * @param {string} templateId - The template ID
 * @returns {Promise<number>} - Total usage count across all devices
 */
async function calculateTotalUsage(templateId) {
  const count = await db
    .collection("templates")
    .doc(templateId)
    .collection("devices")
    .count();
  return (await count.get()).data().count;
}

/**
 * Populates gallery template statistics by aggregating device usage records.
 * Creates template documents from YAML files and sums up all device usage records.
 */
async function populateGalleryTemplateStats() {
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

            console.log(`Processing template ${templateId}...`);

            // Initialize template document if it doesn't exist
            await docRef.set(
              {
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
                name: template.name,
                purpose: template.purpose,
              },
              { merge: true }
            );

            // Create placeholder device entry if needed
            const devicesSnapshot = await docRef.collection("devices").get();
            if (devicesSnapshot.empty) {
              await docRef
                .collection("devices")
                .doc("placeholder")
                .set({ initialized: true });
            }

            // Calculate and store total usage
            const totalUsage = await calculateTotalUsage(templateId);
            await docRef.update({
              total_usage: totalUsage,
              last_usage_sync_at: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(
              `✓ Template ${templateId} processed (Total usage: ${totalUsage})`
            );
          }
        }
      }
    }
    console.log(
      "✓ Finished populating gallery template statistics and aggregating usage."
    );
  } catch (error) {
    console.error("Error populating gallery template statistics:", error);
  }
}

populateGalleryTemplateStats();
