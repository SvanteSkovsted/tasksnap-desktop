import "https://deno.land/x/xhr@0.1.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) throw new Error("OPENAI_API_KEY not configured");

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const { audio_base64, user_id, text } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let transcript = text as string | undefined;

    // 1. Transcribe with Whisper if audio provided
    if (!transcript && audio_base64) {
      const binary = Uint8Array.from(atob(audio_base64), (c) => c.charCodeAt(0));
      const form = new FormData();
      form.append("file", new Blob([binary], { type: "audio/webm" }), "audio.webm");
      form.append("model", "whisper-1");

      const wRes = await fetch("https://api.openai.com/v1/audio/transcriptions", {
        method: "POST",
        headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
        body: form,
      });
      if (!wRes.ok) {
        const err = await wRes.text();
        console.error("Whisper error:", err);
        throw new Error("Transcription failed");
      }
      const wJson = await wRes.json();
      transcript = wJson.text;
    }

    if (!transcript) {
      return new Response(JSON.stringify({ error: "No audio or text provided" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Extract structured task with GPT-4o
    const today = new Date().toISOString();
    const gRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: `You extract structured task data from natural speech. Today is ${today}. Infer due dates from phrases like "tomorrow", "next Monday", "in 2 hours". Always return valid JSON.`,
          },
          { role: "user", content: transcript },
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "create_task",
              description: "Create a structured task",
              parameters: {
                type: "object",
                properties: {
                  title: { type: "string", description: "Concise task title (max 100 chars)" },
                  description: { type: "string", description: "Optional details" },
                  priority: { type: "string", enum: ["urgent", "high", "medium", "low"] },
                  category: { type: "string", description: "e.g. Work, Personal, Errands" },
                  due_date: { type: "string", description: "ISO 8601 datetime or null", nullable: true },
                },
                required: ["title", "priority", "category"],
              },
            },
          },
        ],
        tool_choice: { type: "function", function: { name: "create_task" } },
      }),
    });

    if (!gRes.ok) {
      const err = await gRes.text();
      console.error("GPT error:", err);
      throw new Error("Task extraction failed");
    }
    const gJson = await gRes.json();
    const args = JSON.parse(gJson.choices[0].message.tool_calls[0].function.arguments);

    // 3. Save with service role
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);
    const { data, error } = await supabase
      .from("tasks")
      .insert({
        user_id,
        title: args.title,
        description: args.description ?? transcript,
        priority: args.priority,
        category: args.category,
        due_date: args.due_date || null,
        source: "voice",
      })
      .select()
      .single();

    if (error) throw error;

    return new Response(JSON.stringify({ task: data, transcript }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("capture-task error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unknown" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});