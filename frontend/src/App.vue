<template lang="pug">
#app
  .app-layout
    NavSidebar(
      :current-page="currentPage"
      :isPrivacyMode="isPrivacyMode"
      @navigate="handleNavigation"
      @toggle-privacy="togglePrivacyMode"
      @show-upload-manager="showUploadManager = true"
    )

    .container
      main.content
        KeepAlive
          component(
            :is="currentPageComponent"
            :key="currentPage"
            :isPrivacyMode="isPrivacyMode"
            :chartNavigationState="chartNavigationState"
            @navigate="handleNavigation"
            @chart-navigation-updated="handleChartNavigationUpdated"
          )
      AppFooter

  AiChatPanel

  .mobile-header
    .mobile-logo
      span.mobile-logo-icon 💰
      span.mobile-logo-text 家計簿
    .mobile-nav
      button.mobile-nav-btn(
        v-for="item in mobileNavItems"
        :key="item.id"
        :class="{ active: currentPage === item.id }"
        @click="handleNavigation(item.id)"
      ) {{ item.icon }}
    .mobile-actions
      button.mobile-action-btn(@click="togglePrivacyMode") {{ isPrivacyMode ? '👁️' : '🙈' }}
      button.mobile-action-btn(@click="showUploadManager = true") 🗑️

  UploadManager(
    v-if="showUploadManager"
    @close="showUploadManager = false"
    @data-updated="handleDataUpdated"
  )
</template>

<script>
import { ref, computed, KeepAlive } from 'vue'
import AppFooter from './components/AppFooter.vue'
import HomePage from './components/HomePage.vue'
import AnalyticsPage from './components/AnalyticsPage.vue'
import AssetPage from './components/AssetPage.vue'
import CategoryRulesPage from './components/CategoryRulesPage.vue'
import UploadManager from './components/UploadManager.vue'
import AiChatPanel from './components/AiChatPanel.vue'
import NavSidebar from './components/NavSidebar.vue'

export default {
  name: 'App',
  components: { AppFooter, HomePage, AnalyticsPage, AssetPage, CategoryRulesPage, UploadManager, AiChatPanel, NavSidebar, KeepAlive },
  setup() {
    const currentPage = ref('home')
    const isPrivacyMode = ref(false)
    const showUploadManager = ref(false)
    const chartNavigationState = ref({
      canGoPrevious: false, canGoNext: false, totalMonths: 0, currentOffset: 0, availableMonths: []
    })

    const mobileNavItems = [
      { id: 'home', icon: '🏠' },
      { id: 'analytics', icon: '📊' },
      { id: 'assets', icon: '💰' },
      { id: 'category-rules', icon: '🏷️' },
    ]

    const currentPageComponent = computed(() => {
      switch (currentPage.value) {
        case 'analytics': return 'AnalyticsPage'
        case 'assets': return 'AssetPage'
        case 'category-rules': return 'CategoryRulesPage'
        default: return 'HomePage'
      }
    })

    const handleNavigation = (page) => { currentPage.value = page }
    const togglePrivacyMode = () => { isPrivacyMode.value = !isPrivacyMode.value }
    const handleDataUpdated = () => {}
    const handleChartNavigationUpdated = (state) => { chartNavigationState.value = state }

    return {
      currentPage, currentPageComponent, isPrivacyMode, showUploadManager,
      chartNavigationState, mobileNavItems,
      handleNavigation, togglePrivacyMode,
      handleDataUpdated, handleChartNavigationUpdated
    }
  }
}
</script>

<style lang="scss">
@import './styles/main.scss';

* { box-sizing: border-box; }

#app {
  min-height: 100vh;
  background: $color-bg;
  padding: 20px;

  @media (max-width: $bp-md) {
    padding: 0;
    padding-top: 56px;
  }
}

.app-layout {
  max-width: 1680px;
  margin: 0 auto;
  display: flex;
  gap: 16px;
  align-items: flex-start;

  @media (max-width: $bp-md) { flex-direction: column; gap: 0; }
}

.container {
  flex: 1;
  min-width: 0;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.06), 0 2px 4px rgba(0,0,0,0.04);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 40px);

  @media (max-width: $bp-md) {
    border-radius: 0;
    min-height: calc(100vh - 56px);
  }
}

.content {
  flex: 1;
  padding: 32px;

  @media (max-width: $bp-md) { padding: 16px; }
}

// モバイル用ヘッダー
.mobile-header {
  display: none;

  @media (max-width: $bp-md) {
    display: flex;
    align-items: center;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 56px;
    background: $color-text-primary;
    padding: 0 $sp-4;
    z-index: $z-overlay;
    gap: $sp-3;
  }
}

.mobile-logo {
  display: flex;
  align-items: center;
  gap: $sp-2;
  flex-shrink: 0;

  .mobile-logo-icon { font-size: 1.2rem; }
  .mobile-logo-text {
    font-size: $font-size-base;
    font-weight: $font-weight-bold;
    color: #fff;
  }
}

.mobile-nav {
  display: flex;
  align-items: center;
  gap: $sp-1;
  flex: 1;
  justify-content: center;
}

.mobile-nav-btn {
  width: 36px;
  height: 36px;
  border-radius: $radius-sm;
  border: none;
  background: transparent;
  font-size: 1.1rem;
  cursor: pointer;
  transition: $transition-fast;

  &.active { background: rgba(99,102,241,0.4); }
  &:hover { background: rgba(255,255,255,0.1); }
}

.mobile-actions {
  display: flex;
  gap: $sp-1;
}

.mobile-action-btn {
  width: 36px;
  height: 36px;
  border-radius: $radius-sm;
  border: none;
  background: transparent;
  font-size: 1rem;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: rgba(255,255,255,0.1); }
}
</style>
