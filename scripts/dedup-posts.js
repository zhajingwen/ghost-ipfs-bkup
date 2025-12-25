#!/usr/bin/env node

/**
 * Ghost 文章去重脚本（超简化版）
 * 功能：删除标题重复的文章，保留 updated_at 最新的
 */

const Database = require('better-sqlite3');
const fs = require('fs');

// 数据库路径
const DB_PATH = process.env.GHOST_DB_PATH || '/var/lib/ghost/content/data/ghost.db';

function deduplicate() {
  // 检查数据库是否存在
  if (!fs.existsSync(DB_PATH)) {
    console.log('[INFO] Database not found, skipping deduplication');
    return;
  }

  let db;
  try {
    // 打开数据库
    db = new Database(DB_PATH);

    // 查找重复标题
    const duplicates = db.prepare(`
      SELECT title FROM posts
      GROUP BY title
      HAVING COUNT(*) > 1
    `).all();

    if (duplicates.length === 0) {
      console.log('[INFO] No duplicate posts found');
      return;
    }

    console.log(`[DEDUP] Found ${duplicates.length} duplicate titles`);

    // 在事务中执行删除
    const transaction = db.transaction(() => {
      let totalDeleted = 0;

      duplicates.forEach(({ title }) => {
        // 获取该标题的所有文章，按 updated_at 降序
        const posts = db.prepare(
          'SELECT id FROM posts WHERE title = ? ORDER BY updated_at DESC'
        ).all(title);

        // 保留第一个（最新），删除其他
        const idsToDelete = posts.slice(1).map(p => p.id);

        if (idsToDelete.length > 0) {
          const placeholders = idsToDelete.map(() => '?').join(',');
          const deleted = db.prepare(
            `DELETE FROM posts WHERE id IN (${placeholders})`
          ).run(...idsToDelete);

          totalDeleted += deleted.changes;
          console.log(`[DEDUP] "${title}": deleted ${deleted.changes} old version(s)`);
        }
      });

      console.log(`[DEDUP] Total deleted: ${totalDeleted} posts`);
    });

    // 执行事务
    transaction();

  } catch (error) {
    console.error('[ERROR] Deduplication failed:', error.message);
    process.exit(1);
  } finally {
    if (db) db.close();
  }
}

// 执行
deduplicate();
