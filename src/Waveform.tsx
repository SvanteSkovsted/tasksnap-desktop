import { useEffect, useRef } from "react";

interface WaveformProps {
  analyser: AnalyserNode | null;
  isRecording: boolean;
  isSending: boolean;
  width: number;
  height: number;
  barCount?: number;
}

export function Waveform({
  analyser,
  isRecording,
  isSending,
  width,
  height,
  barCount = 40,
}: WaveformProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animRef   = useRef<number>(0);
  const smoothed  = useRef(new Float32Array(barCount).fill(0.055));
  const phaseRef  = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx  = canvas.getContext("2d")!;
    const data = analyser ? new Uint8Array(analyser.frequencyBinCount) : null;
    const s    = smoothed.current;

    const draw = () => {
      phaseRef.current += 0.032;
      const phase = phaseRef.current;

      if (analyser && data && isRecording) {
        // ── Live audio ─────────────────────────────────────────────────
        analyser.getByteFrequencyData(data);
        for (let i = 0; i < barCount; i++) {
          // Focus on voice range (first ~55% of FFT bins).
          const bin = Math.floor((i / barCount) * data.length * 0.55);
          // 2.5× gain so quiet speech still creates visible movement.
          const raw = Math.min(1, (data[bin] / 255) * 2.5);
          // Mix coefficient: 0.55 old + 0.45 new — responsive but not jumpy.
          s[i] = s[i] * 0.55 + raw * 0.45;
        }
      } else if (isSending) {
        // ── AI-thinking wave: two counter-rotating sine sweeps ─────────
        for (let i = 0; i < barCount; i++) {
          const pos    = i / (barCount - 1);   // 0 → 1
          const wave1  = Math.sin(phase * 2.4  + pos * Math.PI * 3.2) * 0.28;
          const wave2  = Math.sin(phase * 1.35 + pos * Math.PI * 1.8) * 0.14;
          const target = Math.max(0.06, 0.48 + wave1 + wave2);
          // Faster tracking in sending mode for a lively animation.
          s[i] = s[i] * 0.60 + target * 0.40;
        }
      } else {
        // ── Idle: gentle organic undulation + subtle micro-noise ───────
        for (let i = 0; i < barCount; i++) {
          const base =
            Math.sin(phase + i * 0.28) * 0.030 +
            Math.sin(phase * 0.55 + i * 0.14) * 0.018 +
            0.050;
          // Tiny per-frame noise (±0.008) so bars never freeze completely.
          const micro  = (Math.random() - 0.5) * 0.016;
          const target = base + micro;
          s[i] = s[i] * 0.92 + target * 0.08;
        }
      }

      // ── Render ──────────────────────────────────────────────────────
      ctx.clearRect(0, 0, width, height);

      const grad = ctx.createLinearGradient(0, 0, 0, height);
      if (isRecording) {
        grad.addColorStop(0,    "rgba(210,128,86,0.97)");
        grad.addColorStop(0.45, "rgba(201,168,130,0.90)");
        grad.addColorStop(1,    "rgba(190,162,128,0.65)");
      } else if (isSending) {
        // Slightly brighter/warmer while "thinking"
        grad.addColorStop(0,    "rgba(205,152,104,0.90)");
        grad.addColorStop(0.5,  "rgba(194,160,124,0.82)");
        grad.addColorStop(1,    "rgba(182,158,128,0.60)");
      } else {
        grad.addColorStop(0, "rgba(186,168,144,0.38)");
        grad.addColorStop(1, "rgba(186,168,144,0.22)");
      }
      ctx.fillStyle = grad;

      const gap  = 2;
      const barW = (width - gap * (barCount - 1)) / barCount;
      const maxH = height - 6;

      for (let i = 0; i < barCount; i++) {
        const h = Math.max(3, s[i] * maxH);
        const x = i * (barW + gap);
        const y = (height - h) / 2;
        const r = Math.min(barW / 2, 1.8);

        ctx.beginPath();
        if (typeof ctx.roundRect === "function") {
          ctx.roundRect(x, y, barW, h, r);
        } else {
          ctx.rect(x, y, barW, h);
        }
        ctx.fill();
      }

      animRef.current = requestAnimationFrame(draw);
    };

    animRef.current = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(animRef.current);
  }, [analyser, isRecording, isSending, width, height, barCount]);

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      style={{ display: "block" }}
    />
  );
}
