import { createRequire } from "node:module";
import fs from "node:fs";
import { createHash } from "node:crypto";
const { createCanvas, loadImage } = createRequire(import.meta.url)("@napi-rs/canvas");
const report = JSON.parse(fs.readFileSync("artifacts/world-grade-2-proof-v0.2.json", "utf8"));
const source = await loadImage("artifacts/world-grade-2-proof-v0.2-color.png");
const light = await loadImage("artifacts/world-grade-2-proof-v0.2-light-sequence.png");
const columns = 4, map = 112, gap = 8, cardW = 360, cardH = 194;
const canvas = createCanvas(columns * cardW + 32, 6 * cardH + 320), c = canvas.getContext("2d");
c.fillStyle = "#11110f"; c.fillRect(0, 0, canvas.width, canvas.height);
function text(value,x,y,size=12,bold=false,color="#eee9df"){c.fillStyle=color;c.font=`${bold?"bold ":""}${size}px Georgia`;c.textAlign="left";c.fillText(value,x,y);}
function shortInput(input){if(input.kind==="normalizedNumeric")return `${input.field??"distance"} ${input.from??""}${input.from!==undefined?" to ":""}${input.to??""} · ${input.value}`;if(input.values)return `${input.values.join(" to ")}`;if(input.kind==="resolvedFloraVector")return `coverage ${input.from.coveragePercent} to ${input.to.coveragePercent} · distance ${input.normalizedDistance}`;if(input.kind==="multiLayerOpposition")return "multi-layer opposition · no total order";return `${input.from??""} to ${input.to??""}`;}
const byFixture = new Map();
for (const measurement of report.measurements.filter((m)=>!['bright','dim','torch'].includes(m.a))) for (const id of [measurement.a,measurement.b]) { if (!byFixture.has(id)) byFixture.set(id,[]); byFixture.get(id).push(measurement); }
text("WORLD-GRADE-2 v0.2 · KEYED CALIBRATION COMPANION",16,25,16,true,"#d3bd7f");
text("Same-order copy of accepted unlabeled color sheet · named hues are calibration labels, not live writing vocabulary",16,47,11,false,"#bbb3a4");
report.fixtures.forEach((fixture,index)=>{const col=index%4,row=Math.floor(index/4),x=16+col*cardW,y=68+row*cardH,sx=8+col*(map+gap),sy=8+row*(map+gap);c.drawImage(source,sx,sy,map,map,x,y,map,map);text(`${index+1}. ${fixture.id}`,x+124,y+18,14,true);text(fixture.calibration,x+124,y+39,10,false,"#c9c0ae");const rows=byFixture.get(fixture.id)??[];if(!rows.length)text("reference · no pair delta",x+124,y+65,10);rows.slice(0,2).forEach((m,i)=>{const yy=y+63+i*56;text(`${m.layer} · ${m.band}`,x+124,yy,10,true,"#d3bd7f");text(`input ${shortInput(m.inputDistance)}`,x+124,yy+17,9);text(`whole ΔE ${m.wholeFrameDeltaE76} · layer ΔE ${m.layerDeltaE76??"n/a"}`,x+124,yy+34,9);});});
const ly=6*cardH+82;text("CURRENT VISIBILITY · SEPARATE LATER PRESENTATION LAYER",16,ly-22,13,true,"#d3bd7f");for(let i=0;i<3;i++){const x=16+i*440;c.drawImage(light,8+i*(map+gap),8,map,map,x,ly,map,map);const id=["bright","dim","torch"][i];text(id,x+124,ly+18,14,true);report.measurements.filter((m)=>m.a===id||m.b===id).forEach((m,j)=>{const yy=ly+43+j*54;text(`${m.layer} · ${m.band}`,x+124,yy,10,true,"#d3bd7f");text(`input ${shortInput(m.inputDistance)}`,x+124,yy+18,9);text(`whole ΔE ${m.wholeFrameDeltaE76} · layer ΔE n/a`,x+124,yy+36,9);});}
text("AUTHORITY NOTE",16,ly+190,11,true,"#d3bd7f");text("CMY+Depth InkRecipe? on eligible source rune => versioned bind resolver => frozen scoped resolved color + provenance. Named swatches here are labels only.",120,ly+190,10);
const keyedPNG = canvas.toBuffer("image/png");
fs.writeFileSync("artifacts/world-grade-2-proof-v0.2-keyed.png", keyedPNG);
report.artifacts.keyedCompanionSHA256 = createHash("sha256").update(keyedPNG).digest("hex");
fs.writeFileSync("artifacts/world-grade-2-proof-v0.2.json", `${JSON.stringify(report, null, 2)}\n`);
