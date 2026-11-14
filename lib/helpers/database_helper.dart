
// Mengimpor pustaka deteksi platform Flutter
import 'package:flutter/foundation.dart';

// Mengimpor pustaka inti SQLite
import 'package:sqflite/sqflite.dart';

// Mengimpor pustaka penggabungan path
import 'package:path/path.dart';

// Mengimpor SQLite FFI
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mengimpor SQLite FFI khusus Web
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Mengimpor model data Produk dan Karyawan
import '../models/produk.dart';
import '../models/karyawan.dart';

// Kelas pengelola database SmartKasir
class DatabaseHelper {
  // 1. SINGLETON
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 2. GETTER DATABASE
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // 3. INISIALISASI DATABASE
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _onUpgradeDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    }
  }

  // 4. MEMBUAT TABEL DATABASE BARU
  Future _createDB(Database db, int version) async {
    // Membuat tabel produk
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Memasukkan data produk awal
    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }

    // Membuat tabel karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // Memasukkan data karyawan awal
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '1234', 'Kasir')
    ''');

    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '8888', 'Manajer')
    ''');
  }

  // 5. MIGRASI DATABASE VERSI LAMA
  Future _onUpgradeDB(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Membuat tabel karyawan untuk database lama
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      // Memasukkan staf awal
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Ahmad Kasir', '1234', 'Kasir')
      ''');
    }
  }

  // ==========================================
  // CRUD TABEL KARYAWAN
  // ==========================================

  // 6. CREATE: Menambahkan karyawan
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;

    return await db.insert(
      'karyawan',
      karyawan.toMap(),
    );
  }

  // 7. READ: Mengambil seluruh karyawan
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;

    final result = await db.query(
      'karyawan',
      orderBy: 'id ASC',
    );

    return result
        .map((json) => Karyawan.fromMap(json))
        .toList();
  }

  // 8. UPDATE: Memperbarui data karyawan
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;

    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // 9. DELETE: Menghapus karyawan
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;

    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // CRUD TABEL PRODUK
  // ==========================================

  // 10. CREATE: Menambahkan produk
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;

    final id = await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // 11. READ: Mengambil seluruh produk
  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      orderBy: 'harga_jual ASC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // 12. READ: Filter berdasarkan kategori
  Future<List<Produk>> getProdukByKategori(
      String kategori) async {
    final db = await instance.database;

    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // 13. SEARCH: Mencari produk
  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );

    return result
        .map((json) => Produk.fromMap(json))
        .toList();
  }

  // 14. UPDATE: Memperbarui produk
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // 15. DELETE: Menghapus produk
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
