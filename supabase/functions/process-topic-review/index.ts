import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ReviewRequest {
  topic_id: string;
  action: "APPROVED" | "REVISION" | "REJECTED";
  feedback?: string;
}

const DEFAULT_STAGES = [
  { order: 1, name: "Pengajuan Topik" },
  { order: 2, name: "Proposal Skripsi" },
  { order: 3, name: "Seminar Proposal" },
  { order: 4, name: "Pengumpulan Data" },
  { order: 5, name: "Analisis Data" },
  { order: 6, name: "Penyusunan Naskah Skripsi" },
  { order: 7, name: "Seminar Hasil" },
  { order: 8, name: "Sidang Akhir Skripsi" },
];

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

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Sesi pengguna tidak valid" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: ReviewRequest = await req.json();
    const { topic_id, action, feedback } = body;

    if (!topic_id || !["APPROVED", "REVISION", "REJECTED"].includes(action)) {
      return new Response(JSON.stringify({ error: "Aksi review tidak valid." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Ambil data submission
    const { data: submission, error: subError } = await adminClient
      .from("topic_submissions")
      .select("*")
      .eq("id", topic_id)
      .single();

    if (subError || !submission) {
      return new Response(JSON.stringify({ error: "Data pengajuan topik tidak ditemukan." }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Update topic_submissions
    const updatePayload: Record<string, any> = {
      status: action,
      lecturer_feedback: feedback ?? null,
      reviewed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (action === "REVISION") {
      updatePayload.revision_count = (submission.revision_count || 0) + 1;
    }

    const { error: updateSubError } = await adminClient
      .from("topic_submissions")
      .update(updatePayload)
      .eq("id", topic_id);

    if (updateSubError) throw updateSubError;

    // 2. Jika APPROVED: Buat thesis dan seed 8 progress stages
    if (action === "APPROVED") {
      // Periksa apakah thesis sudah ada sebelumnya
      const { data: existingThesis } = await adminClient
        .from("theses")
        .select("id")
        .eq("student_id", submission.student_id)
        .maybeSingle();

      let thesisId = existingThesis?.id;

      if (!thesisId) {
        const { data: newThesis, error: thesisError } = await adminClient
          .from("theses")
          .insert({
            student_id: submission.student_id,
            lecturer_id: submission.lecturer_id ?? user.id,
            topic_submission_id: topic_id,
            title: submission.title,
            current_stage_order: 2, // Lanjut ke Tahap 2: Proposal
            overall_progress_percentage: 12.50,
          })
          .select()
          .single();

        if (thesisError) throw thesisError;
        thesisId = newThesis.id;

        // Seed 8 tahapan
        const stagesToInsert = DEFAULT_STAGES.map((stg) => {
          if (stg.order === 1) {
            return {
              thesis_id: thesisId,
              stage_order: stg.order,
              stage_name: stg.name,
              status: "COMPLETED",
              progress_percentage: 100.0,
              completed_date: new Date().toISOString().split("T")[0],
            };
          } else if (stg.order === 2) {
            return {
              thesis_id: thesisId,
              stage_order: stg.order,
              stage_name: stg.name,
              status: "IN_PROGRESS",
              progress_percentage: 0.0,
              start_date: new Date().toISOString().split("T")[0],
            };
          } else {
            return {
              thesis_id: thesisId,
              stage_order: stg.order,
              stage_name: stg.name,
              status: "NOT_STARTED",
              progress_percentage: 0.0,
            };
          }
        });

        const { error: seedError } = await adminClient
          .from("thesis_progress")
          .insert(stagesToInsert);

        if (seedError) throw seedError;
      }
    }

    // 3. Buat notifikasi untuk mahasiswa
    let notifTitle = "Review Pengajuan Topik";
    let notifMessage = "Dosen telah mereview pengajuan topik skripsi Anda.";

    if (action === "APPROVED") {
      notifTitle = "Topik Skripsi Disetujui! 🎉";
      notifMessage = `Pengajuan topik "${submission.title}" telah disetujui. Tahapan penyusunan proposal kini aktif.`;
    } else if (action === "REVISION") {
      notifTitle = "Revisi Pengajuan Topik";
      notifMessage = `Dosen pembimbing meminta revisi pada pengajuan topik "${submission.title}". Catatan: ${feedback ?? "-"}`;
    } else if (action === "REJECTED") {
      notifTitle = "Pengajuan Topik Ditolak";
      notifMessage = `Pengajuan topik "${submission.title}" tidak disetujui. Alasan: ${feedback ?? "-"}`;
    }

    await adminClient.from("notifications").insert({
      user_id: submission.student_id,
      title: notifTitle,
      message: notifMessage,
      type: "topic",
      reference_id: topic_id,
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: `Status pengajuan berhasil diubah menjadi ${action}.`,
        status: action,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Terjadi kesalahan internal" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
