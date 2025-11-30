import 'dart:async';
import 'package:aura_bluetooth/utils/storage_helper.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/firebase_options.dart'; 

const String taskSyncData = "com.aura.syncHeartRate";

// --- CALLBACK DISPATCHER (Background Isolate) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("👷 [Workmanager] Executing task: $task");

    if (task == taskSyncData) {
      try {
        // 1. Init Firebase (Wajib di isolate baru)
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // 2. Init StorageService (Wajib di isolate baru untuk buka Hive Box)
        final storage = StorageService();
        await storage.init(); 

        // 3. Ambil Data Pending menggunakan helper class Anda
        final pendingData = storage.getUnsyncedData();

        if (pendingData.isEmpty) {
          print("👷 [Workmanager] Queue empty. Nothing to sync.");
          return Future.value(true);
        }

        print("👷 [Workmanager] Found ${pendingData.length} items to sync...");

        final firestoreService = FirestoreService();
        final List<String> successKeys = []; // Tampung key yang berhasil

        // 4. Loop Upload
        for (var item in pendingData) {
          try {
            // Upload ke Firestore
            // Asumsi: Anda punya logic untuk mendapatkan userId, atau hardcode untuk BG
            await firestoreService.syncHeartRateData(item, userId: "BG_USER");
            
            // Jika sukses, simpan key-nya untuk dihapus nanti
            // Logic key harus sama persis dengan di StorageService: timestamp millis string
            final key = item.timestamp.millisecondsSinceEpoch.toString();
            successKeys.add(key);
            
            print("👷 [Workmanager] Synced item: ${item.bpm} BPM");
          } catch (e) {
            print("👷 [Workmanager] Failed to sync item time=${item.timestamp}: $e");
            // Jangan masukkan ke successKeys, biarkan di antrian untuk coba lagi nanti
          }
        }

        // 5. Hapus data yang berhasil terupload dari Sync Queue
        if (successKeys.isNotEmpty) {
          await storage.clearSyncedData(successKeys);
          print("👷 [Workmanager] Cleared ${successKeys.length} items from sync queue.");
        }

        print("👷 [Workmanager] Sync Job Done.");
        
      } catch (e, stack) {
        print("👷 [Workmanager] Critical Error: $e");
        print(stack);
        return Future.value(false); // Return false agar Workmanager me-retry nanti
      }
    }

    return Future.value(true);
  });
}

// --- SERVICE CLASS (Untuk UI/Main App) ---
class WorkmanagerService {
  final Workmanager _workmanager = Workmanager();

  // Inisialisasi awal di main.dart
  Future<void> initialize() async {
    await _workmanager.initialize(
      callbackDispatcher,
      isInDebugMode: true, // Ubah ke false saat rilis production
    );
    print("👷 [WorkmanagerService] Initialized");
  }

  // Daftarkan tugas periodik (15 menit sekali)
  Future<void> registerPeriodicTask() async {
    await _workmanager.registerPeriodicTask(
      "periodic_sync_task", // Unique name
      taskSyncData, 
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected, // Wajib ada internet
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep, // Jangan timpa jadwal jika sudah ada
      backoffPolicy: BackoffPolicy.linear,
    );
    print("👷 [WorkmanagerService] Periodic Task Registered");
  }

  // Trigger manual (berguna untuk tombol "Sync Now" di settings)
  Future<void> triggerOneOffSync() async {
    await _workmanager.registerOneOffTask(
      "one_off_sync_${DateTime.now().millisecondsSinceEpoch}",
      taskSyncData,
      constraints: Constraints(networkType: NetworkType.connected),
    );
    print("👷 [WorkmanagerService] One-off Sync Triggered");
  }
}