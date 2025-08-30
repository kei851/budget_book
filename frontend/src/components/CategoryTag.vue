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
  gap: 5px;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
  
  &:hover {
    opacity: 0.8;
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  }
  
  &.editing {
    box-shadow: 0 0 0 2px #4CAF50;
  }
  
  .edit-icon {
    font-size: 0.7em;
    opacity: 0.7;
  }
}

.category-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  background: white;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  z-index: 1000;
  min-width: 160px;
  padding: 8px 0;
  margin-top: 4px;
}

.dropdown-header {
  padding: 8px 12px;
  font-size: 0.8em;
  font-weight: 600;
  color: #666;
  border-bottom: 1px solid #f0f0f0;
  margin-bottom: 4px;
}

.category-option {
  padding: 6px 12px;
  cursor: pointer;
  transition: background 0.2s ease;
  
  &:hover {
    background: #f8f9fa;
  }
  
  &.active {
    background: #e8f5e8;
  }
}

.option-chip {
  display: inline-flex;
  align-items: center;
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 0.8em;
  font-weight: bold;
}

.dropdown-footer {
  border-top: 1px solid #f0f0f0;
  padding: 8px 12px;
  margin-top: 4px;
}

.cancel-btn {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 0.8em;
  cursor: pointer;
  
  &:hover {
    background: #e9ecef;
  }
}

// カテゴリ別の色設定（DBのseedsと同じ色に統一）
.category-investment {
  background: #FF6384;
  color: white;
}

.category-food {
  background: #4BC0C0;
  color: white;
}

.category-daily {
  background: #9966FF;
  color: white;
}

.category-entertainment {
  background: #36A2EB;
  color: white;
}

.category-housing {
  background: #FF9F40;
  color: white;
}

.category-transport {
  background: #FFCE56;
  color: black;
}

.category-other {
  background: #C9CBCF;
  color: black;
}
</style>