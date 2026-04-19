import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    vue({
      template: {
        preprocessOptions: {
          pug: { pugOptions: { pretty: true } }
        }
      }
    })
  ],
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "./src/styles/variables.scss";`
      }
    }
  },
  server: { port: 3002 }
})
