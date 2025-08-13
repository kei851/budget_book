<template lang="pug">
header.header
  .header-content(v-if="currentPage === 'home'")
    h1.header__title 💰 家計簿アプリ
    p.header__subtitle 楽天カード明細から月毎の支出を可視化
  .header-content(v-else)
    .header-left
      h1.header__title 📊 詳細分析
      .header__subtitle 2024年08月
    button.nav-btn(@click="$emit('navigate', 'home')") ← メイン画面
</template>

<script>
export default {
  name: 'AppHeader',
  props: {
    currentPage: {
      type: String,
      default: 'home'
    }
  },
  emits: ['navigate']
}
</script>

<style lang="scss" scoped>
.header {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
  padding: 30px;
  
  .header-content {
    text-align: center;
  }
  
  .header-content:not(:first-child) {
    display: flex;
    justify-content: space-between;
    align-items: center;
    text-align: left;
  }
  
  &__title {
    font-size: 2.5em;
    margin-bottom: 10px;
    
    .header-content:not(:first-child) & {
      font-size: 2em;
      margin-bottom: 5px;
    }
  }
  
  &__subtitle {
    font-size: 1.1em;
    opacity: 0.9;
  }
}

.nav-btn {
  background: rgba(255,255,255,0.2);
  color: white;
  border: 1px solid rgba(255,255,255,0.3);
  padding: 10px 20px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    background: rgba(255,255,255,0.3);
  }
}
</style>