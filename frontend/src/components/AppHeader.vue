<template lang="pug">
header.header
  .header-inner
    .header-left
      HamburgerMenu(
        :current-page="currentPage"
        :isPrivacyMode="isPrivacyMode"
        @navigate="$emit('navigate', $event)"
        @toggle-privacy="$emit('toggle-privacy')"
        @show-upload-manager="$emit('show-upload-manager')"
      )
    .header-center
      h1.header-title {{ pageTitle }}
</template>

<script>
import HamburgerMenu from './HamburgerMenu.vue'

export default {
  name: 'AppHeader',
  components: { HamburgerMenu },
  props: {
    currentPage: { type: String, default: 'home' },
    isPrivacyMode: { type: Boolean, default: false }
  },
  emits: ['navigate', 'toggle-privacy', 'show-upload-manager'],
  computed: {
    pageTitle() {
      const titles = { analytics: '詳細分析', 'category-rules': 'キーワード管理', home: '家計簿' }
      return titles[this.currentPage] ?? '家計簿'
    }
  }
}
</script>

<style lang="scss" scoped>

.header {
  background: $color-text-primary;
  padding: $sp-4 $sp-6;
}

.header-inner {
  display: flex;
  align-items: center;
  gap: $sp-4;
}

.header-left {
  flex-shrink: 0;
}

.header-center {
  flex: 1;
  display: flex;
  justify-content: center;
}

.header-title {
  font-size: $font-size-lg;
  font-weight: $font-weight-semibold;
  color: #ffffff;
  letter-spacing: -0.01em;
}
</style>
