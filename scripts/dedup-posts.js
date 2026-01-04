#!/usr/bin/env node

/**
 * Ghost 文章去重和黑名单清理脚本
 * 功能：
 * 1. 删除黑名单中的文章（如 "Coming soon"），一个都不保留
 * 2. 删除标题重复的文章，保留 updated_at 最新的
 */

const Database = require('better-sqlite3');
const fs = require('fs');

// 数据库路径
const DB_PATH = process.env.GHOST_DB_PATH || '/var/lib/ghost/content/data/ghost.db';

// 黑名单：需要完全删除的文章标题（一个都不保留）
const BLACKLIST_TITLES = [
  'Coming soon',
  'About this site',
  // 可根据需要添加其他默认文章
];

// Ghost 关联表列表（用于级联删除）
const RELATED_TABLES = [
  'posts_authors',
  'posts_tags',
  'posts_products',
  'posts_meta',
  'mobiledoc_revisions',
  'post_revisions',
  'collections_posts',
  'email_recipients',
  'email_batches',
  'members_click_events',
  'members_feedback'
];

/**
 * 删除黑名单中的文章（不保留任何一个）
 * @param {Database} db - SQLite 数据库实例
 * @returns {number} - 删除的文章数量
 */
function deleteBlacklistedPosts(db) {
  if (BLACKLIST_TITLES.length === 0) return 0;

  let totalDeleted = 0;

  BLACKLIST_TITLES.forEach(title => {
    // 查找该标题的所有文章
    const posts = db.prepare(
      'SELECT id FROM posts WHERE title = ?'
    ).all(title);

    if (posts.length > 0) {
      const idsToDelete = posts.map(p => p.id);
      const placeholders = idsToDelete.map(() => '?').join(',');

      // 1. 先删除所有关联表中的记录
      RELATED_TABLES.forEach(table => {
        try {
          const stmt = db.prepare(
            `DELETE FROM ${table} WHERE post_id IN (${placeholders})`
          );
          stmt.run(...idsToDelete);
        } catch (err) {
          // 忽略表不存在或没有 post_id 字段的错误
          if (!err.message.includes('no such table') && !err.message.includes('no such column')) {
            throw err;
          }
        }
      });

      // 2. 删除文章本身
      const deleted = db.prepare(
        `DELETE FROM posts WHERE id IN (${placeholders})`
      ).run(...idsToDelete);

      totalDeleted += deleted.changes;
      console.log(`[BLACKLIST] Deleted ${deleted.changes} posts with title "${title}"`);
    }
  });

  return totalDeleted;
}

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

    // 在事务中执行删除
    const transaction = db.transaction(() => {
      // 1. 先删除黑名单文章（一个都不保留）
      const blacklistedDeleted = deleteBlacklistedPosts(db);
      if (blacklistedDeleted > 0) {
        console.log(`[BLACKLIST] Total deleted: ${blacklistedDeleted} posts`);
      }

      // 2. 再执行去重逻辑（保留最新）
      if (duplicates.length === 0) {
        console.log('[INFO] No duplicate posts found');
        return;
      }

      console.log(`[DEDUP] Found ${duplicates.length} duplicate titles`);
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

          // 1. 先删除所有关联表中的记录
          RELATED_TABLES.forEach(table => {
            try {
              const stmt = db.prepare(
                `DELETE FROM ${table} WHERE post_id IN (${placeholders})`
              );
              const result = stmt.run(...idsToDelete);
              if (result.changes > 0) {
                console.log(`[DEDUP]   - Deleted ${result.changes} records from ${table}`);
              }
            } catch (err) {
              // 忽略表不存在或没有 post_id 字段的错误
              if (!err.message.includes('no such table') && !err.message.includes('no such column')) {
                throw err;
              }
            }
          });

          // 2. 最后删除文章本身
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
