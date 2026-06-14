<template lang="pug">
.upload-manager-overlay(@click="closeModal")
  .upload-manager(@click.stop)
    .modal-header
      h2 🗑️ アップロード履歴管理
      button.close-btn(@click="closeModal") ×
    
    .modal-content
      .loading(v-if="isLoading") 読み込み中...
      
      .empty-state(v-else-if="histories.length === 0")
        p アップロード履歴がありません
        
      .batch-actions(v-if="histories.length > 0")
        .batch-controls
          label.select-all-label
            input(type="checkbox" v-model="selectAllChecked" @change="toggleSelectAll")
            span 全選択
          button.batch-delete-btn(@click="confirmBatchDelete" :disabled="selectedHistories.length === 0 || isDeleting") 
            | 選択項目を削除 ({{ selectedHistories.length }})
      
      .history-list(v-if="histories.length > 0")
        .history-item(v-for="history in histories" :key="history.id" @click="toggleSelection(history.id)" :class="{ selected: selectedHistoryIds.includes(history.id) }")
          .history-checkbox
            input(type="checkbox" v-model="selectedHistoryIds" :value="history.id" @click.stop)
          .history-info
            .filename 📄 {{ history.filename }}
            .details 
              span.date {{ history.upload_date }}
              span.count {{ history.imported_count }}件
    
    .modal-footer
      button.cancel-btn(@click="closeModal") 閉じる
</template>

<script>
import apiService from '../services/api.js'

export default {
  name: 'UploadManager',
  data() {
    return {
      histories: [],
      isLoading: true,
      isDeleting: false,
      selectedHistoryIds: []
    }
  },
  
  computed: {
    selectedHistories() {
      return this.histories.filter(history => this.selectedHistoryIds.includes(history.id))
    },
    
    selectAllChecked: {
      get() {
        return this.histories.length > 0 && this.selectedHistoryIds.length === this.histories.length
      },
      set(value) {
        // toggleSelectAll メソッドで処理
      }
    }
  },
  
  async mounted() {
    await this.loadHistories()
  },
  
  methods: {
    async loadHistories() {
      try {
        this.isLoading = true
        const response = await apiService.getUploadHistories()
        this.histories = response.upload_histories || []
        this.selectedHistoryIds = [] // 履歴読み込み時にチェックをクリア
      } catch (error) {
        console.error('履歴取得エラー:', error)
        alert('履歴の取得に失敗しました')
      } finally {
        this.isLoading = false
      }
    },
    
    toggleSelectAll() {
      if (this.selectedHistoryIds.length === this.histories.length) {
        // 全選択されている場合は全解除
        this.selectedHistoryIds = []
      } else {
        // 一部または未選択の場合は全選択
        this.selectedHistoryIds = this.histories.map(h => h.id)
      }
    },
    
    toggleSelection(historyId) {
      const index = this.selectedHistoryIds.indexOf(historyId)
      if (index > -1) {
        // 既に選択されている場合は解除
        this.selectedHistoryIds.splice(index, 1)
      } else {
        // 未選択の場合は選択に追加
        this.selectedHistoryIds.push(historyId)
      }
    },
    
    
    async confirmBatchDelete() {
      const selectedCount = this.selectedHistories.length
      const totalTransactions = this.selectedHistories.reduce((sum, h) => sum + h.imported_count, 0)
      
      const fileList = this.selectedHistories.map(h => `• ${h.filename} (${h.imported_count}件)`).join('\n')
      
      const message = `選択した${selectedCount}個のファイルのデータ（合計${totalTransactions}件）を完全に削除しますか？\n\n削除対象:\n${fileList}\n\nこの操作は取り消せません。`
      
      if (confirm(message)) {
        await this.batchDelete()
      }
    },
    
    async batchDelete() {
      try {
        this.isDeleting = true
        
        // 削除予定の履歴を事前に保存
        const historiesToDelete = [...this.selectedHistories]
        const deletedCount = historiesToDelete.length
        
        // 順次削除（並列処理だとサーバー負荷が高い場合があるため）
        for (const history of historiesToDelete) {
          await apiService.deleteUploadHistory(history.id)
          
          // 履歴リストから削除
          const index = this.histories.findIndex(h => h.id === history.id)
          if (index > -1) {
            this.histories.splice(index, 1)
          }
        }
        
        // 選択状態をクリア
        this.selectedHistoryIds = []
        
        alert(`${deletedCount}件のファイルのデータを削除しました`)
        
        // 親コンポーネントにデータ更新を通知
        this.$emit('data-updated')
        
      } catch (error) {
        console.error('一括削除エラー:', error)
        alert('一括削除に失敗しました: ' + error.message)
      } finally {
        this.isDeleting = false
      }
    },
    
    closeModal() {
      this.$emit('close')
    }
  }
}
</script>

<style lang="scss" scoped>
.upload-manager-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(45, 55, 69, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: $z-modal;
}

.upload-manager {
  background: $color-surface;
  border-radius: $radius-lg;
  min-width: 500px;
  max-width: 700px;
  max-height: 80vh;
  overflow: hidden;
  box-shadow: $shadow-lg;
}

.modal-header {
  background: $color-surface-sub;
  padding: $sp-5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid $color-border;

  h2 {
    margin: 0;
    color: $color-text-primary;
    font-size: $font-size-lg;
    font-weight: $font-weight-semibold;
  }

  .close-btn {
    background: none;
    border: none;
    font-size: $font-size-xl;
    cursor: pointer;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: $color-text-muted;
    line-height: 1;

    &:hover { color: $color-text-primary; }
  }
}

.modal-content {
  padding: $sp-5;
  max-height: 400px;
  overflow-y: auto;
}

.loading, .empty-state {
  text-align: center;
  padding: $sp-10;
  color: $color-text-secondary;
  font-size: $font-size-sm;
}

.batch-actions {
  margin-bottom: $sp-5;
  padding: $sp-4;
  background: $color-surface-sub;
  border-radius: $radius-sm;

  .batch-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: $sp-4;

    .select-all-label {
      display: flex;
      align-items: center;
      gap: $sp-2;
      cursor: pointer;
      font-weight: $font-weight-medium;
      font-size: $font-size-sm;
      color: $color-text-primary;

      input[type="checkbox"] { width: 16px; height: 16px; cursor: pointer; }
    }

    .batch-delete-btn {
      background: $color-danger;
      color: #fff;
      border: none;
      padding: $sp-2 $sp-4;
      border-radius: $radius-sm;
      cursor: pointer;
      font-weight: $font-weight-medium;
      font-size: $font-size-sm;
      transition: $transition-fast;

      &:hover:not(:disabled) { background: $red-700; }
      &:disabled { background: $color-text-muted; cursor: not-allowed; }
    }
  }
}

.history-list {
  .history-item {
    display: flex;
    align-items: center;
    padding: $sp-4;
    border: 1px solid $color-border;
    border-radius: $radius-sm;
    margin-bottom: $sp-2;
    gap: $sp-4;
    cursor: pointer;
    transition: $transition-fast;

    &:hover {
      background: $color-surface-sub;
      border-color: $color-accent;
    }

    &.selected {
      background: $color-accent-light;
      border-color: $color-accent;
      box-shadow: $shadow-xs;
    }
  }

  .history-checkbox {
    display: flex;
    align-items: center;
    input[type="checkbox"] { width: 16px; height: 16px; cursor: pointer; }
  }

  .history-info {
    flex: 1;

    .filename {
      font-weight: $font-weight-semibold;
      color: $color-text-primary;
      margin-bottom: $sp-1;
      font-size: $font-size-sm;
    }

    .details {
      display: flex;
      gap: $sp-4;
      font-size: $font-size-xs;
      color: $color-text-secondary;

      .date::before { content: "📅 "; }
      .count::before { content: "📊 "; }
    }
  }
}

.modal-footer {
  padding: $sp-5;
  border-top: 1px solid $color-border;
  display: flex;
  justify-content: flex-end;

  .cancel-btn {
    background: $color-surface-sub;
    color: $color-text-secondary;
    border: 1px solid $color-border;
    padding: $sp-2 + 2 $sp-5;
    border-radius: $radius-sm;
    cursor: pointer;
    font-size: $font-size-sm;
    transition: $transition-fast;

    &:hover { background: $color-border-light; }
  }
}

@media (max-width: $bp-md) {
  .upload-manager { min-width: 90%; margin: $sp-5; }

  .batch-controls {
    flex-direction: column;
    align-items: stretch;
    gap: $sp-2;
    .batch-delete-btn { width: 100%; }
  }

  .history-item {
    flex-direction: column;
    align-items: flex-start;
    gap: $sp-2;
    .history-checkbox { align-self: flex-start; }
    .history-info { align-self: stretch; }
  }
}
</style>