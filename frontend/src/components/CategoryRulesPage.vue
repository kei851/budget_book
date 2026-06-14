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
            categories.value = [
              { id: 1, name: '投資', color: '#FC3059' },
              { id: 2, name: '食費', color: '#14b8a6' },
              { id: 3, name: '日用品費', color: '#8b5cf6' },
              { id: 4, name: '娯楽費', color: '#338EE8' },
              { id: 5, name: '住宅費', color: '#B87500' },
              { id: 6, name: '交通費', color: '#B89000' },
              { id: 7, name: 'その他', color: '#868F9C' }
            ]
          }
        } else {
          categories.value = [
            { id: 1, name: '投資', color: '#FC3059' },
            { id: 2, name: '食費', color: '#14b8a6' },
            { id: 3, name: '日用品費', color: '#8b5cf6' },
            { id: 4, name: '娯楽費', color: '#338EE8' },
            { id: 5, name: '住宅費', color: '#B87500' },
            { id: 6, name: '交通費', color: '#B89000' },
            { id: 7, name: 'その他', color: '#868F9C' }
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
  padding: $sp-5;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: $sp-8;
}

.page-title {
  font-size: $font-size-xl;
  color: $color-text-primary;
  font-weight: $font-weight-semibold;
}

.add-rule-btn {
  background: $color-accent;
  color: #fff;
  border: none;
  padding: $sp-3 $sp-5;
  border-radius: $radius-sm;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  transition: $transition-base;

  &:hover { background: $color-accent-hover; }
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: $sp-5;

  h3 { color: $color-text-primary; margin: 0; font-weight: $font-weight-semibold; }

  .rules-count {
    background: $color-border-light;
    padding: $sp-1 $sp-3;
    border-radius: $radius-full;
    font-size: $font-size-sm;
    color: $color-text-secondary;
  }
}

.rules-table {
  background: $color-surface;
  border-radius: $radius-md;
  overflow: hidden;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border-light;
}

.table-header {
  display: grid;
  grid-template-columns: 2fr 1.5fr 1fr 1.5fr 1.5fr;
  gap: $sp-4;
  padding: $sp-4 $sp-5;
  background: $color-surface-sub;
  font-weight: $font-weight-semibold;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  border-bottom: 1px solid $color-border;
}

.rule-row {
  display: grid;
  grid-template-columns: 2fr 1.5fr 1fr 1.5fr 1.5fr;
  gap: $sp-4;
  padding: $sp-4 $sp-5;
  border-bottom: 1px solid $color-border-light;
  align-items: center;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; }

  &.editing {
    background: $color-accent-light;
    border-left: 3px solid $color-accent;
  }
}

.keyword-input, .priority-input {
  width: 100%;
  padding: $sp-1 + 2 $sp-2;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-primary;

  &:focus {
    outline: none;
    border-color: $color-accent;
    box-shadow: 0 0 0 2px $color-accent-light;
  }
}

.keyword-display {
  font-family: 'Monaco', 'Menlo', monospace;
  background: $color-surface-sub;
  padding: $sp-1 $sp-2;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-primary;
}

.category-select {
  width: 100%;
  padding: $sp-1 + 2 $sp-2;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
}

.category-chip {
  display: inline-flex;
  align-items: center;
  padding: $sp-1 $sp-2 + 2;
  border-radius: $radius-full;
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
  color: #fff;
}

.priority-display {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: $color-border-light;
  border-radius: 50%;
  font-weight: $font-weight-semibold;
  font-size: $font-size-sm;
  color: $color-text-secondary;
}

.action-buttons {
  display: flex;
  gap: $sp-2;
}

.edit-btn, .save-btn {
  background: $color-accent;
  color: #fff;
  border: none;
  padding: $sp-1 + 2 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-xs;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-accent-hover; }
}

.delete-btn {
  background: $color-danger;
  color: #fff;
  border: none;
  padding: $sp-1 + 2 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-xs;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $red-700; }
}

.cancel-btn {
  background: $color-surface-sub;
  color: $color-text-secondary;
  border: 1px solid $color-border;
  padding: $sp-1 + 2 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-xs;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-border-light; }
}

.bulk-btn {
  background: $color-accent-light;
  color: $color-accent;
  border: 1px solid $blue-100;
  padding: $sp-2 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-xs;
  font-weight: $font-weight-medium;
  cursor: pointer;
  white-space: nowrap;
  transition: $transition-fast;

  &:hover { background: $blue-100; }
}

.empty-state {
  text-align: center;
  padding: $sp-12 $sp-5;
  color: $color-text-secondary;

  .empty-icon { font-size: 3.5em; margin-bottom: $sp-5; }
  .empty-text { font-size: $font-size-lg; font-weight: $font-weight-semibold; margin-bottom: $sp-2; }
  .empty-description { color: $color-text-muted; font-size: $font-size-sm; }
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(45, 55, 69, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: $z-modal;
}

.modal-content {
  background: $color-surface;
  border-radius: $radius-lg;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: $shadow-lg;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $sp-5;
  border-bottom: 1px solid $color-border-light;

  h3 { margin: 0; color: $color-text-primary; font-weight: $font-weight-semibold; }

  .close-btn {
    background: none;
    border: none;
    font-size: $font-size-lg;
    cursor: pointer;
    color: $color-text-muted;
    line-height: 1;

    &:hover { color: $color-text-primary; }
  }
}

.modal-body { padding: $sp-5; }

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: $sp-2;
  padding: $sp-5;
  border-top: 1px solid $color-border-light;
}

.form-group {
  margin-bottom: $sp-5;

  label {
    display: block;
    margin-bottom: $sp-2;
    font-weight: $font-weight-semibold;
    font-size: $font-size-sm;
    color: $color-text-primary;
  }
}

.form-input, .form-select {
  width: 100%;
  padding: $sp-2 + 2 $sp-3;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-base;
  color: $color-text-primary;

  &:focus {
    outline: none;
    border-color: $color-accent;
    box-shadow: 0 0 0 2px $color-accent-light;
  }
}

.add-btn {
  background: $color-accent;
  color: #fff;
  border: none;
  padding: $sp-2 + 2 $sp-5;
  border-radius: $radius-sm;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  transition: $transition-base;

  &:hover:not(:disabled) { background: $color-accent-hover; }
  &:disabled { background: $color-border; cursor: not-allowed; }
}

.bulk-info {
  background: $color-surface-sub;
  padding: $sp-5;
  border-radius: $radius-sm;
  margin-bottom: $sp-5;

  > div { margin-bottom: $sp-2; &:last-child { margin-bottom: 0; } }
}

.keyword-highlight {
  background: $yellow-60;
  padding: 2px $sp-1 + 2;
  border-radius: 3px;
  font-family: monospace;
  color: $color-warning;
}

.count-highlight {
  background: $color-success-bg;
  padding: 2px $sp-1 + 2;
  border-radius: 3px;
  font-weight: $font-weight-semibold;
  color: $color-success;
}

.bulk-warning {
  background: $color-warning-bg;
  border: 1px solid $yellow-500;
  padding: $sp-4;
  border-radius: $radius-sm;
  color: $color-warning;
  font-size: $font-size-sm;
}

.bulk-apply-btn {
  background: $color-accent;
  color: #fff;
  border: none;
  padding: $sp-2 + 2 $sp-5;
  border-radius: $radius-sm;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  transition: $transition-base;

  &:hover { background: $color-accent-hover; }
}
</style>