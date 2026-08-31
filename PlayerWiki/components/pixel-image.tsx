export function PixelImage({ src, alt, size = 48 }: { src: string | null; alt: string; size?: number }) {
  if (!src) return <span className="image-missing" style={{ width: size, height: size }} aria-hidden="true">?</span>;
  return <img className="pixel-image" src={src} alt={alt} width={size} height={size} style={{ width: size, height: size }} />;
}
