<template lang="pug">
.category-tag-container
  span.category-tag(
    :class="category"
    @click="toggleDropdown"
  ) {{ categoryText }}
    .category-dropdown(:class="{ show: showDropdown }")
      .category-option(@click="changeCategory('investment', '投資')") 投資
      .category-option(@click="changeCategory('food', '食費')") 食費
      .category-option(@click="changeCategory('daily', '日用品費')") 日用品費
      .category-option(@click="changeCategory('entertainment', '娯楽費')") 娯楽費
      .category-option(@click="changeCategory('housing', '住宅費')") 住宅費
      .category-option(@click="changeCategory('transport', '交通費')") 交通費
      .category-option(@click="changeCategory('other', 'その他')") その他
</template>

<script>
import { ref, onMounted, onUnmounted } from 'vue'

export default {
  name: 'CategoryTag',
  props: {
    category: {
      type: String,
      required: true
    },
    categoryText: {
      type: String,
      required: true
    }
  },
  emits: ['change-category'],
  setup(props, { emit }) {
    const showDropdown = ref(false)
    
    const toggleDropdown = () => {
      showDropdown.value = !showDropdown.value
    }
    
    const changeCategory = (category, text) => {
      emit('change-category', { category, text })
      showDropdown.value = false
    }
    
    const handleClickOutside = (event) => {
      if (!event.target.closest('.category-tag-container')) {
        showDropdown.value = false
      }
    }
    
    onMounted(() => {
      document.addEventListener('click', handleClickOutside)
    })
    
    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside)
    })
    
    return {
      showDropdown,
      toggleDropdown,
      changeCategory
    }
  }
}
</script>

<style lang="scss" scoped>
.category-tag-container {
  position: relative;
  display: inline-block;
}

.category-tag {
  background: #4CAF50;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  cursor: pointer;
  position: relative;
  display: inline-block;
  transition: all 0.2s ease;
  
  &:hover {
    opacity: 0.8;
    transform: scale(1.05);
  }
  
  &.investment { background: #FF6384; }
  &.food { background: #4BC0C0; }
  &.daily { background: #9966FF; }
  &.entertainment { background: #36A2EB; }
  &.housing { background: #FF9F40; }
  &.transport { background: #FFCE56; color: #333; }
  &.other { background: #C9CBCF; color: #333; }
}

.category-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  background: white;
  border: 1px solid #dee2e6;
  border-radius: 5px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
  min-width: 120px;
  z-index: 9999;
  display: none;
  
  &.show {
    display: block;
  }
}

.category-option {
  padding: 8px 12px;
  cursor: pointer;
  border-bottom: 1px solid #f8f9fa;
  font-size: 0.9em;
  color: #333;
  
  &:hover {
    background: #f8f9fa;
  }
  
  &:last-child {
    border-bottom: none;
  }
}
</style>