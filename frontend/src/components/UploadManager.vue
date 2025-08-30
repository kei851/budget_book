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
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.upload-manager {
  background: white;
  border-radius: 12px;
  min-width: 500px;
  max-width: 700px;
  max-height: 80vh;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.modal-header {
  background: #f8f9fa;
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #dee2e6;
  
  h2 {
    margin: 0;
    color: #495057;
    font-size: 1.5em;
  }
  
  .close-btn {
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    padding: 0;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #6c757d;
    
    &:hover {
      color: #495057;
    }
  }
}

.modal-content {
  padding: 20px;
  max-height: 400px;
  overflow-y: auto;
}

.loading, .empty-state {
  text-align: center;
  padding: 40px;
  color: #6c757d;
}

.batch-actions {
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  
  .batch-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 15px;
    
    .select-all-label {
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      font-weight: 500;
      
      input[type="checkbox"] {
        width: 16px;
        height: 16px;
        cursor: pointer;
      }
    }
    
    .batch-delete-btn {
      background: #dc3545;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 500;
      transition: background 0.2s;
      
      &:hover:not(:disabled) {
        background: #c82333;
      }
      
      &:disabled {
        background: #6c757d;
        cursor: not-allowed;
      }
    }
  }
}

.history-list {
  .history-item {
    display: flex;
    align-items: center;
    padding: 15px;
    border: 1px solid #dee2e6;
    border-radius: 8px;
    margin-bottom: 10px;
    gap: 15px;
    cursor: pointer;
    transition: all 0.2s ease;
    
    &:hover {
      background: #f8f9fa;
      border-color: #4CAF50;
    }
    
    &.selected {
      background: #e8f5e8;
      border-color: #4CAF50;
      box-shadow: 0 2px 4px rgba(76, 175, 80, 0.1);
    }
  }
  
  .history-checkbox {
    display: flex;
    align-items: center;
    
    input[type="checkbox"] {
      width: 16px;
      height: 16px;
      cursor: pointer;
    }
  }
  
  .history-info {
    flex: 1;
    
    .filename {
      font-weight: 600;
      color: #495057;
      margin-bottom: 5px;
    }
    
    .details {
      display: flex;
      gap: 15px;
      font-size: 0.9em;
      color: #6c757d;
      
      .date {
        &:before {
          content: "📅 ";
        }
      }
      
      .count {
        &:before {
          content: "📊 ";
        }
      }
    }
  }
  
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid #dee2e6;
  display: flex;
  justify-content: flex-end;
  
  .cancel-btn {
    background: #6c757d;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
    
    &:hover {
      background: #545b62;
    }
  }
}

// モバイル対応
@media (max-width: 768px) {
  .upload-manager {
    min-width: 90%;
    margin: 20px;
  }
  
  .batch-controls {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
    
    .batch-delete-btn {
      width: 100%;
    }
  }
  
  .history-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
    
    .history-checkbox {
      align-self: flex-start;
    }
    
    .history-info {
      align-self: stretch;
    }
    
  }
}
</style>