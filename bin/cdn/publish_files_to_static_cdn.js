// publish_files_to_static_cdn.js
//
// Hashes every file under the sibling static/sources/ directory (the
// static.storypad.me submodule), copies the hashed copy into static/public/,
// and regenerates lib/gen/storage_hash_map.dart — a compile-time const map
// (logical-path -> hashed-path) read directly by CloudStorageService, no
// runtime asset load/JSON parse needed.
//
// Requires the static.storypad.me submodule to be checked out at static/ as
// a sibling of app/ at the monorepo root (the normal state of this repo).
import fs from "fs/promises";
import path from "path";
import { execFile } from "child_process";
import { promisify } from "util";
import {
  getFileSize,
  listAllFiles,
  computeHash,
  generateFilePathWithHash,
} from "../firebase_admin/helpers.js";

const execFileAsync = promisify(execFile);

const sourcesRoot = path.join("../../../static/sources");
const publicRoot = path.join("../../../static/public");
const storageMapDartFile = path.join("../../lib/gen/storage_hash_map.dart");

const files = await listAllFiles(sourcesRoot);
let storageMap = {};

for (const file of files) {
  if (file.includes(".DS_Store")) continue;

  const filePath = path.join(sourcesRoot, file);
  const hash = await computeHash(filePath);
  const filePathWithHash = generateFilePathWithHash(sourcesRoot, file, hash);
  storageMap[`/${file}`] = filePathWithHash;

  if ((await getFileSize(filePath)) > 20) {
    console.log(`  Exit as bigger than 20mb ${filePathWithHash}`);
    process.exit(1);
  }

  const destination = path.join(publicRoot, filePathWithHash);
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await fs.copyFile(filePath, destination);
  console.log(`  Published ${filePathWithHash}`);
}

const sortedEntries = Object.entries(storageMap).sort(([a], [b]) =>
  a.localeCompare(b)
);
const mapEntries = sortedEntries
  .map(([key, value]) => `  ${JSON.stringify(key)}: ${JSON.stringify(value)},`)
  .join("\n");

const dartSource = `// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  Storage Hash Map Generator
/// *****************************************************
///
/// Regenerate via: app/bin/publish_files_to_static_cdn

// coverage:ignore-file
// ignore_for_file: type=lint

const Map<String, String> kStorageHashMap = {
${mapEntries}
};
`;

await fs.mkdir(path.dirname(storageMapDartFile), { recursive: true });
await fs.writeFile(storageMapDartFile, dartSource, "utf-8");

console.log("\nFormatting...");
try {
  await execFileAsync("dart", ["format", "lib/gen/storage_hash_map.dart"], {
    cwd: "../..",
  });
  console.log("Formatted successfully");
} catch (error) {
  console.log("Warning: Formatting failed");
  console.log(error.stderr ?? error.message);
}

console.log(
  `\nWrote ${sortedEntries.length} entries to ${storageMapDartFile}`
);
