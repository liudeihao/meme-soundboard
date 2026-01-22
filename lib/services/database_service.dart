import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/sound_item.dart';

/// 数据库服务 - 管理音效的本地存储
class DatabaseService {
  static Database? _database;
  static const String _tableName = 'sounds';
  static bool _initialized = false;

  /// 初始化数据库工厂 (在 Windows/Linux/macOS 上需要)
  static void initializeFfi() {
    if (_initialized) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    initializeFfi();
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(
      directory.path,
      'meme_soundboard',
      'meme_soundboard.db',
    );

    // 确保目录存在
    final dbDir = Directory(p.dirname(path));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            soundPath TEXT NOT NULL,
            imagePath TEXT,
            sourceType INTEGER DEFAULT 1,
            category TEXT DEFAULT '其他',
            isFavorite INTEGER DEFAULT 0,
            dominantColor INTEGER,
            createdAt INTEGER,
            advOverrideVolume INTEGER DEFAULT 0,
            advVolumeLevel REAL DEFAULT 1.0,
            advRestoreVolume INTEGER DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 迁移：添加新字段
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN sourceType INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN advOverrideVolume INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN advVolumeLevel REAL DEFAULT 1.0',
          );
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN advRestoreVolume INTEGER DEFAULT 1',
          );
          // 将旧的 isAsset 字段迁移到 sourceType
          await db.execute(
            'UPDATE $_tableName SET sourceType = 0 WHERE isAsset = 1',
          );
        }
      },
    );
  }

  /// 插入音效
  Future<void> insertSound(SoundItem sound) async {
    final db = await database;
    await db.insert(
      _tableName,
      sound.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有音效
  Future<List<SoundItem>> getAllSounds() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'createdAt DESC');
    return maps.map((map) => SoundItem.fromMap(map)).toList();
  }

  /// 搜索音效
  Future<List<SoundItem>> searchSounds(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => SoundItem.fromMap(map)).toList();
  }

  /// 获取收藏的音效
  Future<List<SoundItem>> getFavorites() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => SoundItem.fromMap(map)).toList();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除音效
  Future<void> deleteSound(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// 更新音效
  Future<void> updateSound(SoundItem sound) async {
    final db = await database;
    await db.update(
      _tableName,
      sound.toMap(),
      where: 'id = ?',
      whereArgs: [sound.id],
    );
  }

  /// 按分类获取音效
  Future<List<SoundItem>> getSoundsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => SoundItem.fromMap(map)).toList();
  }

  /// 迁移指定分类下的所有音效到新分类
  Future<void> migrateCategoryForSounds(
    String fromCategory,
    String toCategory,
  ) async {
    final db = await database;
    await db.update(
      _tableName,
      {'category': toCategory},
      where: 'category = ?',
      whereArgs: [fromCategory],
    );
  }

  /// 删除指定分类下的所有音效
  Future<void> deleteSoundsByCategory(String category) async {
    final db = await database;
    await db.delete(_tableName, where: 'category = ?', whereArgs: [category]);
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM $_tableName ORDER BY category',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  /// 清空所有音效数据（用于重置）
  Future<void> clearAllSounds() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
