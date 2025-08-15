<template lang="pug">
.file-upload
  .upload-buttons
    button.upload-btn(@click="triggerFileInput" :disabled="loading") 
      span(v-if="!loading") 📄 ファイルを選択
      span(v-else) 処理中...
    
    button.upload-btn.folder-btn(@click="triggerFolderInput" :disabled="loading") 
      span(v-if="!loading") 📁 フォルダーを選択
      span(v-else) 処理中...
  
  .progress-info(v-if="uploadProgress.total > 0")
    .progress-text {{ uploadProgress.current }}/{{ uploadProgress.total }} ファイル処理中...
    .progress-bar
      .progress-fill(:style="{ width: progressPercentage + '%' }")
  
  input(
    ref="fileInput"
    type="file"
    accept=".csv"
    @change="handleFileSelect"
    style="display: none"
  )
  
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
import { ref, reactive, computed } from 'vue'

export default {
  name: 'FileUpload',
  props: {
    loading: {
      type: Boolean,
      default: false
    }
  },
  emits: ['file-uploaded', 'folder-uploaded'],
  setup(props, { emit }) {
    const fileInput = ref(null)
    const folderInput = ref(null)
    
    const uploadProgress = reactive({
      current: 0,
      total: 0
    })
    
    const progressPercentage = computed(() => {
      if (uploadProgress.total === 0) return 0
      return Math.round((uploadProgress.current / uploadProgress.total) * 100)
    })
    
    const triggerFileInput = () => {
      if (!props.loading) {
        fileInput.value.click()
      }
    }
    
    const triggerFolderInput = () => {
      if (!props.loading) {
        folderInput.value.click()
      }
    }
    
    const handleFileSelect = (event) => {
      const file = event.target.files[0]
      if (file) {
        handleFile(file)
      }
    }
    
    const handleFolderSelect = (event) => {
      const files = Array.from(event.target.files)
      const csvFiles = files.filter(file => file.name.toLowerCase().endsWith('.csv'))
      
      if (csvFiles.length === 0) {
        alert('CSVファイルが見つかりませんでした')
        return
      }
      
      console.log(`${csvFiles.length}個のCSVファイルが見つかりました`)
      handleMultipleFiles(csvFiles)
    }
    
    const handleFile = (file) => {
      // ファイル形式チェック
      if (!file.name.toLowerCase().endsWith('.csv')) {
        alert('CSVファイルを選択してください')
        return
      }
      
      // ファイルサイズチェック (100MB)
      if (file.size > 100 * 1024 * 1024) {
        alert('ファイルサイズが大きすぎます（100MB以下にしてください）')
        return
      }
      
      emit('file-uploaded', file)
    }
    
    const handleMultipleFiles = async (files) => {
      uploadProgress.current = 0
      uploadProgress.total = files.length
      
      // ファイルサイズチェック
      const validFiles = files.filter(file => {
        if (file.size > 100 * 1024 * 1024) {
          console.warn(`${file.name} はサイズが大きすぎます（スキップ）`)
          return false
        }
        return true
      })
      
      if (validFiles.length === 0) {
        alert('有効なファイルがありません')
        uploadProgress.current = 0
        uploadProgress.total = 0
        return
      }
      
      // フォルダーアップロードイベントを発行
      emit('folder-uploaded', {
        files: validFiles,
        uploadProgress
      })
    }
    
    return {
      fileInput,
      folderInput,
      uploadProgress,
      progressPercentage,
      triggerFileInput,
      triggerFolderInput,
      handleFileSelect,
      handleFolderSelect
    }
  }
}
</script>

<style lang="scss" scoped>
.file-upload {
  display: inline-block;
  width: 100%;
}

.upload-buttons {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
}

.upload-btn {
  background: #4CAF50;
  color: white;
  border: none;
  padding: 12px 25px;
  border-radius: 5px;
  font-size: 1em;
  cursor: pointer;
  transition: background 0.3s ease;
  
  &:hover:not(:disabled) {
    background: #45a049;
  }
  
  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  &.folder-btn {
    background: #2196F3;
    
    &:hover:not(:disabled) {
      background: #1976D2;
    }
  }
}

.progress-info {
  margin-top: 15px;
}

.progress-text {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 8px;
  text-align: center;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e0e0e0;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4CAF50, #45a049);
  transition: width 0.3s ease;
}
</style>