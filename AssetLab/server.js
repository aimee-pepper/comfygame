import { createServer } from "node:http";
import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { basename, extname, join, normalize } from "node:path";

const root = new URL(".", import.meta.url).pathname;
const port = 4173;
const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png"
};

createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host}`),pathname = decodeURIComponent(url.pathname);
  if(request.method==="POST"&&pathname==="/__artifact"){
    const requested=basename(url.searchParams.get("name")??"");
    if(!/^[a-zA-Z0-9._-]+\.png$/.test(requested)){response.writeHead(400).end("Invalid PNG filename");return;}
    const chunks=[];let size=0;for await(const chunk of request){size+=chunk.length;if(size>5_000_000){response.writeHead(413).end("Artifact too large");return;}chunks.push(chunk);}
    const bytes=Buffer.concat(chunks);if(bytes.length<8||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))){response.writeHead(415).end("Expected PNG bytes");return;}
    const directory=join(root,"artifacts");await mkdir(directory,{recursive:true});await writeFile(join(directory,requested),bytes);response.writeHead(201,{"Content-Type":"application/json"}).end(JSON.stringify({path:`artifacts/${requested}`,bytes:bytes.length}));return;
  }
  const relative = pathname === "/" ? "index.html" : pathname.slice(1);
  const file = normalize(join(root, relative));
  if (!file.startsWith(root)) {
    response.writeHead(403).end("Forbidden");
    return;
  }
  try {
    if (!(await stat(file)).isFile()) throw new Error("Not a file");
    response.writeHead(200, { "Content-Type": types[extname(file)] ?? "application/octet-stream" });
    response.end(await readFile(file));
  } catch {
    response.writeHead(404).end("Not found");
  }
}).listen(port, "127.0.0.1", () => {
  console.log(`Bookbinder Asset Lab: http://127.0.0.1:${port}`);
});
