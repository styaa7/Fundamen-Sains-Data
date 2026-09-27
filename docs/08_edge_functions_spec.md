# SkripsiFlow — Supabase Edge Functions Specification

Dokumen ini mendefinisikan spesifikasi API, logika bisnis server-side, validasi keamanan, dan struktur payload untuk **Supabase Edge Functions** (Deno/TypeScript).

---

## 1. Edge Function: `book-consultation`

### Tujuan:
Memastikan validasi pencegahan jadwal bentrok (*conflict prevention*) dilakukan secara atomic di server, menghindari *race condition* ketika dua mahasiswa memesan slot dosen pada waktu yang beririsan.

### Endpoint:
`POST /functions/v1/book-consultation`  
**Headers**: `Authorization: Bearer <USER_JWT>`

### Request Body:
```json
{
  "lecturer_id": "8f1a23c4-1234-4567-89ab-cdef01234567",
  "scheduled_start": "2026-10-01T09:00:00Z",
  "scheduled_end": "2026-10-01T10:00:00Z",
  "agenda": "Review Bab 3 Metodologi Penelitian dan Instrumen Kuisioner"
}
```

### Business Logic:
1. Validasi token JWT dan ambil `student_id` dari auth user.
2. Validasi format waktu: `scheduled_start >= NOW()` dan durasi antara 15 hingga 120 menit.
3. Eksekusi pengecekan overlap di database:
   ```sql
   SELECT id FROM public.consultations
   WHERE lecturer_id = $lecturer_id
     AND status IN ('CONFIRMED', 'REQUESTED')
     AND (scheduled_start, scheduled_end) OVERLAPS ($scheduled_start, $scheduled_end);
   ```
4. Jika ditemukan overlap $\to$ Return **HTTP 409 Conflict**:
   ```json
   {
     "success": false,
     "error": "JADWAL_BENTROK",
     "message": "Dosen telah memiliki agenda bimbingan pada rentang waktu tersebut. Silakan pilih waktu lain."
   }
   ```
5. Jika slot tersedia $\to$ Insert `consultations` status `REQUESTED`.
6. Buat record notifikasi untuk dosen yang bersangkutan.
7. Return **HTTP 201 Created**:
   ```json
   {
     "success": true,
     "data": {
       "consultation_id": "uuid",
       "status": "REQUESTED"
     }
   }
   ```

---

## 2. Edge Function: `process-topic-review`

### Tujuan:
Menangani aksi review dosen terhadap pengajuan topik (Setujui, Minta Revisi, Tolak) dan mengotomasi pembentukan record skripsi serta inisialisasi 8 tahapan progres.

### Endpoint:
`POST /functions/v1/process-topic-review`  
**Headers**: `Authorization: Bearer <USER_JWT>`

### Request Body:
```json
{
  "topic_id": "b3c2a100-5678-4321-abcd-ef0123456789",
  "action": "APPROVED", // 'APPROVED' | 'REVISION' | 'REJECTED'
  "feedback": "Topik sangat relevan dan memiliki urgensi penelitian yang kuat. Silakan lanjut ke Proposal."
}
```

### Business Logic:
1. Pastikan pemanggil adalah Dosen yang ditugaskan pada topik tersebut (atau Admin).
2. Update tabel `topic_submissions`:
   - Set `status = action`
   - Set `lecturer_feedback = feedback`
   - Set `reviewed_at = NOW()`
   - Jika `action == 'REVISION'`, increment `revision_count += 1`.
3. **Jika `action == 'APPROVED'` (Side-effect Otomatisasi)**:
   - Insert ke tabel `theses` dengan `overall_progress_percentage = 12.50`.
   - Insert 8 entri ke tabel `thesis_progress`:
     - Tahap 1: *Pengajuan Topik* $\to$ `status = 'COMPLETED'`, `progress = 100%`, `completed_date = TODAY`.
     - Tahap 2: *Proposal Skripsi* $\to$ `status = 'IN_PROGRESS'`, `progress = 0%`.
     - Tahap 3 s/d 8: $\to$ `status = 'NOT_STARTED'`, `progress = 0%`.
4. Buat record notifikasi untuk mahasiswa bersangkutan.
5. Return **HTTP 200 OK**:
   ```json
   {
     "success": true,
     "message": "Review topik berhasil diproses.",
     "data": { "status": "APPROVED" }
   }
   ```

---

## 3. Edge Function: `send-notification`

### Tujuan:
Mengirimkan notifikasi tersentralisasi yang dapat dihubungkan ke Realtime channel atau Push Notification.

### Request Body:
```json
{
  "user_id": "uuid",
  "title": "Jadwal Konsultasi Disetujui",
  "message": "Dosen telah mengonfirmasi jadwal konsultasi Anda pada 28 September 2026, 10:00 WIB.",
  "type": "consultation",
  "reference_id": "uuid"
}
```
