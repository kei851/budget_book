<template lang="pug">
.hamburger-menu
  button.hamburger-btn(@click="toggleMenu" :class="{ active: isOpen }" aria-label="メニュー")
    .bar
    .bar
    .bar

  transition(name="fade")
    .overlay(v-if="isOpen" @click="closeMenu")

  .drawer(:class="{ open: isOpen }")
    .drawer-header
      span.drawer-title メニュー
      button.drawer-close(@click="closeMenu") ✕

    nav.drawer-nav
      .nav-item(v-if="currentPage !== 'home'" @click="go('home')")
        .nav-icon 🏠
        .nav-body
          .nav-label トップ
          .nav-desc メイン画面
      .nav-item(@click="go('analytics')")
        .nav-icon 📊
        .nav-body
          .nav-label 詳細分析
          .nav-desc データの詳細分析
      .nav-item(@click="go('category-rules')")
        .nav-icon 🏷️
        .nav-body
          .nav-label キーワード管理
          .nav-desc カテゴリ自動分類ルール
      .nav-item(@click="go('toggle-privacy')")
        .nav-icon {{ isPrivacyMode ? '👁️' : '🙈' }}
        .nav-body
          .nav-label {{ isPrivacyMode ? '金額表示' : '金額非表示' }}
          .nav-desc {{ isPrivacyMode ? '金額を表示します' : '金額を隠します' }}
      .nav-item(@click="go('upload-manager')")
        .nav-icon 🗑️
        .nav-body
          .nav-label CSV削除管理
          .nav-desc アップロードデータの管理
</template>

<script>
export default {
  name: 'HamburgerMenu',
  props: {
    currentPage: { type: String, default: 'home' },
    isPrivacyMode: { type: Boolean, default: false }
  },
  emits: ['navigate', 'toggle-privacy', 'show-upload-manager'],
  data() {
    return { isOpen: false }
  },
  methods: {
    toggleMenu() { this.isOpen = !this.isOpen },
    closeMenu() { this.isOpen = false },
    go(action) {
      this.closeMenu()
      const actions = {
        home: () => this.$emit('navigate', 'home'),
        analytics: () => this.$emit('navigate', 'analytics'),
        'category-rules': () => this.$emit('navigate', 'category-rules'),
        'toggle-privacy': () => this.$emit('toggle-privacy'),
        'upload-manager': () => this.$emit('show-upload-manager')
      }
      actions[action]?.()
    }
  }
}
</script>

<style lang="scss" scoped>

.hamburger-menu { position: relative; }

.hamburger-btn {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 4px;
  width: 36px;
  height: 36px;
  padding: 8px 6px;
  background: rgba(255,255,255,0.12);
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: $radius-sm;
  transition: $transition-base;

  &:hover { background: rgba(255,255,255,0.2); }

  &.active .bar {
    &:nth-child(1) { transform: rotate(45deg) translate(4px, 4px); }
    &:nth-child(2) { opacity: 0; }
    &:nth-child(3) { transform: rotate(-45deg) translate(4px, -4px); }
  }
}

.bar {
  display: block;
  height: 2px;
  width: 100%;
  background: #ffffff;
  border-radius: 1px;
  transition: $transition-base;
}

.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(2px);
  z-index: $z-overlay;
}

.drawer {
  position: fixed;
  top: 0;
  left: -100%;
  width: 300px;
  max-width: 85vw;
  height: 100vh;
  background: $color-surface;
  box-shadow: $shadow-lg;
  transition: left 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  z-index: $z-drawer;

  &.open { left: 0; }
}

.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: $sp-4 $sp-5;
  background: $color-text-primary;
  color: #ffffff;
}

.drawer-title {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
}

.drawer-close {
  background: none;
  border: none;
  color: rgba(255,255,255,0.7);
  font-size: $font-size-md;
  width: 28px;
  height: 28px;
  border-radius: $radius-sm;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: $transition-fast;

  &:hover { color: #ffffff; background: rgba(255,255,255,0.12); }
}

.drawer-nav { padding: $sp-3 0; }

.nav-item {
  display: flex;
  align-items: center;
  gap: $sp-3;
  padding: $sp-3 $sp-5;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: $transition-fast;

  &:hover {
    background: $color-accent-light;
    border-left-color: $color-accent;
  }
}

.nav-icon { font-size: 20px; width: 28px; text-align: center; flex-shrink: 0; }

.nav-label {
  font-size: $font-size-base;
  font-weight: $font-weight-medium;
  color: $color-text-primary;
}

.nav-desc {
  font-size: $font-size-sm;
  color: $color-text-muted;
  margin-top: 2px;
}

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
