import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';


export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    allowedHosts: ['app.fastcheckin.net', 'www.fastcheckin.net'],
    cors: {
      origin: ['*'],
      credentials: true
    }
  },
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
  css: {
    devSourcemap: true
  },
});
