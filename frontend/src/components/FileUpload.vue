//- Pugテンプレート言語でのVueテンプレート定義開始
<template lang="pug">
//- ファイルアップロードコンポーネントのメインコンテナ
.file-upload
  //- アップロードボタンを配置するフレックスコンテナ
  .upload-buttons
    //- 単一ファイル選択ボタン、ローディング時は無効化
    button.upload-btn(@click="triggerFileInput" :disabled="loading")
      //- ローディング中でない時に表示するテキスト
      span(v-if="!loading") 📄 ファイルを選択
      //- ローディング中に表示するテキスト
      span(v-else) 処理中...

    //- フォルダー選択ボタン、青色スタイル、ローディング時は無効化
    button.upload-btn.folder-btn(@click="triggerFolderInput" :disabled="loading")
      //- ローディング中でない時に表示するテキスト
      span(v-if="!loading") 📁 フォルダーを選択
      //- ローディング中に表示するテキスト
      span(v-else) 処理中...

  //- プログレス情報コンテナ、総ファイル数が0より大きい時のみ表示
  .progress-info(v-if="uploadProgress.total > 0")
    //- 現在の進捗状況をテキストで表示
    .progress-text {{ uploadProgress.current }}/{{ uploadProgress.total }} ファイル処理中...
    //- プログレスバーの背景コンテナ
    .progress-bar
      //- プログレスバーの進捗部分、幅を動的に変更
      .progress-fill(:style="{ width: progressPercentage + '%' }")

  //- 単一ファイル選択用の隠しinput要素
  input(
    ref="fileInput"
    type="file"
    accept=".csv"
    @change="handleFileSelect"
    style="display: none"
  )

  //- フォルダー選択用の隠しinput要素
  input(
    ref="folderInput"
    type="file"
    webkitdirectory
    multiple
    accept=".csv"
    @change="handleFolderSelect"
    style="display: none"
  )
</template>

<script>
// JavaScriptセクション開始
// Vue 3のComposition API関数をインポート
import { ref, reactive, computed } from 'vue'

export default { // Vue コンポーネントをデフォルトエクスポート
  name: 'FileUpload', // コンポーネント名を定義
  props: { // 親コンポーネントから受け取るプロパティ定義
    loading: { // ローディング状態のプロパティ
      type: Boolean, // データ型はboolean
      default: false // デフォルト値はfalse
    }
  },
  emits: ['file-uploaded', 'folder-uploaded'], // 発行するイベント名の配列
  setup(props, { emit }) { // Composition APIのsetup関数、propsとemitを受け取り
    const fileInput = ref(null) // 単一ファイル選択input要素への参照
    const folderInput = ref(null) // フォルダー選択input要素への参照

    const uploadProgress = reactive({ // アップロード進捗情報（リアクティブ）
      current: 0, // 現在処理中のファイル数
      total: 0 // 総ファイル数
    })

    const progressPercentage = computed(() => { // 進捗率を計算するコンピューテッドプロパティ
      if (uploadProgress.total === 0) return 0 // 総数が0なら0%を返す
      return Math.round((uploadProgress.current / uploadProgress.total) * 100) // 進捗率を計算し四捨五入
    })

    const triggerFileInput = () => { // 単一ファイル選択ダイアログを開く関数
      if (!props.loading && fileInput.value) { // ローディング中でなく要素が存在する場合
        fileInput.value.click() // input要素をプログラムからクリック
      }
    }

    const triggerFolderInput = () => { // フォルダー選択ダイアログを開く関数
      if (!props.loading && folderInput.value) { // ローディング中でなく要素が存在する場合
        folderInput.value.click() // input要素をプログラムからクリック
      }
    }

    const handleFileSelect = (event) => { // 単一ファイル選択時のイベントハンドラ
      const file = event.target.files[0] // 選択されたファイルの1番目を取得
      if (file) { // ファイルが存在する場合
        handleFile(file) // ファイル処理関数を呼び出し
      }
    }

    const handleFolderSelect = (event) => { // フォルダー選択時のイベントハンドラ
      const files = Array.from(event.target.files) // FileListを配列に変換
      console.log('選択されたファイル数:', files.length) // デバッグ用：ファイル数をログ出力
      console.log('ファイル一覧:', files.map(f => f.name)) // デバッグ用：ファイル名一覧をログ出力

      const csvFiles = files.filter(file => file.name.toLowerCase().endsWith('.csv')) // CSV拡張子でフィルタリング
      console.log('CSVファイル数:', csvFiles.length) // デバッグ用：CSVファイル数をログ出力
      console.log('CSVファイル一覧:', csvFiles.map(f => f.name)) // デバッグ用：CSVファイル名一覧をログ出力

      if (csvFiles.length === 0) { // CSVファイルが見つからない場合
        alert('CSVファイルが見つかりませんでした') // アラートダイアログ表示
        return // 処理を終了
      }

      console.log(`${csvFiles.length}個のCSVファイルが見つかりました`) // デバッグ用：見つかったCSVファイル数をログ出力
      handleMultipleFiles(csvFiles) // 複数ファイル処理関数を呼び出し
    }

    const handleFile = (file) => { // 単一ファイルの検証と処理を行う関数
      if (!file.name.toLowerCase().endsWith('.csv')) { // CSVファイルでない場合
        alert('CSVファイルを選択してください') // エラーメッセージ表示
        return // 処理を終了
      }

      if (file.size > 100 * 1024 * 1024) { // ファイルサイズが100MBを超える場合
        alert('ファイルサイズが大きすぎます（100MB以下にしてください）') // エラーメッセージ表示
        return // 処理を終了
      }

      emit('file-uploaded', file) // 親コンポーネントにfile-uploadedイベントを発行
    }

    const handleMultipleFiles = async (files) => { // 複数ファイルの処理を行う非同期関数
      const validFiles = files.filter(file => { // ファイルサイズでフィルタリング
        if (file.size > 100 * 1024 * 1024) { // 100MBを超える場合
          console.warn(`${file.name} はサイズが大きすぎます（スキップ）`) // 警告をログ出力
          return false // フィルタから除外
        }
        return true // フィルタを通す
      })

      if (validFiles.length === 0) { // 有効なファイルが一つもない場合
        alert('有効なファイルがありません') // エラーメッセージ表示
        uploadProgress.current = 0 // 現在の進捗を0にリセット
        uploadProgress.total = 0 // 総数を0にリセット
        return // 処理を終了
      }

      uploadProgress.current = 0 // 現在の進捗を0に初期化
      uploadProgress.total = validFiles.length // 総数を有効ファイル数に設定

      emit('folder-uploaded', { // 親コンポーネントにfolder-uploadedイベントを発行
        files: validFiles, // 有効なファイル配列を送信
        uploadProgress // 進捗情報オブジェクトを送信
      })
    }

    return { // setup関数から返すオブジェクト（テンプレートで使用可能）
      fileInput, // 単一ファイル選択input要素の参照
      folderInput, // フォルダー選択input要素の参照
      uploadProgress, // アップロード進捗情報オブジェクト
      progressPercentage, // 進捗率（計算済み）
      triggerFileInput, // 単一ファイル選択ダイアログ開く関数
      triggerFolderInput, // フォルダー選択ダイアログ開く関数
      handleFileSelect, // 単一ファイル選択イベントハンドラ
      handleFolderSelect // フォルダー選択イベントハンドラ
    }
  }
}
</script> // JavaScriptセクション終了

<style lang="scss" scoped> // SCSSスタイル開始、scopedで他コンポーネントに影響させない
.file-upload { // ファイルアップロードコンポーネントのメインコンテナ
  display: inline-block; // インラインブロック表示
  width: 100%; // 幅を100%に設定
}

.upload-buttons { // アップロードボタンのコンテナ
  display: flex; // フレックスボックスレイアウト
  gap: 15px; // ボタン間の間隔を15px
  margin-bottom: 15px; // 下部マージン15px
}

.upload-btn { // アップロードボタンの基本スタイル
  background: #4CAF50; // 背景色（緑色）
  color: white; // 文字色（白色）
  border: none; // ボーダーなし
  padding: 12px 25px; // 内側の余白（上下12px、左右25px）
  border-radius: 5px; // 角丸5px
  font-size: 1em; // フォントサイズ1em
  cursor: pointer; // マウスカーソルをポインターに変更
  transition: background 0.3s ease; // 背景色の変化に0.3秒のアニメーション

  &:hover:not(:disabled) { // ホバー時のスタイル（無効化されていない場合）
    background: #45a049; // より暗い緑色に変更
  }

  &:disabled { // 無効化時のスタイル
    opacity: 0.6; // 透明度を0.6に設定
    cursor: not-allowed; // 禁止カーソルに変更
  }

  &.folder-btn { // フォルダーボタン専用スタイル
    background: #2196F3; // 背景色（青色）

    &:hover:not(:disabled) { // フォルダーボタンのホバー時スタイル
      background: #1976D2; // より暗い青色に変更
    }
  }
}

.progress-info { // プログレス情報表示エリア
  margin-top: 15px; // 上部マージン15px
}

.progress-text { // プログレステキストのスタイル
  font-size: 0.9em; // フォントサイズを0.9emに設定
  color: #666; // 文字色（グレー）
  margin-bottom: 8px; // 下部マージン8px
  text-align: center; // 中央揃え
}

.progress-bar { // プログレスバーの背景部分
  width: 100%; // 幅100%
  height: 8px; // 高さ8px
  background: #e0e0e0; // 背景色（ライトグレー）
  border-radius: 4px; // 角丸4px
  overflow: hidden; // はみ出た部分を隠す
}

.progress-fill { // プログレスバーの進捗表示部分
  height: 100%; // 高さ100%
  background: linear-gradient(90deg, #4CAF50, #45a049); // 緑色のグラデーション背景
  transition: width 0.3s ease; // 幅の変化に0.3秒のアニメーション
}
</style> 