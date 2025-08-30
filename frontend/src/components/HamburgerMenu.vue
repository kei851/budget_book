<template lang="pug">
.hamburger-menu
  // ハンバーガーボタン
  button.hamburger-btn(@click="toggleMenu" :class="{ active: isOpen }")
    .hamburger-icon
      span
      span  
      span
  
  // メニューオーバーレイ
  .menu-overlay(v-if="isOpen" @click="closeMenu")
  
  // メニューコンテンツ
  .menu-content(:class="{ open: isOpen }")
    .menu-header
      h3 📋 メニュー
      button.close-btn(@click="closeMenu") ×
    
    .menu-items
      .menu-item(@click="handleMenuAction('home')" v-if="currentPage !== 'home'")
        .menu-icon 🏠
        .menu-text
          .menu-title トップに戻る
          .menu-description メイン画面に戻る
      
      .menu-item(@click="handleMenuAction('analytics')")
        .menu-icon 📊
        .menu-text
          .menu-title 詳細分析
          .menu-description データの詳細分析
      
      .menu-item(@click="handleMenuAction('toggle-privacy')")
        .menu-icon {{ isPrivacyMode ? '👁️' : '🙈' }}
        .menu-text
          .menu-title {{ isPrivacyMode ? '金額表示' : '金額非表示' }}
          .menu-description {{ isPrivacyMode ? '金額を表示します' : '金額を隠します' }}
      
      .menu-item(@click="handleMenuAction('upload-manager')")
        .menu-icon 🗑️
        .menu-text
          .menu-title CSV削除管理
          .menu-description アップロードデータの管理
      
      .menu-item(@click="handleMenuAction('category-rules')")
        .menu-icon 🏷️
        .menu-text
          .menu-title キーワード管理
          .menu-description カテゴリ自動分類ルールの設定
</template>

<script>
export default {
  name: 'HamburgerMenu',
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
  data() {
    return {
      isOpen: false
    }
  },
  methods: {
    toggleMenu() {
      this.isOpen = !this.isOpen
    },
    closeMenu() {
      this.isOpen = false
    },
    handleMenuAction(action) {
      this.closeMenu()
      
      switch(action) {
        case 'home':
          this.$emit('navigate', 'home')
          break
        case 'analytics':
          this.$emit('navigate', 'analytics')
          break
        case 'category-rules':
          this.$emit('navigate', 'category-rules')
          break
        case 'toggle-privacy':
          this.$emit('toggle-privacy')
          break
        case 'upload-manager':
          this.$emit('show-upload-manager')
          break
      }
    }
  }
}
</script>

<style lang="scss" scoped>
@import "../styles/variables.scss";

.hamburger-menu {
  position: relative;
}

.hamburger-btn {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: 44px;
  height: 44px;
  background: linear-gradient(135deg, rgba(255,255,255,0.9) 0%, rgba(255,255,255,0.7) 100%);
  border: 2px solid rgba(255,255,255,0.6);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  
  &:hover {
    background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
    transform: translateY(-2px) scale(1.05);
    box-shadow: 0 8px 20px rgba(0,0,0,0.2);
  }
  
  &.active {
    background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);
    border-color: #ff4757;
    
    .hamburger-icon span {
      background: white;
      
      &:nth-child(1) {
        transform: rotate(45deg) translate(5px, 5px);
      }
      
      &:nth-child(2) {
        opacity: 0;
      }
      
      &:nth-child(3) {
        transform: rotate(-45deg) translate(7px, -6px);
      }
    }
  }
}

.hamburger-icon {
  width: 20px;
  height: 15px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  
  span {
    display: block;
    height: 2px;
    width: 100%;
    background: #2c3e50;
    border-radius: 1px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }
}

.menu-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.5);
  backdrop-filter: blur(3px);
  z-index: 9998;
}

.menu-content {
  position: fixed;
  top: 0;
  left: -100%;
  width: 350px;
  max-width: 90vw;
  height: 100vh;
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  box-shadow: 10px 0 30px rgba(0,0,0,0.3);
  transition: left 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  z-index: 9999;
  transform: translateZ(0); // ハードウェアアクセラレーション
  
  &.open {
    left: 0;
  }
}

.menu-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid #e9ecef;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  
  h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
  }
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: white;
  cursor: pointer;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s ease;
  
  &:hover {
    background: rgba(255,255,255,0.2);
  }
}

.menu-items {
  padding: 20px 0;
}

.menu-item {
  display: flex;
  align-items: flex-start;
  padding: 15px 25px;
  cursor: pointer;
  transition: all 0.3s ease;
  border-left: 4px solid transparent;
  
  &:hover {
    background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
    border-left-color: #667eea;
    transform: translateX(5px);
  }
}

.menu-icon {
  font-size: 24px;
  width: 40px;
  min-width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 2px;
}

.menu-text {
  margin-left: 15px;
  flex: 1;
  line-height: 1.4;
  text-align: left;
}

.menu-title {
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 4px;
  text-align: left;
}

.menu-description {
  font-size: 13px;
  color: #6c757d;
  text-align: left;
  line-height: 1.3;
}

// モバイル対応
@media (max-width: 768px) {
  .menu-content {
    width: 280px;
  }
  
  .menu-item {
    padding: 12px 20px;
  }
  
  .menu-icon {
    font-size: 20px;
    width: 35px;
  }
}
</style>