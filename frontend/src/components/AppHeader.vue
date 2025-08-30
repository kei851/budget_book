<template lang="pug">
header.header
  .header-menu
    HamburgerMenu(
      :current-page="currentPage"
      :isPrivacyMode="isPrivacyMode"
      @navigate="$emit('navigate', $event)"
      @toggle-privacy="$emit('toggle-privacy')"
      @show-upload-manager="$emit('show-upload-manager')"
    )
  .header-content
    .header-main
      h1.header__title {{ getPageTitle() }}
</template>

<script>
import HamburgerMenu from './HamburgerMenu.vue'

export default {
  name: 'AppHeader',
  components: {
    HamburgerMenu
  },
  props: {
    currentPage: {
      type: String,
      default: 'home'
    },
    isPrivacyMode: {
      type: Boolean,
      default: false
    }
  },
  emits: ['navigate', 'toggle-privacy', 'show-upload-manager'],
  methods: {
    getPageTitle() {
      switch(this.currentPage) {
        case 'analytics':
          return '📊 詳細分析'
        case 'category-rules':
          return '🏷️ キーワード管理'
        case 'home':
          return '💰 家計簿アプリ'
        default:
          return '💰 家計簿アプリ'
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.header {
  background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  color: white;
  padding: 30px;
  position: relative;
  
  .header-menu {
    position: absolute;
    top: 30px;
    left: 30px;
    z-index: 1000;
  }
  
  .header-content {
    display: flex;
    justify-content: center;
    align-items: center;
    
    .header-main {
      text-align: center;
    }
  }
  
  &__title {
    font-size: 2.5em;
    margin-bottom: 10px;
    margin: 0;
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

.header-right {
  display: flex;
  align-items: center;
  gap: 15px;
}

.privacy-toggle-header {
  transform: scale(0.85);
}

.header-privacy-toggle {
  margin-top: 15px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
}

.manage-btn {
  background: linear-gradient(135deg, rgba(255,255,255,0.95) 0%, rgba(255,255,255,0.85) 100%);
  color: #2c3e50;
  border: 2px solid rgba(255,255,255,0.7);
  padding: 12px 24px;
  border-radius: 30px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  font-size: 16px;
  font-weight: 700;
  text-shadow: none;
  box-shadow: 0 6px 16px rgba(0,0,0,0.2);
  backdrop-filter: blur(10px);
  letter-spacing: 0.5px;
  
  &:hover {
    background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
    transform: translateY(-4px) scale(1.02);
    box-shadow: 0 12px 28px rgba(0,0,0,0.25);
    border-color: rgba(255,255,255,0.9);
  }
  
  &:active {
    transform: translateY(-2px) scale(1);
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
  }
}

.rules-btn {
  background: linear-gradient(135deg, #ffd700 0%, #ffb347 100%);
  border: 2px solid #ff8c00;
  color: #8b4513;
  box-shadow: 0 6px 16px rgba(255, 215, 0, 0.4);
  
  &:hover {
    background: linear-gradient(135deg, #ffed4a 0%, #ffd700 100%);
    border-color: #ff6347;
    box-shadow: 0 12px 28px rgba(255, 215, 0, 0.5);
    transform: translateY(-4px) scale(1.02);
  }
}
</style>