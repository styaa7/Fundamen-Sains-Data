import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface BookingRequest {
  lecturer_id: string;
  scheduled_start: string;
  scheduled_end: string;
  agenda: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Client with user auth context
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Sesi pengguna tidak valid" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: BookingRequest = await req.json();
    const { lecturer_id, scheduled_start, scheduled_end, agenda } = body;

    // 1. Validasi field
    if (!lecturer_id || !scheduled_start || !scheduled_end || !agenda) {
      return new Response(JSON.stringify({ error: "Semua data form wajib diisi." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const startDate = new Date(scheduled_start);
    const endDate = new Date(scheduled_end);
    const now = new Date();

    if (startDate < now) {
      return new Response(JSON.stringify({ error: "Waktu konsultasi tidak boleh berada di masa lalu." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (endDate <= startDate) {
      return new Response(JSON.stringify({ error: "Jam selesai harus lebih besar dari jam mulai." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const durationMinutes = (endDate.getTime() - startDate.getTime()) / (1000 * 60);
    if (durationMinutes < 15 || durationMinutes > 120) {
      return new Response(JSON.stringify({ error: "Durasi bimbingan harus antara 15 hingga 120 menit." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Gunakan Service Role Client untuk pengecekan konflik jadwal dosen secara akurat
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Cek irisan jadwal: start1 < end2 AND end1 > start2
    const { data: conflicts, error: conflictError } = await adminClient
      .from("consultations")
      .select("id, scheduled_start, scheduled_end, status")
      .eq("lecturer_id", lecturer_id)
      .in("status", ["CONFIRMED", "REQUESTED"])
      .lt("scheduled_start", scheduled_end)
      .gt("scheduled_end", scheduled_start);

    if (conflictError) {
      throw conflictError;
    }

    if (conflicts && conflicts.length > 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "JADWAL_BENTROK",
          message: "Dosen telah memiliki agenda bimbingan pada rentang jam tersebut. Silakan pilih waktu lain.",
        }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Masukkan record konsultasi baru
    const { data: newConsultation, error: insertError } = await adminClient
      .from("consultations")
      .insert({
        student_id: user.id,
        lecturer_id,
        scheduled_start,
        scheduled_end,
        agenda,
        status: "REQUESTED",
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    // 4. Kirim notifikasi ke dosen
    const { data: studentProfile } = await adminClient
      .from("profiles")
      .select("full_name")
      .eq("id", user.id)
      .single();

    const studentName = studentProfile?.full_name ?? "Mahasiswa";

    await adminClient.from("notifications").insert({
      user_id: lecturer_id,
      title: "Permintaan Konsultasi Baru",
      message: `${studentName} mengajukan bimbingan untuk agenda: "${agenda.substring(0, 50)}..."`,
      type: "consultation",
      reference_id: newConsultation.id,
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "Permintaan jadwal bimbingan berhasil diajukan.",
        data: newConsultation,
      }),
      {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Terjadi kesalahan internal server" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
