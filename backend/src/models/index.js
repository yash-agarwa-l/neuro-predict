import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import Sequelize from 'sequelize';
import sequelize from '../db/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const db = {};


async function loadModels(directory) {
  const entries = fs.readdirSync(directory, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(directory, entry.name);

    if (entry.isDirectory()) {

      await loadModels(fullPath);
    } else if (entry.name.endsWith('.js') && entry.name !== 'index.js') {
      try {
        const module = await import(fullPath);
        if (typeof module.default !== 'function') {
          console.error(`Error: Model file ${entry.name} does not export a default function`);
          continue;
        }
        const model = module.default(sequelize);
        db[model.name] = model;
      } catch (error) {
        console.error(`Error loading model ${entry.name}:`, error);
      }
    }
  }
}

await loadModels(__dirname);


Object.keys(db).forEach(modelName => {
  if (typeof db[modelName].associate === 'function') {
    db[modelName].associate(db);
  }
});

db.sequelize = sequelize;
db.Sequelize = Sequelize;

export default db;
