<template lang="pug">
.file-upload
  button.upload-btn(@click="triggerFileInput" :disabled="loading") 
    span(v-if="!loading") ファイルを選択
    span(v-else) 処理中...
  
  input(
    ref="fileInput"
    type="file"
    accept=".csv"
    @change="handleFileSelect"
    style="display: none"
  )
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'FileUpload',
  props: {
    loading: {
      type: Boolean,
      default: false
    }
  },
  emits: ['file-uploaded'],
  setup(props, { emit }) {
    const fileInput = ref(null)
    
    const triggerFileInput = () => {
      if (!props.loading) {
        fileInput.value.click()
      }
    }
    
    const handleFileSelect = (event) => {
      const file = event.target.files[0]
      if (file) {
        handleFile(file)
      }
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
    
    return {
      fileInput,
      triggerFileInput,
      handleFileSelect
    }
  }
}
</script>

<style lang="scss" scoped>
.file-upload {
  display: inline-block;
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
}
</style>