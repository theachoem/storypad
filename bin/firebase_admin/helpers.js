// helpers.js
import fs from "fs/promises";
import path from "path";
import crypto from "crypto";

/**
 * Returns the file size in megabytes (MB).
 * @param {string} filePath - Full path to the file.
 * @returns {Promise<number>} - File size in megabytes.
 */
export async function getFileSize(filePath) {
  const stat = await fs.stat(filePath);
  return stat.size / (1024 * 1024);
}

/**
 * Recursively list all files in a directory.
 */
export async function listAllFiles(dir, base = dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });

  const files = await Promise.all(
    entries.map((entry) => {
      const fullPath = path.join(dir, entry.name);
      return entry.isDirectory()
        ? listAllFiles(fullPath, base)
        : path.relative(base, fullPath);
    })
  );

  return files.flat();
}

/**
 * Compute SHA256 hash from file content.
 */
export async function computeHash(filePath) {
  const hash = crypto.createHash("sha256");
  const fileContent = await fs.readFile(filePath, { encoding: "utf-8" });
  hash.update(fileContent);
  return hash.digest("hex").slice(0, 32);
}

/**
 * Generates a new path with hash suffix: /relax_sounds/type/file-hash.ext
 */
export function generateFilePathWithHash(localRoot, file, hash) {
  const fileNameWithoutExtension = path.basename(file, path.extname(file));
  const newFileName = `/${path
    .dirname(file)
    .replace(localRoot, "")}/${fileNameWithoutExtension}-${hash}${path.extname(
    file
  )}`;

  return newFileName;
}
