// Figure Out Your Type — web version. Mirrors Sources/TypeCore in the Mac app.
"use strict";

const MODEL = "claude-opus-5-5";
const MAX_PIXEL_SIZE = 1568;
const KEY_STORAGE = "figureOutYourType.apiKey";
const FEEDBACK_URL = "https://github.com/amalmehta/FigureOutYourType/issues/new";

const SYSTEM_PROMPT = `You help someone understand their dating "type". They will show you photos of people they're attracted to, sometimes with a short note about each person. Find the patterns across all of them and describe the type along four dimensions: physical, emotional, spiritual, and style & lifestyle.

Guidelines:
- Look for what the people have in common. A trait only counts as part of the type if it shows up across several people; say how many when it helps. Name anyone who breaks the pattern in "outliers".
- Physical: describe only what is visible — hair, build, height cues, facial hair, grooming, expression, apparent age range, how they carry themselves. Never name or guess race, ethnicity, religion, sexual orientation, health or disability.
- Emotional and spiritual: base these mainly on the user's notes. Without notes you can only read surface cues (expression, setting, activity, the energy a photo gives off) — say so and mark those traits low confidence.
- Style & lifestyle: clothing, aesthetic, settings, hobbies or activities visible in the photos or notes.
- Refer to people as "Person 1", "Person 2", etc. Don't try to identify anyone.
- Write warmly and directly to the user ("you're drawn to…"). Keep each detail to one or two sentences.
- "headline" is a short, vivid phrase that sums up the type. "caveats" says plainly what photos can't tell you and how much to trust this read.`;

const SECTION_SCHEMA = {
  type: "object",
  properties: {
    summary: { type: "string" },
    traits: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          detail: { type: "string" },
          confidence: { type: "string", enum: ["low", "medium", "high"] },
        },
        required: ["name", "detail", "confidence"],
        additionalProperties: false,
      },
    },
  },
  required: ["summary", "traits"],
  additionalProperties: false,
};

const REPORT_SCHEMA = {
  type: "object",
  properties: {
    headline: { type: "string" },
    summary: { type: "string" },
    physical: SECTION_SCHEMA,
    emotional: SECTION_SCHEMA,
    spiritual: SECTION_SCHEMA,
    lifestyle: SECTION_SCHEMA,
    commonThreads: { type: "array", items: { type: "string" } },
    outliers: { type: "array", items: { type: "string" } },
    caveats: { type: "string" },
  },
  required: ["headline", "summary", "physical", "emotional", "spiritual", "lifestyle", "commonThreads", "outliers", "caveats"],
  additionalProperties: false,
};

// ---------- State ----------

/** @type {{id: string, note: string, photos: {id: string, dataUrl: string}[]}[]} */
let people = [];
let report = null;
let sessionKey = null; // used when "remember" is off
const uid = () => Math.random().toString(36).slice(2);
const $ = (id) => document.getElementById(id);

// ---------- Key storage (localStorage can throw or be empty) ----------

function loadKey() {
  if (sessionKey) return sessionKey;
  try { return localStorage.getItem(KEY_STORAGE) || null; } catch { return null; }
}
function saveKey(key, remember) {
  sessionKey = remember ? null : key;
  try {
    if (remember && key) localStorage.setItem(KEY_STORAGE, key);
    else localStorage.removeItem(KEY_STORAGE);
  } catch { sessionKey = key; }
}

// ---------- Images ----------

/** Downscales any browser-readable image to an upright JPEG data URL. */
async function prepareImage(blob) {
  const bitmap = await createImageBitmap(blob, { imageOrientation: "from-image" });
  const scale = Math.min(1, MAX_PIXEL_SIZE / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return canvas.toDataURL("image/jpeg", 0.85);
}

async function addImages(blobs, personId = null) {
  const images = blobs.filter((b) => b && b.type.startsWith("image/"));
  if (!images.length) return;
  const prepared = [];
  for (const blob of images) {
    try { prepared.push(await prepareImage(blob)); } catch { /* skipped below */ }
  }
  if (prepared.length < blobs.length) showError("Some files couldn't be read as images and were skipped.");
  const photos = prepared.map((dataUrl) => ({ id: uid(), dataUrl }));
  const target = personId && people.find((p) => p.id === personId);
  if (target) target.photos.push(...photos);
  else people.push(...photos.map((photo) => ({ id: uid(), note: "", photos: [photo] })));
  render();
}

// ---------- Claude ----------

function buildRequestBody() {
  const withPhotos = people.filter((p) => p.photos.length);
  if (!withPhotos.length) throw new Error("Add at least one photo first.");
  const content = [];
  withPhotos.forEach((person, index) => {
    const note = person.note.trim();
    const count = person.photos.length;
    content.push({
      type: "text",
      text: `Person ${index + 1} (${count} ${count === 1 ? "photo" : "photos"})` + (note ? ` — the user's note: ${note}` : " — no note."),
    });
    for (const photo of person.photos) {
      content.push({
        type: "image",
        source: { type: "base64", media_type: "image/jpeg", data: photo.dataUrl.split(",")[1] },
      });
    }
  });
  content.push({ type: "text", text: "What's my type?" });
  return {
    model: MODEL,
    max_tokens: 16000,
    system: SYSTEM_PROMPT,
    fallbacks: "default",
    output_config: { effort: "high", format: { type: "json_schema", schema: REPORT_SCHEMA } },
    messages: [{ role: "user", content }],
  };
}

async function analyze(apiKey) {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
      "anthropic-beta": "server-side-fallback-2026-07-01",
      "anthropic-dangerous-direct-browser-access": "true",
    },
    body: JSON.stringify(buildRequestBody()),
  });
  const json = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(`Claude returned an error (${response.status}): ${json?.error?.message ?? "Unknown error"}`);
  }
  if (json?.stop_reason === "refusal") {
    throw new Error(`Claude declined to analyze these photos. ${json.stop_details?.explanation ?? ""}`);
  }
  if (json?.stop_reason === "max_tokens") {
    throw new Error("The answer was cut off before it finished. Try again with fewer photos.");
  }
  const text = [...(json?.content ?? [])].reverse().find((b) => b.type === "text")?.text;
  try { return JSON.parse(text); } catch { throw new Error("Claude's answer couldn't be read. Try again."); }
}

async function figureOutType() {
  const key = loadKey();
  if (!key) { openSettings("Add your Anthropic API key first."); return; }
  const photoCount = people.reduce((n, p) => n + p.photos.length, 0);
  $("busyText").textContent = `Looking at ${photoCount} ${photoCount === 1 ? "photo" : "photos"}…`;
  $("busy").hidden = false;
  try {
    report = await analyze(key);
    render();
    window.scrollTo(0, 0);
  } catch (error) {
    showError(error instanceof TypeError ? "Couldn't reach Anthropic's API. Check your connection." : error.message);
  } finally {
    $("busy").hidden = true;
  }
}

// ---------- Rendering (model text only ever goes through textContent) ----------

function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  Object.assign(node, props);
  for (const child of children) if (child != null) node.append(child);
  return node;
}

function render() {
  const showReport = Boolean(report);
  $("emptyView").hidden = showReport || people.length > 0;
  $("peopleView").hidden = showReport || people.length === 0;
  $("reportView").hidden = !showReport;
  $("backButton").hidden = !showReport;
  document.querySelectorAll("[data-photos-only]").forEach((b) => (b.hidden = showReport));
  $("analyzeButton").disabled = people.length === 0;
  if (showReport) renderReport(); else renderPeople();
}

function renderPeople() {
  $("peopleCount").textContent = `${people.length} ${people.length === 1 ? "person" : "people"}`;
  const grid = $("peopleGrid");
  grid.replaceChildren(...people.map((person, index) => {
    const add = el("button", { className: "icon", type: "button", title: "Add more photos of this person", textContent: "+" });
    add.addEventListener("click", () => pickFiles(person.id));
    const remove = el("button", { className: "icon", type: "button", title: "Remove this person", textContent: "🗑" });
    remove.addEventListener("click", () => { people = people.filter((p) => p.id !== person.id); render(); });

    const photos = el("div", { className: "photos" }, ...person.photos.map((photo) => {
      const x = el("button", { className: "remove", type: "button", title: "Remove photo", textContent: "×" });
      x.addEventListener("click", () => {
        person.photos = person.photos.filter((p) => p.id !== photo.id);
        if (!person.photos.length) people = people.filter((p) => p.id !== person.id);
        render();
      });
      return el("div", { className: "photo" }, el("img", { src: photo.dataUrl, alt: `Person ${index + 1}` }), x);
    }));

    const note = el("textarea", { rows: 2, placeholder: "Optional: what are they like?", value: person.note });
    note.setAttribute("aria-label", `Note about Person ${index + 1}`);
    note.addEventListener("input", () => (person.note = note.value));

    const card = el("article", { className: "card" },
      el("div", { className: "card-head" }, el("h3", { textContent: `Person ${index + 1}` }), add, remove),
      photos, note);
    card.addEventListener("dragover", (e) => { e.preventDefault(); e.stopPropagation(); card.classList.add("dragging"); });
    card.addEventListener("dragleave", () => card.classList.remove("dragging"));
    card.addEventListener("drop", (e) => {
      e.preventDefault(); e.stopPropagation(); card.classList.remove("dragging"); document.body.classList.remove("dragging");
      addImages([...e.dataTransfer.files], person.id);
    });
    return card;
  }));
}

function renderReport() {
  const r = report;
  const sections = [["Physical", r.physical], ["Emotional", r.emotional], ["Spiritual", r.spiritual], ["Style & Lifestyle", r.lifestyle]];
  const faces = people.slice(0, 12).map((p) => el("img", { src: p.photos[0].dataUrl, alt: "" }));
  const list = (title, items) => items?.length
    ? el("div", { className: "list" }, el("h3", { textContent: title }), el("ul", {}, ...items.map((t) => el("li", { textContent: t }))))
    : null;

  $("reportView").replaceChildren(
    el("header", {},
      el("p", { className: "eyebrow", textContent: "Your type" }),
      el("h2", { className: "headline", textContent: r.headline }),
      el("p", { className: "lede", textContent: r.summary }),
      el("div", { className: "faces" }, ...faces,
        el("span", { className: "muted small", textContent: `Based on ${people.length} ${people.length === 1 ? "person" : "people"}` }))),
    ...sections.map(([title, s]) => el("section", { className: "section" },
      el("h3", { textContent: title }),
      el("p", { textContent: s.summary }),
      ...s.traits.map((t) => el("div", { className: "trait" },
        el("span", { className: `dot ${t.confidence}`, title: `${t.confidence} confidence` }),
        el("div", {}, el("div", { className: "trait-name", textContent: t.name }), el("div", { className: "trait-detail", textContent: t.detail })))))),
    list("What they all share", r.commonThreads),
    list("Who breaks the pattern", r.outliers),
    el("p", { className: "caveats", textContent: `ⓘ ${r.caveats}` }),
  );
}

// ---------- Dialogs ----------

function showError(message) {
  $("errorText").textContent = message;
  if (!$("errorDialog").open) $("errorDialog").showModal();
}

function openSettings(status) {
  $("keyInput").value = "";
  $("keyStatus").textContent = status ?? (loadKey() ? "A key is saved." : "No key saved yet.");
  $("settingsDialog").showModal();
  $("keyInput").focus();
}

// ---------- Input ----------

function pickFiles(personId = null) {
  const input = $("fileInput");
  input.onchange = () => { addImages([...input.files], personId); input.value = ""; };
  input.click();
}

document.addEventListener("paste", (e) => {
  if (report || e.target.closest?.("textarea, input")) return;
  const files = [...(e.clipboardData?.items ?? [])].filter((i) => i.kind === "file").map((i) => i.getAsFile());
  if (files.length) { e.preventDefault(); addImages(files); }
  else showError("There's no image on the clipboard.");
});
document.addEventListener("dragover", (e) => { if (!report) { e.preventDefault(); document.body.classList.add("dragging"); } });
document.addEventListener("dragleave", (e) => { if (!e.relatedTarget) document.body.classList.remove("dragging"); });
document.addEventListener("drop", (e) => {
  e.preventDefault();
  document.body.classList.remove("dragging");
  if (!report) addImages([...e.dataTransfer.files]);
});

$("addButton").addEventListener("click", () => pickFiles());
$("emptyAddButton").addEventListener("click", () => pickFiles());
$("analyzeButton").addEventListener("click", figureOutType);
$("backButton").addEventListener("click", () => { report = null; render(); });
$("settingsButton").addEventListener("click", () => openSettings());
$("saveKey").addEventListener("click", (e) => {
  const key = $("keyInput").value.trim();
  if (!key) { e.preventDefault(); $("keyStatus").textContent = "Paste a key first."; return; }
  saveKey(key, $("rememberKey").checked);
});
$("forgetKey").addEventListener("click", () => { saveKey(null, true); sessionKey = null; $("keyStatus").textContent = "Key forgotten."; });
$("feedbackTab").addEventListener("click", () => { $("feedbackStatus").textContent = ""; $("feedbackDialog").showModal(); });
$("sendFeedback").addEventListener("click", () => {
  const text = $("feedbackText").value.trim();
  if (!text) { $("feedbackStatus").textContent = "Write something first."; return; }
  const url = `${FEEDBACK_URL}?title=${encodeURIComponent("Feedback")}&body=${encodeURIComponent(text)}`;
  window.open(url, "_blank", "noopener");
  $("feedbackText").value = "";
  $("feedbackStatus").textContent = "Opened GitHub to send it. Thanks!";
});

render();
