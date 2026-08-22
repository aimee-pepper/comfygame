import crypto from "node:crypto";
import { ARRIVAL_SIZE, arrivalSceneCommands, receiptKeys, validateWorldArrivalReceipt } from "./world-arrival-kit.js";

export const CORPUS_ID = "world-arrival-command-corpus-v1";
export const COMMAND_OP = "rect-v1";
export const COMMAND_SCOPES = Object.freeze([
  "frame", "illumination", "ground", "water", "material", "flora",
  "suspended", "precipitation", "entryDisclosure", "entryMark"
]);
export const COMMAND_KEYS = Object.freeze(["op", "x", "y", "width", "height", "rgba", "scope", "sourceOrder"]);

export const sha256 = bytes => crypto.createHash("sha256").update(bytes).digest("hex");

export function canonicalValue(value) {
  if (Array.isArray(value)) return value.map(canonicalValue);
  if (value && typeof value === "object") return Object.fromEntries(
    Object.keys(value).sort().map(key => [key, canonicalValue(value[key])])
  );
  return value;
}

export const canonicalJSON = value => JSON.stringify(canonicalValue(value));
export const canonicalSHA256 = value => sha256(Buffer.from(canonicalJSON(value)));

function parseHex(value) {
  const raw = value.slice(1);
  if (raw.length === 3) return [...raw].map(ch => parseInt(ch + ch, 16)).concat(255);
  if (raw.length === 6) return [0, 2, 4].map(index => parseInt(raw.slice(index, index + 2), 16)).concat(255);
  if (raw.length === 8) return [0, 2, 4, 6].map(index => parseInt(raw.slice(index, index + 2), 16));
  throw new Error("invalid-arrival-command-color");
}

export function rgba8(value) {
  if (typeof value !== "string") throw new Error("invalid-arrival-command-color");
  if (value.startsWith("#")) return parseHex(value);
  const match = value.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d*\.?\d+))?\s*\)$/);
  if (!match) throw new Error("invalid-arrival-command-color");
  const channels = match.slice(1, 4).map(Number), alpha = match[4] === undefined ? 255 : Math.round(Number(match[4]) * 255);
  if (channels.some(channel => !Number.isInteger(channel) || channel < 0 || channel > 255) || alpha < 0 || alpha > 255) {
    throw new Error("invalid-arrival-command-color");
  }
  return [...channels, alpha];
}

export function validateCorpusCommand(command, expectedOrder = command?.sourceOrder) {
  if (!command || typeof command !== "object" || Array.isArray(command)
      || Object.keys(command).sort().join("|") !== [...COMMAND_KEYS].sort().join("|")) return ["invalid-command-fields"];
  const issues = [];
  if (command.op !== COMMAND_OP) issues.push("unknown-command-op");
  if (!COMMAND_SCOPES.includes(command.scope)) issues.push("unknown-command-scope");
  for (const key of ["x", "y", "width", "height", "sourceOrder"]) if (!Number.isInteger(command[key])) issues.push(`noninteger-${key}`);
  if (command.width <= 0 || command.height <= 0) issues.push("nonpositive-command-size");
  if (command.x < 0 || command.y < 0 || command.x + command.width > ARRIVAL_SIZE.width || command.y + command.height > ARRIVAL_SIZE.height) issues.push("command-out-of-bounds");
  if (!Array.isArray(command.rgba) || command.rgba.length !== 4 || command.rgba.some(channel => !Number.isInteger(channel) || channel < 0 || channel > 255)) issues.push("invalid-command-rgba");
  if (command.sourceOrder !== expectedOrder) issues.push("invalid-source-order");
  return [...new Set(issues)];
}

export function corpusCommands(receipt) {
  const receiptIssues = validateWorldArrivalReceipt(receipt);
  if (receiptIssues.length) throw new Error(`invalid-world-arrival-receipt:${receiptIssues.join(",")}`);
  return arrivalSceneCommands(receipt).map((command, sourceOrder) => {
    if (!command || command.op !== "rect" || Object.keys(command).sort().join("|") !== ["color", "h", "op", "scope", "w", "x", "y"].join("|")) {
      throw new Error("arrival-compositor-emitted-nonrect-command");
    }
    const normalized = { op: COMMAND_OP, x: command.x, y: command.y, width: command.w, height: command.h, rgba: rgba8(command.color), scope: command.scope, sourceOrder };
    const issues = validateCorpusCommand(normalized, sourceOrder);
    if (issues.length) throw new Error(`invalid-arrival-corpus-command:${issues.join(",")}`);
    return normalized;
  });
}

export function renderCorpusCommands(commands) {
  const rgba = new Uint8ClampedArray(ARRIVAL_SIZE.width * ARRIVAL_SIZE.height * 4);
  commands.forEach((command, index) => {
    const issues = validateCorpusCommand(command, index);
    if (issues.length) throw new Error(`invalid-arrival-corpus-command:${issues.join(",")}`);
    for (let y = command.y; y < command.y + command.height; y++) for (let x = command.x; x < command.x + command.width; x++) {
      const offset = (y * ARRIVAL_SIZE.width + x) * 4, alpha = command.rgba[3] / 255, inverse = 1 - alpha;
      rgba[offset] = Math.round(command.rgba[0] * alpha + rgba[offset] * inverse);
      rgba[offset + 1] = Math.round(command.rgba[1] * alpha + rgba[offset + 1] * inverse);
      rgba[offset + 2] = Math.round(command.rgba[2] * alpha + rgba[offset + 2] * inverse);
      rgba[offset + 3] = Math.round(command.rgba[3] + rgba[offset + 3] * inverse);
    }
  });
  return rgba;
}

export function sanitizeReceipt(receipt) {
  if (validateWorldArrivalReceipt(receipt).length) throw new Error("invalid-world-arrival-receipt");
  const sanitized = Object.fromEntries(receiptKeys.map(key => [key, structuredClone(receipt[key])]));
  return canonicalValue(sanitized);
}

export function makeCorpusRecord(id, receipt, metadata = {}) {
  const sanitizedReceipt = sanitizeReceipt(receipt), sceneReceiptBody = { version: 2, payload: sanitizedReceipt }, commands = corpusCommands(sanitizedReceipt), rgba = renderCorpusCommands(commands);
  return {
    id,
    metadata: canonicalValue(metadata),
    sceneReceiptVersion: 2,
    inputReceiptSHA256: canonicalSHA256(sceneReceiptBody),
    inputPayloadSHA256: canonicalSHA256(sanitizedReceipt),
    commandListSHA256: canonicalSHA256(commands),
    renderedRGBA8SHA256: sha256(rgba),
    receipt: sanitizedReceipt,
    arrivalSceneCommands: commands
  };
}
