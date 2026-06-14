<template lang="pug">
.budget-card
  .budget-card-header
    .budget-title
      .budget-icon 📅
      span 今月の予算
    .budget-actions
      button.btn-edit(v-if="!editing" @click="startEdit")
        svg(viewBox="0 0 24 24" width="14" height="14" fill="currentColor")
          path(d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z")
        span 予算を設定
      .edit-actions(v-else)
        button.btn-save(@click="saveBudgets" :disabled="saving") {{ saving ? '保存中...' : '保存' }}
        button.btn-cancel(@click="cancelEdit") キャンセル

  .budget-empty(v-if="!editing && budgets.length === 0")
    p.empty-text 予算がまだ設定されていません
    button.btn-generate(@click="startEdit") ＋ 予算を設定する

  .budget-list(v-else)
    .budget-item(v-for="item in displayItems" :key="item.category_id")
      .budget-item-header
        .category-dot(:style="{ background: item.category_color }")
        .category-name {{ item.category_name }}
        .budget-amounts(v-if="!editing")
          span.spent(:class="{ over: item.percentage >= 100 }") ¥{{ item.spent_amount.toLocaleString() }}
          span.separator /
          span.budget ¥{{ item.budget_amount.toLocaleString() }}

      .budget-bar-wrapper(v-if="!editing")
        .budget-bar
          .budget-bar-fill(
            :style="{ width: item.percentage + '%', background: item.percentage >= 100 ? '#ef4444' : item.percentage >= 80 ? '#f59e0b' : item.category_color }"
          )
        .budget-percent(:class="{ over: item.percentage >= 100 }") {{ item.percentage }}%

      .budget-input-row(v-if="editing")
        span.input-yen ¥
        input.budget-input(
          type="number"
          v-model.number="editValues[item.category_id]"
          placeholder="0"
          min="0"
        )
</template>

<script>
import { ref, computed, watch } from 'vue'
import apiService from '../services/api.js'

const CATEGORIES = [
  { id: 1, name: '投資',    color: '#FC3059' },
  { id: 2, name: '食費',    color: '#14b8a6' },
  { id: 3, name: '日用品費', color: '#8b5cf6' },
  { id: 4, name: '娯楽費',  color: '#338EE8' },
  { id: 5, name: '住宅費',  color: '#B87500' },
  { id: 6, name: '交通費',  color: '#B89000' },
  { id: 7, name: 'その他',  color: '#868F9C' },
]

export default {
  name: 'BudgetCard',
  props: {
    year: { type: Number, required: true },
    month: { type: Number, required: true },
    isPrivacyMode: { type: Boolean, default: false }
  },
  setup(props) {
    const budgets = ref([])
    const editing = ref(false)
    const saving = ref(false)
    const editValues = ref({})

    const displayItems = computed(() => {
      if (editing.value) return CATEGORIES
      return budgets.value.length > 0 ? budgets.value : []
    })

    const load = async () => {
      try {
        budgets.value = await apiService.getBudgets(props.year, props.month)
      } catch (_) {}
    }

    const startEdit = () => {
      editValues.value = {}
      CATEGORIES.forEach(c => {
        const existing = budgets.value.find(b => b.category_id === c.id)
        editValues.value[c.id] = existing ? existing.budget_amount : 0
      })
      editing.value = true
    }

    const cancelEdit = () => { editing.value = false }

    const saveBudgets = async () => {
      saving.value = true
      try {
        const items = CATEGORIES.map(c => ({
          category_id: c.id,
          amount: editValues.value[c.id] || 0
        }))
        await apiService.setBudgets(props.year, props.month, items)
        await load()
        editing.value = false
      } catch (e) {
        alert('保存に失敗しました: ' + e.message)
      } finally {
        saving.value = false
      }
    }

    watch([() => props.year, () => props.month], load, { immediate: true })

    return { budgets, editing, saving, editValues, displayItems, startEdit, cancelEdit, saveBudgets }
  }
}
</script>

<style lang="scss" scoped>
.budget-card {
  background: $color-surface;
  border: 1px solid $color-border-light;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-sm;
}

.budget-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: $sp-5;
}

.budget-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.budget-icon { font-size: 1.1rem; }

.btn-edit {
  display: flex;
  align-items: center;
  gap: $sp-1;
  padding: $sp-1 + 2 $sp-3;
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-accent-light; color: $color-accent; border-color: $color-accent; }
}

.edit-actions { display: flex; gap: $sp-2; }

.btn-save {
  padding: $sp-1 + 2 $sp-4;
  background: $color-accent;
  border: none;
  border-radius: $radius-sm;
  color: #fff;
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  cursor: pointer;
  transition: $transition-fast;

  &:hover:not(:disabled) { background: $color-accent-hover; }
  &:disabled { opacity: 0.6; cursor: not-allowed; }
}

.btn-cancel {
  padding: $sp-1 + 2 $sp-3;
  background: transparent;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  color: $color-text-secondary;
  font-size: $font-size-sm;
  cursor: pointer;

  &:hover { background: $color-surface-sub; }
}

.budget-empty {
  text-align: center;
  padding: $sp-6 0;

  .empty-text {
    font-size: $font-size-sm;
    color: $color-text-muted;
    margin-bottom: $sp-4;
  }
}

.btn-generate {
  padding: $sp-2 + 2 $sp-5;
  background: linear-gradient(135deg, $color-accent, #7c3aed);
  border: none;
  border-radius: $radius-full;
  color: #fff;
  font-size: $font-size-sm;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(99,102,241,0.3);
  transition: $transition-base;

  &:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(99,102,241,0.4); }
}

.budget-list { display: flex; flex-direction: column; gap: $sp-4; }

.budget-item {
  display: flex;
  flex-direction: column;
  gap: $sp-1 + 2;
}

.budget-item-header {
  display: flex;
  align-items: center;
  gap: $sp-2;
}

.category-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.category-name {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-primary;
  flex: 1;
}

.budget-amounts {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: $font-size-xs;

  .spent {
    font-weight: $font-weight-semibold;
    color: $color-text-primary;
    &.over { color: #ef4444; }
  }
  .separator { color: $color-text-muted; }
  .budget { color: $color-text-muted; }
}

.budget-bar-wrapper {
  display: flex;
  align-items: center;
  gap: $sp-2;
}

.budget-bar {
  flex: 1;
  height: 6px;
  background: $color-border-light;
  border-radius: $radius-full;
  overflow: hidden;
}

.budget-bar-fill {
  height: 100%;
  border-radius: $radius-full;
  transition: width 0.5s ease;
}

.budget-percent {
  font-size: $font-size-xs;
  color: $color-text-muted;
  min-width: 32px;
  text-align: right;

  &.over { color: #ef4444; font-weight: $font-weight-semibold; }
}

.budget-input-row {
  display: flex;
  align-items: center;
  gap: $sp-1;
  flex: 1;
}

.input-yen {
  font-size: $font-size-sm;
  color: $color-text-secondary;
}

.budget-input {
  flex: 1;
  padding: $sp-1 + 2 $sp-2;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-primary;
  background: $color-surface-sub;
  outline: none;
  width: 100%;

  &:focus { border-color: $color-accent; background: #fff; }
}
</style>
