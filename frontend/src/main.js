// Vue 3のcreateApp関数をインポート
import { createApp } from 'vue'
// メインアプリケーションコンポーネントをインポート
import App from './App.vue'
// メインスタイルシートをインポート
import './styles/main.scss'

// Vueアプリケーションを作成し、#appエレメントにマウント
createApp(App).mount('#app')