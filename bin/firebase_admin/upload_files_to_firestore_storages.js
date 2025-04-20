import admin from "firebase-admin";
import { applicationDefault } from "firebase-admin/app";
import fs from "fs/promises";
import path from "path";
import mime from "mime";
import {
  getFileSize,
  listAllFiles,
  computeHash,
  generateFilePathWithHash,
} from "./helpers.js";

const storageMapFile = path.join("../../assets/firestore_storage_map.json");
const localRoot = path.join("../../firestore_storages");

await admin.initializeApp({
  credential: applicationDefault(),
  storageBucket: "tc-write-story.appspot.com",
});

const bucket = admin.storage().bucket();
const files = await listAllFiles(localRoot);
let storageMap = {};

for (let file of files) {
  if (file.includes(".DS_Store")) continue;

  let filePath = path.join(localRoot, file);
  let hash = await computeHash(filePath);
  let filePathWithHash = generateFilePathWithHash(localRoot, file, hash);
  storageMap[`/${file.replace(localRoot, "")}`] = filePathWithHash;

  const destination = filePathWithHash.slice(1);
  const remoteFile = bucket.file(destination);
  const [exists] = await remoteFile.exists();

  if (getFileSize(filePath) > 10) {
    console.log(`⚠️ Exit as bigger than 10mb ${filePathWithHash}`);
    process.exit(1);
  }

  if (exists) {
    console.log(`📂 Already Exist ${filePathWithHash}`);
  } else {
    console.log(`🏃 Uploading... ${filePathWithHash}`);

    const mimeType = mime.getType(filePath);
    await bucket.upload(filePath, {
      destination: destination,
      metadata: {
        contentType: mimeType,
      },
    });

    console.log(`✅ Uploading done ${filePathWithHash}`);
  }
}

await fs.writeFile(
  storageMapFile,
  JSON.stringify(storageMap, null, 2),
  "utf-8"
);
