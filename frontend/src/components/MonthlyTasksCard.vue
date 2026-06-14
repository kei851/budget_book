<template lang="pug">
.tasks-card
  .tasks-header
    .tasks-title
      .tasks-icon 📋
      span {{ currentMonthLabel }}のやること
    .tasks-progress {{ doneCount }}/{{ tasks.length }}完了

  .tasks-list
    label.task-item(v-for="task in tasks" :key="task.id" :class="{ done: task.done }")
      input.task-check(
        type="checkbox"
        :checked="task.done"
        @change="toggle(task.id)"
      )
      .task-body
        .task-label {{ task.label }}
        .task-sub(v-if="task.sub") {{ task.sub }}

  .tasks-reset(v-if="doneCount > 0")
    button.btn-reset(@click="resetAll") リセット
</template>

<script>
import { ref, computed, onMounted } from 'vue'

const DEFAULT_TASKS = [
  { id: 'rakuten_csv',  label: '楽天カードCSVを取込む',  sub: '毎月10日頃に明細が確定' },
  { id: 'rakuten_bank', label: '楽天銀行CSVを取込む',    sub: 'Web明細からダウンロード' },
  { id: 'cash_input',   label: '現金の支出を手入力する', sub: 'レシートをまとめて入力' },
  { id: 'pasmo_input',  label: 'Pasmoの支出を手入力する', sub: 'アプリで履歴を確認しながら' },
  { id: 'budget_check', label: '予算の進捗を確認する',   sub: null },
  { id: 'ai_summary',   label: 'AIサマリを生成して振り返る', sub: null },
]

function storageKey(year, month) {
  return `monthly_tasks_${year}_${String(month).padStart(2, '0')}`
}

export default {
  name: 'MonthlyTasksCard',
  setup() {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth() + 1

    const currentMonthLabel = `${year}年${month}月`
    const key = storageKey(year, month)

    const savedDone = JSON.parse(localStorage.getItem(key) || '[]')

    const tasks = ref(
      DEFAULT_TASKS.map(t => ({ ...t, done: savedDone.includes(t.id) }))
    )

    const doneCount = computed(() => tasks.value.filter(t => t.done).length)

    const persist = () => {
      const done = tasks.value.filter(t => t.done).map(t => t.id)
      localStorage.setItem(key, JSON.stringify(done))
    }

    const toggle = (id) => {
      const task = tasks.value.find(t => t.id === id)
      if (task) { task.done = !task.done; persist() }
    }

    const resetAll = () => {
      tasks.value.forEach(t => { t.done = false })
      localStorage.removeItem(key)
    }

    return { tasks, doneCount, currentMonthLabel, toggle, resetAll }
  }
}
</script>

<style lang="scss" scoped>
.tasks-card {
  background: $color-surface;
  border: 1px solid $color-border-light;
  border-radius: $radius-lg;
  padding: $sp-5 $sp-6;
  box-shadow: $shadow-xs;
}

.tasks-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: $sp-4;
}

.tasks-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-base;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.tasks-icon { font-size: 1rem; }

.tasks-progress {
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
  color: $color-accent;
  background: $color-accent-light;
  padding: 2px $sp-2;
  border-radius: $radius-full;
}

.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.task-item {
  display: flex;
  align-items: flex-start;
  gap: $sp-3;
  padding: $sp-3;
  border-radius: $radius-sm;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; }

  &.done {
    .task-label {
      text-decoration: line-through;
      color: $color-text-muted;
    }
    .task-sub { color: $color-text-muted; opacity: 0.6; }
  }
}

.task-check {
  margin-top: 2px;
  width: 15px;
  height: 15px;
  flex-shrink: 0;
  accent-color: $color-accent;
  cursor: pointer;
}

.task-body { flex: 1; min-width: 0; }

.task-label {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-primary;
  transition: $transition-fast;
}

.task-sub {
  font-size: $font-size-xs;
  color: $color-text-muted;
  margin-top: 1px;
}

.tasks-reset {
  margin-top: $sp-3;
  padding-top: $sp-3;
  border-top: 1px solid $color-border-light;
  display: flex;
  justify-content: flex-end;
}

.btn-reset {
  background: none;
  border: none;
  font-size: $font-size-xs;
  color: $color-text-muted;
  cursor: pointer;
  padding: $sp-1 $sp-2;
  border-radius: $radius-sm;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; color: $color-text-secondary; }
}
</style>
