<template lang="pug">
.file-upload
  .upload-buttons
    button.btn.btn-primary(@click="triggerFileInput" :disabled="loading")
      span(v-if="!loading") 📄 ファイルを選択
      span(v-else) 処理中...
    button.btn.btn-secondary(@click="triggerFolderInput" :disabled="loading")
      span(v-if="!loading") 📁 フォルダーを選択
      span(v-else) 処理中...

  .progress-info(v-if="uploadProgress.total > 0")
    .progress-text {{ uploadProgress.current }} / {{ uploadProgress.total }} ファイル処理中
    .progress-bar
      .progress-fill(:style="{ width: progressPercentage + '%' }")

  input(ref="fileInput" type="file" accept=".csv" @change="handleFileSelect" style="display:none")
  input(ref="folderInput" type="file" webkitdirectory multiple accept=".csv" @change="handleFolderSelect" style="display:none")
</template>

<script>
import { ref, reactive, computed } from 'vue'

export default {
  name: 'FileUpload',
  props: { loading: { type: Boolean, default: false } },
  emits: ['file-uploaded', 'folder-uploaded'],
  setup(props, { emit }) {
    const fileInput = ref(null)
    const folderInput = ref(null)
    const uploadProgress = reactive({ current: 0, total: 0 })
    const progressPercentage = computed(() =>
      uploadProgress.total === 0 ? 0 : Math.round((uploadProgress.current / uploadProgress.total) * 100)
    )

    const triggerFileInput = () => { if (!props.loading) fileInput.value?.click() }
    const triggerFolderInput = () => { if (!props.loading) folderInput.value?.click() }

    const handleFileSelect = (e) => {
      const file = e.target.files[0]
      if (!file) return
      if (!file.name.toLowerCase().endsWith('.csv')) { alert('CSVファイルを選択してください'); return }
      if (file.size > 100 * 1024 * 1024) { alert('ファイルサイズが大きすぎます（100MB以下）'); return }
      emit('file-uploaded', file)
    }

    const handleFolderSelect = (e) => {
      const csvFiles = Array.from(e.target.files)
        .filter(f => f.name.toLowerCase().endsWith('.csv'))
        .filter(f => f.size <= 100 * 1024 * 1024)
      if (csvFiles.length === 0) { alert('CSVファイルが見つかりませんでした'); return }
      uploadProgress.current = 0
      uploadProgress.total = csvFiles.length
      emit('folder-uploaded', { files: csvFiles, uploadProgress })
    }

    return { fileInput, folderInput, uploadProgress, progressPercentage, triggerFileInput, triggerFolderInput, handleFileSelect, handleFolderSelect }
  }
}
</script>

<style lang="scss" scoped>

.file-upload { width: 100%; }

.upload-buttons {
  display: flex;
  gap: $sp-3;
  flex-wrap: wrap;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: $sp-2;
  padding: $sp-3 $sp-5;
  border: none;
  border-radius: $radius-sm;
  font-size: $font-size-base;
  font-weight: $font-weight-medium;
  transition: $transition-fast;

  &:disabled { opacity: 0.5; cursor: not-allowed; }

  &-primary {
    background: $color-accent;
    color: #ffffff;
    &:hover:not(:disabled) { background: $color-accent-hover; }
  }

  &-secondary {
    background: $color-surface;
    color: $color-text-primary;
    border: 1px solid $color-border;
    &:hover:not(:disabled) { background: $color-surface-sub; }
  }
}

.progress-info { margin-top: $sp-3; }

.progress-text {
  font-size: $font-size-sm;
  color: $color-text-secondary;
  margin-bottom: $sp-2;
  text-align: center;
}

.progress-bar {
  height: 6px;
  background: $color-border;
  border-radius: $radius-full;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: $color-accent;
  border-radius: $radius-full;
  transition: width 0.3s ease;
}
</style>
