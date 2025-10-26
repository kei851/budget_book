// Viteの設定関数をインポート
import { defineConfig } from 'vite'
// Vue.js用のViteプラグインをインポート
import vue from '@vitejs/plugin-vue'

// Viteの設定をエクスポート
export default defineConfig({
  // 使用するプラグインの配列
  plugins: [
    // Vueプラグインの設定
    vue({
      // テンプレート関連の設定
      template: {
        // プリプロセッサのオプション
        preprocessOptions: {
          // Pugテンプレートエンジンの設定
          pug: {
            // Pugの詳細オプション
            pugOptions: {
              // 整形された出力を生成（開発時の可読性向上）
              pretty: true
            }
          }
        }
      }
    })
  ],
  // CSS関連の設定
  css: {
    // CSSプリプロセッサのオプション
    preprocessorOptions: {
      // SCSS/Sassの設定
      scss: {
        // すべてのSCSSファイルに自動的に追加されるコード（変数ファイルをグローバルインポート）
        additionalData: `@import "./src/styles/variables.scss";`
      }
    }
  },
  // 開発サーバーの設定
  server: {
    // 開発サーバーのポート番号
    port: 3002
  }
})