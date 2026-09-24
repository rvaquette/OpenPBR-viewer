
import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
  base: "/OpenPBR-viewer/",
  build: {
    target: "esnext",
    sourcemap: true,
    rollupOptions: {
      input: {
        main: "index.html",
        mobile: "index2.html"
      },
      // The MaterialX WASM module is served as a static asset from public/mtlx/
      // and loaded via dynamic import at runtime — exclude from bundling.
      external: [/^\/mtlx\//]
    }
  }
})