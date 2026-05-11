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

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

    // Hent åbne, nylige opgaver så modellen kan vurdere om den skal opdatere en eksisterende
    const since = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
    const { data: existing } = await supabase
      .from("tasks")
      .select("id, title, summary, category, priority, due_date")
      .eq("user_id", user_id)
      .neq("status", "done")
      .gte("created_at", since)
      .order("created_at", { ascending: false })
      .limit(40);

    // Beregn nuværende tid i Europe/Copenhagen som ISO med korrekt offset
    const now = new Date();
    const cphParts = new Intl.DateTimeFormat("en-GB", {
      timeZone: "Europe/Copenhagen",
      year: "numeric", month: "2-digit", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false,
    }).formatToParts(now).reduce((acc: Record<string, string>, p) => {
      if (p.type !== "literal") acc[p.type] = p.value;
      return acc;
    }, {});
    // Find offset (fx +02:00 om sommeren, +01:00 om vinteren)
    const offsetMin = -new Date(now.toLocaleString("en-US", { timeZone: "Europe/Copenhagen" })).getTimezoneOffset();
    // Brug en mere pålidelig metode: udregn diff mellem cph-vægur og UTC
    const cphAsUtc = Date.UTC(+cphParts.year, +cphParts.month - 1, +cphParts.day, +cphParts.hour, +cphParts.minute, +cphParts.second);
    const offsetMinutes = Math.round((cphAsUtc - now.getTime()) / 60000);
    const sign = offsetMinutes >= 0 ? "+" : "-";
    const abs = Math.abs(offsetMinutes);
    const offsetStr = `${sign}${String(Math.floor(abs / 60)).padStart(2, "0")}:${String(abs % 60).padStart(2, "0")}`;
    const todayLocal = `${cphParts.year}-${cphParts.month}-${cphParts.day}T${cphParts.hour}:${cphParts.minute}:${cphParts.second}${offsetStr}`;

    const systemPrompt = `Du er en dansktalende assistent for en dansk bruger. Du konverterer en talt eller skriftlig note til en struktureret opgave til brugeren selv. Nuværende tid er ${todayLocal} (Europe/Copenhagen, offset ${offsetStr}).

REGLER:
- Skriv ALTID på dansk. Brug danske ord og dansk stavemåde. Brug kun engelske ord hvis du er helt sikker på at brugeren brugte dem som egennavne (fx produktnavne, firmanavne) — ellers oversæt til dansk.
- Noten er brugerens egne tanker til sig selv. Skriv derfor i ANDEN person ("du") eller som en direkte handling ("Ring til…", "Husk at…"). Skriv ALDRIG i tredje person ("brugeren skal…", "han skal…").
- "title" skal være et kort, præcist emne på 3-7 ord — IKKE en hel sætning.
- "transcript" skal være en RENSET, læsevenlig version af det brugeren sagde — IKKE en ordret transskription.
   * Fjern fyldord og tøven: "øh", "øhm", "altså", "ikke", "ligesom", "sådan", gentagelser, falske starter.
   * Anvend selvkorrektioner: hvis brugeren siger "nej, jeg mener…", "altså, det skulle være…", "rettelse…" eller på anden måde fortryder, så brug KUN den endelige version og smid det fortrudte væk.
   * Behold brugerens egen stemme, ordvalg og betydning — omskriv ikke unødigt. Ret kun grammatik og tegnsætning så det bliver flydende.
   * Skriv det som hele, velformede sætninger i FØRSTE person ("jeg skal…") — det er brugerens egne ord.
- "summary" skal være et 1-2 sætningers resume af hvad der skal gøres, skrevet direkte til brugeren i ANDEN person ("du skal…") eller som imperativ ("Ring til…", "Forbered…"). ALDRIG "brugeren skal".
- Udled forfaldsdato fra naturligt sprog ("i morgen kl 15", "næste mandag", "om 2 timer"). Tider brugeren nævner er ALTID lokal dansk tid (Europe/Copenhagen). Returnér som ISO 8601 MED det korrekte offset for Europe/Copenhagen (${offsetStr}) — fx "2026-05-12T20:00:00${offsetStr}". Brug ALDRIG "Z" eller UTC.
- Sæt prioritet ud fra hastværk i stemmen/teksten.

DUPLIKATER OG OPDATERING:
Hvis noten klart vedrører en EKSISTERENDE opgave på listen nedenfor (samme emne, samme person/projekt, eller en tilføjelse/ændring til den), så vælg action="update" og angiv "existing_task_id" + de felter der skal opdateres. Vær konservativ — kun hvis det er åbenlyst samme opgave.
Ellers vælg action="create".

EKSISTERENDE ÅBNE OPGAVER:
${JSON.stringify(existing ?? [], null, 2)}

Kald ALTID upsert_task værktøjet.`;

    const userContent: any[] = [];
    if (text) userContent.push({ type: "text", text });
    if (audio_base64) {
      userContent.push({ type: "text", text: "Transskribér denne stemmenote og udled en struktureret opgave på dansk." });
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
            name: "upsert_task",
            description: "Opret en ny opgave eller opdatér en eksisterende baseret på note.",
            parameters: {
              type: "object",
              properties: {
                action: { type: "string", enum: ["create", "update"] },
                existing_task_id: { type: "string", description: "Kun ved action=update" },
                title: { type: "string", description: "Kort emne 3-7 ord på dansk" },
                summary: { type: "string", description: "1-2 sætningers resume på dansk" },
                transcript: { type: "string", description: "Renset, læsevenlig version af noten — uden fyldord, med selvkorrektioner anvendt" },
                priority: { type: "string", enum: ["urgent", "high", "medium", "low"] },
                category: { type: "string", description: "fx Arbejde, Privat, Ærinder, Sundhed" },
                due_date: { type: "string", description: "ISO 8601 datotid eller tom streng" },
              },
              required: ["action", "title", "summary", "transcript", "priority", "category"],
              additionalProperties: false,
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "upsert_task" } },
      }),
    });

    if (!aiRes.ok) {
      const errTxt = await aiRes.text();
      console.error("Lovable AI error:", aiRes.status, errTxt);
      if (aiRes.status === 429) {
        return new Response(JSON.stringify({ error: "Rate limit nået, prøv igen om lidt." }), {
          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (aiRes.status === 402) {
        return new Response(JSON.stringify({ error: "AI-credits opbrugt. Tilføj kredit i Lovable workspace settings." }), {
          status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      throw new Error("AI extraction failed");
    }

    const aiJson = await aiRes.json();
    const toolCall = aiJson.choices?.[0]?.message?.tool_calls?.[0];
    if (!toolCall) throw new Error("Model did not return a tool call");
    const args = JSON.parse(toolCall.function.arguments);

    const dueIso = args.due_date && args.due_date.length > 0 ? args.due_date : null;
    const transcript = args.transcript ?? text ?? null;

    if (args.action === "update" && args.existing_task_id) {
      const { data, error } = await supabase
        .from("tasks")
        .update({
          title: args.title,
          summary: args.summary ?? null,
          transcript,
          priority: args.priority,
          category: args.category,
          due_date: dueIso,
        })
        .eq("id", args.existing_task_id)
        .eq("user_id", user_id)
        .select()
        .single();
      if (error) throw error;
      return new Response(JSON.stringify({ task: data, action: "updated" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data, error } = await supabase
      .from("tasks")
      .insert({
        user_id,
        title: args.title,
        summary: args.summary ?? null,
        transcript,
        description: null,
        priority: args.priority,
        category: args.category,
        due_date: dueIso,
        source: audio_base64 ? "voice" : "text",
      })
      .select()
      .single();
    if (error) throw error;

    return new Response(JSON.stringify({ task: data, action: "created" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("capture-task error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unknown" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
