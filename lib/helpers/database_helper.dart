
// Mengimpor pustaka deteksi platform Flutter (untuk memeriksa peramban web kIsWeb)
import 'package:flutter/foundation.dart';

// Mengimpor pustaka inti SQLite untuk Flutter
import 'package:sqflite/sqflite.dart';

// Mengimpor pustaka penggabungan path direktori berkas lokal
import 'package:path/path.dart';

// Mengimpor implementasi SQLite FFI khusus peramban Web Google Chrome
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Mengimpor model data produk
import '../models/produk.dart';

// Kelas pengelola koneksi dan operasi basis data SQLite lokal SmartKasir
class DatabaseHelper {
  // --- 1. PENERAPAN DESIGN PATTERN SINGLETON ---

  // Deklarasi instansi statis tunggal kelas DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Variabel penampung objek koneksi database aktif
  static Database? _database;

  // Konstruktor privat
  DatabaseHelper._init();

  // --- 2. GETTER DATABASE ASINKRON ---

  // Mengembalikan koneksi database aktif
  Future<Database> get database async {
    // Jika objek database sudah ada, langsung kembalikan
    if (_database != null) return _database!;

    // Jika belum ada, inisialisasi database baru
    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // --- 3. INISIALISASI BERKAS DATABASE (CHROME & ANDROID) ---

  Future<Database> _initDB(String filePath) async {
    // Jika aplikasi berjalan di Google Chrome (Flutter Web)
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await openDatabase(
        filePath,
        version: 1,
        onCreate: _createDB,
      );
    }

    // Jika berjalan di smartphone Android
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // --- 4. PEMBUATAN STRUKTUR TABEL & DATA AWAL ---

  Future _createDB(Database db, int version) async {
    // Membuat tabel produk di database SQLite
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

    // Memasukkan data produk awal secara otomatis
    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }
  }

  // --- 5. CREATE: MENAMBAHKAN PRODUK BARU ---

  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;

    final id = await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // --- 6. READ: MENGAMBIL SELURUH DAFTAR PRODUK ---

  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      orderBy: 'harga_jual ASC',
    );

    // Mengubah hasil query menjadi daftar objek Produk
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 7. READ DENGAN FILTER KATEGORI ---

  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;

    // Jika kategori Semua, ambil seluruh data
    if (kategori == 'Semua') {
      return await getAllProduk();
    }

    // Mengambil produk berdasarkan kategori
    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 8. SEARCH: PENCARIAN PRODUK MENGGUNAKAN SQL LIKE ---

  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;

    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'id DESC',
    );

    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // --- 9. UPDATE: MEMPERBARUI DATA PRODUK ---

  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;

    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // --- 10. DELETE: MENGHAPUS DATA PRODUK ---

  Future<int> deleteProduk(int id) async {
    final db = await instance.database;

    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
