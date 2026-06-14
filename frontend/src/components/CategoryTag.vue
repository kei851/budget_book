<template lang="pug">
.category-tag-container
  .category-chip(
    :class="[`category-${category}`, { editing: isEditing }]"
    @click="toggleEdit"
  )
    span.category-text {{ categoryText }}
    span.edit-icon(v-if="!isEditing") ✏️
  
  .category-dropdown(v-if="isEditing" @click.stop)
    .dropdown-header カテゴリを選択
    .category-option(
      v-for="option in categoryOptions"
      :key="option.value"
      :class="{ active: option.value === categoryText }"
      @click="selectCategory(option)"
    )
      .option-chip(:class="`category-${option.class}`")
        span {{ option.text }}
    .dropdown-footer
      button.cancel-btn(@click="cancelEdit") キャンセル
</template>

<script>
import { ref, onMounted, onBeforeUnmount } from 'vue'

export default {
  name: 'CategoryTag',
  props: {
    category: {
      type: String,
      default: 'other'
    },
    categoryText: {
      type: String,
      default: 'その他'
    }
  },
  emits: ['change-category'],
  setup(props, { emit }) {
    const isEditing = ref(false)
    
    const categoryOptions = [
      { value: '投資', text: '投資', class: 'investment' },
      { value: '食費', text: '食費', class: 'food' },
      { value: '日用品費', text: '日用品費', class: 'daily' },
      { value: '娯楽費', text: '娯楽費', class: 'entertainment' },
      { value: '住宅費', text: '住宅費', class: 'housing' },
      { value: '交通費', text: '交通費', class: 'transport' },
      { value: 'その他', text: 'その他', class: 'other' }
    ]
    
    const toggleEdit = () => {
      isEditing.value = !isEditing.value
    }
    
    const selectCategory = (option) => {
      if (option.text !== props.categoryText) {
        emit('change-category', {
          text: option.text,
          class: option.class
        })
      }
      isEditing.value = false
    }
    
    const cancelEdit = () => {
      isEditing.value = false
    }
    
    // 外部クリックで編集モードを終了
    const handleClickOutside = (event) => {
      if (!event.target.closest('.category-tag-container')) {
        isEditing.value = false
      }
    }
    
    onMounted(() => {
      document.addEventListener('click', handleClickOutside)
    })
    
    onBeforeUnmount(() => {
      document.removeEventListener('click', handleClickOutside)
    })
    
    return {
      isEditing,
      categoryOptions,
      toggleEdit,
      selectCategory,
      cancelEdit
    }
  }
}
</script>

<style lang="scss" scoped>
.category-tag-container {
  position: relative;
  display: inline-block;
}

.category-chip {
  display: inline-flex;
  align-items: center;
  gap: $sp-1 + 1;
  padding: $sp-1 $sp-2 + 2;
  border-radius: $radius-full;
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  transition: $transition-base;
  user-select: none;

  &:hover {
    opacity: 0.82;
    transform: translateY(-1px);
    box-shadow: $shadow-sm;
  }

  &.editing {
    box-shadow: 0 0 0 2px $color-accent;
  }

  .edit-icon {
    font-size: 0.75em;
    opacity: 0.65;
  }
}

.category-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-md;
  box-shadow: $shadow-lg;
  z-index: $z-modal;
  min-width: 160px;
  padding: $sp-2 0;
  margin-top: $sp-1;
}

.dropdown-header {
  padding: $sp-2 $sp-3;
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
  color: $color-text-secondary;
  border-bottom: 1px solid $color-border-light;
  margin-bottom: $sp-1;
}

.category-option {
  padding: $sp-1 + 2 $sp-3;
  cursor: pointer;
  transition: $transition-fast;

  &:hover {
    background: $color-surface-sub;
  }

  &.active {
    background: $color-accent-light;
  }
}

.option-chip {
  display: inline-flex;
  align-items: center;
  padding: 3px $sp-2;
  border-radius: $radius-full;
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
}

.dropdown-footer {
  border-top: 1px solid $color-border-light;
  padding: $sp-2 $sp-3;
  margin-top: $sp-1;
}

.cancel-btn {
  background: $color-surface-sub;
  border: 1px solid $color-border;
  padding: $sp-1 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-xs;
  cursor: pointer;
  color: $color-text-secondary;

  &:hover {
    background: $color-border-light;
  }
}

.category-investment  { background: $color-investment;    color: #fff; }
.category-food        { background: $color-food;          color: #fff; }
.category-daily       { background: $color-daily;         color: #fff; }
.category-entertainment { background: $color-entertainment; color: #fff; }
.category-housing     { background: $color-housing;       color: #fff; }
.category-transport   { background: $color-transport;     color: $color-text-primary; }
.category-other       { background: $color-other;         color: $color-text-primary; }
</style>