import admin from "firebase-admin";
import { applicationDefault } from "firebase-admin/app";
import fs from "fs/promises";
import path from "path";
import mime from "mime";
import process from "process";
import {
  getFileSize,
  listAllFiles,
  computeHash,
  generateFilePathWithHash,
} from "./helpers.js";

const storageMapFile = path.join("../../assets/firestore_storage_map.json");
const localRoot = path.join("../../firestore_storages");
const cacheFile = path.join("upload_cache.json");

await admin.initializeApp({
  credential: applicationDefault(),
  storageBucket: "tc-write-story.appspot.com",
});

const bucket = admin.storage().bucket();
const files = await listAllFiles(localRoot);
let storageMap = {};

// Load cache if exists
let uploadCache = {};
try {
  const cacheData = await fs.readFile(cacheFile, "utf-8");
  uploadCache = JSON.parse(cacheData);
} catch (e) {
  // No cache file or invalid, start fresh
  uploadCache = {};
}

for (let file of files) {
  if (file.includes(".DS_Store")) continue;

  let filePath = path.join(localRoot, file);
  let hash = await computeHash(filePath);
  let filePathWithHash = generateFilePathWithHash(localRoot, file, hash);
  storageMap[`/${file.replace(localRoot, "")}`] = filePathWithHash;

  // Skip upload if cached and hash matches
  if (uploadCache[filePath] === hash) {
    console.log(` Skipping upload (cached) ${filePathWithHash}`);
    continue;
  }

  const destination = filePathWithHash.slice(1);
  const remoteFile = bucket.file(destination);
  const [exists] = await remoteFile.exists();

  if (getFileSize(filePath) > 20) {
    console.log(` Exit as bigger than 10mb ${filePathWithHash}`);
    process.exit(1);
  }

  if (exists) {
    console.log(` Already Exist ${filePathWithHash}`);
  } else {
    console.log(` Uploading... ${filePathWithHash}`);

    const mimeType = mime.getType(filePath);
    await bucket.upload(filePath, {
      destination: destination,
      metadata: {
        contentType: mimeType,
      },
    });

    console.log(` Uploading done ${filePathWithHash}`);
  }

  // Update cache
  uploadCache[filePath] = hash;
}

await fs.writeFile(
  storageMapFile,
  JSON.stringify(storageMap, null, 2),
  "utf-8"
);

await fs.writeFile(cacheFile, JSON.stringify(uploadCache, null, 2), "utf-8");
