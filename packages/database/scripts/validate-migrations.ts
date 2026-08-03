import { readdir, readFile } from "node:fs/promises";
import { resolve } from "node:path";

const directory = resolve(import.meta.dirname, "../migrations");
const files = await readdir(directory);
const upFiles = files.filter((file) => file.endsWith(".up.sql")).sort();
const downFiles = new Set(files.filter((file) => file.endsWith(".down.sql")));

if (upFiles.length === 0) throw new Error("En az bir migration gereklidir.");

for (const upFile of upFiles) {
  const downFile = upFile.replace(".up.sql", ".down.sql");
  if (!downFiles.has(downFile))
    throw new Error(`${upFile} için rollback bulunamadı.`);

  const sql = await readFile(resolve(directory, upFile), "utf8");
  if (!/begin;/i.test(sql) || !/commit;/i.test(sql)) {
    throw new Error(`${upFile} transaction içinde olmalıdır.`);
  }
  if (/create table/i.test(sql) && !/enable row level security/i.test(sql)) {
    throw new Error(`${upFile} tablo oluşturuyor ancak RLS etkinleştirmiyor.`);
  }
}

console.log(`${upFiles.length} migration ve rollback çifti doğrulandı.`);
