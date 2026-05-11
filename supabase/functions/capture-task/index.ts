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
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY not configured");

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const { audio_base64, user_id, text, mime_type } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!audio_base64 && !text) {
      return new Response(JSON.stringify({ error: "audio_base64 or text required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const today = new Date().toISOString();
    const systemPrompt = `You extract structured task data from a user's spoken or written note. Today is ${today}. Infer due dates from natural phrases ("tomorrow 3pm", "next Monday", "in 2 hours") and return them as ISO 8601. Pick a single concise title (<100 chars). Always call the create_task tool.`;

    // Build the user message: Gemini accepts inline audio via input_audio
    const userContent: any[] = [];
    if (text) {
      userContent.push({ type: "text", text });
    }
    if (audio_base64) {
      userContent.push({ type: "text", text: "Transcribe this audio note and extract a structured task." });
      userContent.push({
        type: "input_audio",
        input_audio: { data: audio_base64, format: (mime_type?.includes("wav") ? "wav" : "webm") },
      });
    }

    const aiRes = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
        tools: [{
          type: "function",
          function: {
            name: "create_task",
            description: "Create a structured task from the user's note.",
            parameters: {
              type: "object",
              properties: {
                title: { type: "string", description: "Concise task title (<100 chars)" },
                description: { type: "string", description: "Optional details, or full transcript" },
                priority: { type: "string", enum: ["urgent", "high", "medium", "low"] },
                category: { type: "string", description: "e.g. Work, Personal, Errands, Health" },
                due_date: { type: "string", description: "ISO 8601 datetime, or empty string" },
              },
              required: ["title", "priority", "category"],
              additionalProperties: false,
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "create_task" } },
      }),
    });

    if (!aiRes.ok) {
      const errTxt = await aiRes.text();
      console.error("Lovable AI error:", aiRes.status, errTxt);
      if (aiRes.status === 429) {
        return new Response(JSON.stringify({ error: "Rate limit reached, please try again shortly." }), {
          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (aiRes.status === 402) {
        return new Response(JSON.stringify({ error: "AI credits exhausted. Add funds in Lovable workspace settings." }), {
          status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      throw new Error("AI extraction failed");
    }

    const aiJson = await aiRes.json();
    const toolCall = aiJson.choices?.[0]?.message?.tool_calls?.[0];
    if (!toolCall) throw new Error("Model did not return a tool call");
    const args = JSON.parse(toolCall.function.arguments);

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);
    const { data, error } = await supabase
      .from("tasks")
      .insert({
        user_id,
        title: args.title,
        description: args.description ?? text ?? null,
        priority: args.priority,
        category: args.category,
        due_date: args.due_date && args.due_date.length > 0 ? args.due_date : null,
        source: audio_base64 ? "voice" : "text",
      })
      .select()
      .single();

    if (error) throw error;

    return new Response(JSON.stringify({ task: data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("capture-task error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unknown" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
