<template lang="pug">
teleport(to="body")
  .modal-overlay(@click.self="$emit('close')")
    .modal-panel
      .modal-header
        h2.modal-title ✏️ 手入力で支出を追加
        button.modal-close(@click="$emit('close')") ✕

      .payment-tabs
        button.payment-tab(
          v-for="m in paymentMethods"
          :key="m.value"
          :class="{ active: form.payment_method === m.value }"
          @click="form.payment_method = m.value"
        )
          span.tab-icon {{ m.icon }}
          span {{ m.label }}

      form.modal-form(@submit.prevent="submit")
        .form-row
          label.form-label 日付
          input.form-input(
            type="date"
            v-model="form.transaction_date"
            required
          )

        .form-row
          label.form-label 店舗・内容
          input.form-input(
            type="text"
            v-model="form.store_name"
            placeholder="例: セブンイレブン、スーパー"
            required
          )

        .form-row
          label.form-label 金額
          .amount-wrap
            span.currency-sign ¥
            input.form-input.amount-input(
              type="number"
              v-model="form.amount"
              placeholder="0"
              min="1"
              required
            )

        .form-row
          label.form-label カテゴリ
          select.form-input(v-model="form.category_id")
            option(value="") 自動判定
            option(v-for="cat in categories" :key="cat.id" :value="cat.id")
              | {{ cat.name }}

        .form-actions
          button.btn-cancel(type="button" @click="$emit('close')") キャンセル
          button.btn-save(type="submit" :disabled="saving")
            | {{ saving ? '保存中...' : '保存する' }}

      .error-msg(v-if="error") {{ error }}
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'ManualEntryModal',
  emits: ['close', 'saved'],
  setup(_, { emit }) {
    const categories = ref([])
    const saving = ref(false)
    const error = ref(null)

    const today = new Date().toISOString().split('T')[0]
    const form = reactive({
      transaction_date: today,
      store_name: '',
      amount: '',
      category_id: '',
      payment_method: 'cash'
    })

    const paymentMethods = [
      { value: 'cash',  label: '現金',  icon: '💴' },
      { value: 'pasmo', label: 'Pasmo', icon: '🚃' },
      { value: 'other', label: 'その他', icon: '💳' }
    ]

    const submit = async () => {
      if (saving.value) return
      saving.value = true
      error.value = null
      try {
        await apiService.createTransaction({
          transaction_date: form.transaction_date,
          store_name: form.store_name,
          amount: form.amount,
          category_id: form.category_id || null,
          payment_method: form.payment_method
        })
        emit('saved')
        emit('close')
      } catch (e) {
        error.value = e.message
      } finally {
        saving.value = false
      }
    }

    onMounted(async () => {
      try {
        const res = await apiService.getCategories()
        categories.value = res
      } catch (_) {}
    })

    return { form, categories, paymentMethods, saving, error, submit }
  }
}
</script>

<style lang="scss" scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-panel {
  background: $color-surface;
  border-radius: $radius-lg;
  box-shadow: $shadow-lg;
  width: 420px;
  max-width: calc(100vw - 32px);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: $sp-5 $sp-6;
  border-bottom: 1px solid $color-border-light;
}

.modal-title {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.1rem;
  color: $color-text-muted;
  cursor: pointer;
  padding: $sp-1;
  line-height: 1;
  border-radius: $radius-sm;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; color: $color-text-primary; }
}

.payment-tabs {
  display: flex;
  gap: 0;
  border-bottom: 1px solid $color-border-light;
}

.payment-tab {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: $sp-1;
  padding: $sp-3;
  background: $color-surface-sub;
  border: none;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  cursor: pointer;
  transition: $transition-fast;
  border-bottom: 2px solid transparent;

  &:hover { background: $color-accent-light; color: $color-accent; }

  &.active {
    background: $color-surface;
    color: $color-accent;
    font-weight: $font-weight-semibold;
    border-bottom-color: $color-accent;
  }

  .tab-icon { font-size: 1rem; }
}

.modal-form {
  padding: $sp-5 $sp-6;
  display: flex;
  flex-direction: column;
  gap: $sp-4;
}

.form-row {
  display: flex;
  flex-direction: column;
  gap: $sp-1;
}

.form-label {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-secondary;
}

.form-input {
  width: 100%;
  padding: $sp-2 + 2 $sp-3;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-base;
  color: $color-text-primary;
  background: $color-surface;
  box-sizing: border-box;
  transition: $transition-fast;

  &:focus {
    outline: none;
    border-color: $color-accent;
    box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.12);
  }
}

.amount-wrap {
  display: flex;
  align-items: center;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  overflow: hidden;
  transition: $transition-fast;

  &:focus-within {
    border-color: $color-accent;
    box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.12);
  }
}

.currency-sign {
  padding: 0 $sp-3;
  font-size: $font-size-base;
  color: $color-text-secondary;
  background: $color-surface-sub;
  border-right: 1px solid $color-border;
  white-space: nowrap;
  align-self: stretch;
  display: flex;
  align-items: center;
}

.amount-input {
  border: none;
  border-radius: 0;

  &:focus { box-shadow: none; }
}

.form-actions {
  display: flex;
  gap: $sp-3;
  padding-top: $sp-2;
}

.btn-cancel {
  flex: 1;
  padding: $sp-3;
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; }
}

.btn-save {
  flex: 2;
  padding: $sp-3;
  background: $color-accent;
  border: none;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  font-weight: $font-weight-semibold;
  color: #fff;
  cursor: pointer;
  transition: $transition-fast;

  &:hover:not(:disabled) { background: $color-accent-hover; }
  &:disabled { opacity: 0.55; cursor: not-allowed; }
}

.error-msg {
  padding: $sp-3 $sp-6 $sp-4;
  font-size: $font-size-sm;
  color: #dc2626;
}
</style>
