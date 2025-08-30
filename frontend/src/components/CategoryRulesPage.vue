<template lang="pug">
.category-rules-page
  .page-header
    .page-title 
      span 🏷️ カテゴリキーワード管理
    .page-actions
      button.add-rule-btn(@click="showAddModal = true") ➕ 新しいルールを追加
  
  .rules-section
    .section-header
      h3 登録済みキーワードルール
      .rules-count {{ categoryRules.length }}件
    
    .rules-table(v-if="categoryRules.length > 0")
      .table-header
        .col-keyword キーワード
        .col-category カテゴリ
        .col-priority 優先度
        .col-actions 操作
        .col-bulk 一括操作
      
      .rule-row(
        v-for="rule in categoryRules" 
        :key="rule.id"
        :class="{ editing: editingRule?.id === rule.id }"
      )
        .col-keyword
          input.keyword-input(
            v-if="editingRule?.id === rule.id"
            v-model="editingRule.keyword"
            @keyup.enter="saveRule"
            @keyup.escape="cancelEdit"
          )
          span.keyword-display(v-else) {{ rule.keyword }}
        
        .col-category
          select.category-select(
            v-if="editingRule?.id === rule.id"
            v-model.number="editingRule.category_id"
          )
            option(value="" disabled) カテゴリを選択
            option(
              v-for="category in categories" 
              :key="category.id" 
              :value="category.id"
              :selected="category.id === editingRule.category_id"
              :style="`background-color: ${category.color}; color: white;`"
            ) {{ category.name }}
          .category-chip(
            v-else
            :style="`background-color: ${rule.category_color}; color: white;`"
          ) {{ rule.category_name }}
        
        .col-priority
          input.priority-input(
            v-if="editingRule?.id === rule.id"
            v-model.number="editingRule.priority"
            type="number"
            min="0"
            max="100"
          )
          span.priority-display(v-else) {{ rule.priority }}
        
        .col-actions
          .action-buttons(v-if="editingRule?.id === rule.id")
            button.save-btn(@click="saveRule") 保存
            button.cancel-btn(@click="cancelEdit") キャンセル
          .action-buttons(v-else)
            button.edit-btn(@click="startEdit(rule)") 編集
            button.delete-btn(@click="deleteRule(rule)") 削除
        
        .col-bulk
          button.bulk-btn(@click="showBulkModal(rule)") 
            | 一括適用 ({{ rule.matching_count || 0 }}件)
    
    .empty-state(v-else)
      .empty-icon 📋
      .empty-text キーワードルールが登録されていません
      .empty-description 新しいルールを追加して、取引の自動分類を設定しましょう
  
  // 新規ルール追加モーダル
  .modal(v-if="showAddModal" @click.self="showAddModal = false")
    .modal-content
      .modal-header
        h3 新しいキーワードルールを追加
        button.close-btn(@click="showAddModal = false") ×
      .modal-body
        .form-group
          label キーワード
          input.form-input(
            v-model="newRule.keyword"
            placeholder="例: Amazon, スターバックス"
            @keyup.enter="addRule"
          )
        .form-group
          label カテゴリ
          select.form-select(v-model="newRule.category_id")
            option(value="") カテゴリを選択
            option(
              v-for="category in categories" 
              :key="category.id" 
              :value="category.id"
              :style="`background-color: ${category.color}; color: white;`"
            ) {{ category.name }}
        .form-group
          label 優先度
          input.form-input(
            v-model.number="newRule.priority"
            type="number"
            min="0"
            max="100"
            placeholder="0-100 (高いほど優先)"
          )
      .modal-footer
        button.cancel-btn(@click="showAddModal = false") キャンセル
        button.add-btn(@click="addRule" :disabled="!canAddRule") 追加

  // 一括適用モーダル
  .modal(v-if="showBulkUpdateModal" @click.self="showBulkUpdateModal = false")
    .modal-content
      .modal-header
        h3 一括カテゴリ変更
        button.close-btn(@click="showBulkUpdateModal = false") ×
      .modal-body
        .bulk-info
          .bulk-keyword 
            strong キーワード: 
            span.keyword-highlight "{{ bulkUpdateData.keyword }}"
          .bulk-count
            strong 対象取引数: 
            span.count-highlight {{ getMatchingTransactionsCount(bulkUpdateData.keyword) }}件
          .bulk-current
            strong 変更先カテゴリ:
            .category-chip(:style="`background-color: ${bulkUpdateData.categoryColor}; color: white;`")
              | {{ bulkUpdateData.categoryName }}
        .bulk-warning
          | ⚠️ この操作により、上記キーワードを含む全ての取引のカテゴリが変更されます。
      .modal-footer
        button.cancel-btn(@click="showBulkUpdateModal = false") キャンセル  
        button.bulk-apply-btn(@click="applyBulkUpdate") 一括適用
</template>

<script>
import { ref, reactive, onMounted, computed } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'CategoryRulesPage',
  setup() {
    const categoryRules = ref([])
    const categories = ref([])
    const allTransactions = ref([])
    const isLoading = ref(false)
    
    // モーダル制御
    const showAddModal = ref(false)
    const showBulkUpdateModal = ref(false)
    
    // 編集状態
    const editingRule = ref(null)
    
    // 新規ルール
    const newRule = reactive({
      keyword: '',
      category_id: '',
      priority: 5
    })
    
    // 一括更新データ
    const bulkUpdateData = reactive({
      keyword: '',
      categoryId: '',
      categoryName: '',
      categoryColor: ''
    })
    
    const canAddRule = computed(() => {
      return newRule.keyword.trim() && newRule.category_id
    })
    
    // カテゴリクラス名取得
    const getCategoryClass = (categoryName) => {
      const mapping = {
        '投資': 'investment',
        '食費': 'food',
        '日用品費': 'daily', 
        '娯楽費': 'entertainment',
        '住宅費': 'housing',
        '交通費': 'transport',
        'その他': 'other'
      }
      return mapping[categoryName] || 'other'
    }
    
    // マッチする取引数を取得
    const getMatchingTransactionsCount = (keyword) => {
      if (!keyword || !allTransactions.value) return 0
      return allTransactions.value.filter(transaction => 
        transaction.store_name.toLowerCase().includes(keyword.toLowerCase())
      ).length
    }
    
    // データ読み込み
    const loadData = async () => {
      isLoading.value = true
      try {
        // 並行でデータを取得
        const [rulesResponse, transactionsResponse, analyticsData] = await Promise.all([
          apiService.getCategoryRules(),
          apiService.getTransactions(),
          apiService.getAnalyticsData()
        ])
        
        // 新しい配列として設定してreactivityを確実にトリガー
        categoryRules.value = [...(rulesResponse.category_rules || [])]
        allTransactions.value = transactionsResponse.transactions || []
        
        // 実際のカテゴリデータから構築（グラフの色と同期）
        if (analyticsData.category_stats && analyticsData.category_stats.length > 0) {
          const mappedCategories = analyticsData.category_stats.map(cat => ({
            id: Number(cat.id) || cat.id, // 数値変換、失敗時は元の値を保持
            name: cat.name,
            color: cat.color
          })).filter(cat => cat.id != null && cat.name) // nullやundefined、空の名前を除外
          
          if (mappedCategories.length > 0) {
            categories.value = mappedCategories
          } else {
            // マッピング後に空になった場合もフォールバック
            categories.value = [
              { id: 1, name: '投資', color: '#FF6384' },
              { id: 2, name: '食費', color: '#4BC0C0' },
              { id: 3, name: '日用品費', color: '#FFCE56' },
              { id: 4, name: '娯楽費', color: '#36A2EB' },
              { id: 5, name: '住宅費', color: '#FF6B6B' },
              { id: 6, name: '交通費', color: '#FF9F40' },
              { id: 7, name: 'その他', color: '#9966FF' }
            ]
          }
        } else {
          // フォールバック用のデフォルトカテゴリ
          categories.value = [
            { id: 1, name: '投資', color: '#FF6384' },
            { id: 2, name: '食費', color: '#4BC0C0' },
            { id: 3, name: '日用品費', color: '#FFCE56' },
            { id: 4, name: '娯楽費', color: '#36A2EB' },
            { id: 5, name: '住宅費', color: '#FF6B6B' },
            { id: 6, name: '交通費', color: '#FF9F40' },
            { id: 7, name: 'その他', color: '#9966FF' }
          ]
        }
        console.log('最終カテゴリデータ:', categories.value)
        
      } catch (error) {
        console.error('データ読み込みエラー:', error)
        alert('データの読み込みに失敗しました: ' + error.message)
      } finally {
        isLoading.value = false
      }
    }
    
    // 新規ルール追加
    const addRule = async () => {
      if (!canAddRule.value) return
      
      try {
        const result = await apiService.createCategoryRule({
          keyword: newRule.keyword.trim(),
          category_id: newRule.category_id,
          priority: newRule.priority || 5
        })
        
        const category = categories.value.find(c => c.id === newRule.category_id)
        categoryRules.value.unshift({
          ...result,
          category_name: category.name,
          category_color: category.color
        })
        
        // フォームリセット
        Object.assign(newRule, { keyword: '', category_id: '', priority: 5 })
        showAddModal.value = false
        
        alert('新しいルールを追加しました')
        
      } catch (error) {
        console.error('ルール追加エラー:', error)
        alert('ルールの追加に失敗しました: ' + error.message)
      }
    }
    
    // 編集開始
    const startEdit = (rule) => {
      editingRule.value = { ...rule }
    }
    
    // 編集キャンセル
    const cancelEdit = () => {
      editingRule.value = null
    }
    
    // ルール保存
    const saveRule = async () => {
      if (!editingRule.value) return
      
      try {
        const result = await apiService.updateCategoryRule(editingRule.value.id, {
          keyword: editingRule.value.keyword,
          category_id: editingRule.value.category_id,
          priority: editingRule.value.priority
        })
        
        // 編集モードを終了
        editingRule.value = null
        
        // データを再読み込みして確実に最新状態を反映
        await loadData()
        
        alert('ルールを更新しました')
        
      } catch (error) {
        console.error('ルール更新エラー:', error)
        alert('ルールの更新に失敗しました: ' + error.message)
      }
    }
    
    // ルール削除
    const deleteRule = async (rule) => {
      if (!confirm(`キーワード「${rule.keyword}」のルールを削除しますか？`)) return
      
      try {
        await apiService.deleteCategoryRule(rule.id)
        
        const index = categoryRules.value.findIndex(r => r.id === rule.id)
        if (index !== -1) {
          categoryRules.value.splice(index, 1)
        }
        
        alert('ルールを削除しました')
        
      } catch (error) {
        console.error('ルール削除エラー:', error)
        alert('ルールの削除に失敗しました: ' + error.message)
      }
    }
    
    // 一括更新モーダル表示
    const showBulkModal = (rule) => {
      Object.assign(bulkUpdateData, {
        keyword: rule.keyword,
        categoryId: rule.category_id,
        categoryName: rule.category_name,
        categoryColor: rule.category_color
      })
      showBulkUpdateModal.value = true
    }
    
    // 一括更新実行
    const applyBulkUpdate = async () => {
      try {
        const result = await apiService.bulkUpdateCategory(
          bulkUpdateData.keyword,
          bulkUpdateData.categoryId
        )
        
        showBulkUpdateModal.value = false
        alert(result.message)
        
        // 取引データを再読み込み
        const transactionsResponse = await apiService.getTransactions()
        allTransactions.value = transactionsResponse.transactions || []
        
      } catch (error) {
        console.error('一括更新エラー:', error)
        alert('一括更新に失敗しました: ' + error.message)
      }
    }
    
    onMounted(() => {
      loadData()
    })
    
    return {
      categoryRules,
      categories,
      allTransactions,
      isLoading,
      showAddModal,
      showBulkUpdateModal,
      editingRule,
      newRule,
      bulkUpdateData,
      canAddRule,
      getCategoryClass,
      getMatchingTransactionsCount,
      loadData,
      addRule,
      startEdit,
      cancelEdit,
      saveRule,
      deleteRule,
      showBulkModal,
      applyBulkUpdate
    }
  }
}
</script>

<style lang="scss" scoped>
.category-rules-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.page-title {
  font-size: 1.8em;
  color: #333;
  font-weight: 600;
}

.add-rule-btn {
  background: #4CAF50;
  color: white;
  border: none;
  padding: 12px 20px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
  
  &:hover {
    background: #45a049;
  }
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  
  h3 {
    color: #333;
    margin: 0;
  }
  
  .rules-count {
    background: #f0f0f0;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 0.9em;
    color: #666;
  }
}

.rules-table {
  background: white;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.table-header {
  display: grid;
  grid-template-columns: 2fr 1.5fr 1fr 1.5fr 1.5fr;
  gap: 15px;
  padding: 15px 20px;
  background: #f8f9fa;
  font-weight: 600;
  color: #333;
  border-bottom: 1px solid #dee2e6;
}

.rule-row {
  display: grid;
  grid-template-columns: 2fr 1.5fr 1fr 1.5fr 1.5fr;
  gap: 15px;
  padding: 15px 20px;
  border-bottom: 1px solid #f0f0f0;
  align-items: center;
  transition: background 0.2s;
  
  &:hover {
    background: #f8f9fa;
  }
  
  &.editing {
    background: #fff9e6;
    border-left: 4px solid #4CAF50;
  }
}

.keyword-input, .priority-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9em;
}

.keyword-display {
  font-family: 'Monaco', 'Menlo', monospace;
  background: #f5f5f5;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.9em;
}

.category-select {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9em;
}

.category-chip {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
  color: white;
}

.priority-display {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: #e9ecef;
  border-radius: 50%;
  font-weight: bold;
  color: #495057;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.edit-btn, .save-btn {
  background: #007bff;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 0.8em;
  cursor: pointer;
  
  &:hover {
    background: #0056b3;
  }
}

.delete-btn, .cancel-btn {
  background: #dc3545;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 0.8em;
  cursor: pointer;
  
  &:hover {
    background: #c82333;
  }
}

.bulk-btn {
  background: #17a2b8;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 0.8em;
  cursor: pointer;
  white-space: nowrap;
  
  &:hover {
    background: #138496;
  }
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
  
  .empty-icon {
    font-size: 4em;
    margin-bottom: 20px;
  }
  
  .empty-text {
    font-size: 1.3em;
    font-weight: 600;
    margin-bottom: 10px;
  }
  
  .empty-description {
    color: #999;
  }
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 10px;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #f0f0f0;
  
  h3 {
    margin: 0;
    color: #333;
  }
  
  .close-btn {
    background: none;
    border: none;
    font-size: 1.5em;
    cursor: pointer;
    color: #999;
    
    &:hover {
      color: #333;
    }
  }
}

.modal-body {
  padding: 20px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 20px;
  border-top: 1px solid #f0f0f0;
}

.form-group {
  margin-bottom: 20px;
  
  label {
    display: block;
    margin-bottom: 8px;
    font-weight: 600;
    color: #333;
  }
}

.form-input, .form-select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1em;
  
  &:focus {
    outline: none;
    border-color: #4CAF50;
    box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
  }
}

.cancel-btn {
  background: #6c757d;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  
  &:hover {
    background: #5a6268;
  }
}

.add-btn {
  background: #4CAF50;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  
  &:hover:not(:disabled) {
    background: #45a049;
  }
  
  &:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
}

.bulk-info {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  
  > div {
    margin-bottom: 10px;
    
    &:last-child {
      margin-bottom: 0;
    }
  }
}

.keyword-highlight {
  background: #fff3cd;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
}

.count-highlight {
  background: #d4edda;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: bold;
}

.bulk-warning {
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  padding: 15px;
  border-radius: 6px;
  color: #856404;
  font-size: 0.9em;
}

.bulk-apply-btn {
  background: #17a2b8;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  
  &:hover {
    background: #138496;
  }
}

// カテゴリ別の色設定
.category-investment { background: #667eea; }
.category-food { background: #4CAF50; }
.category-daily { background: #FF9800; }
.category-entertainment { background: #E91E63; }
.category-housing { background: #9C27B0; }
.category-transport { background: #00BCD4; }
.category-other { background: #9E9E9E; }
</style>