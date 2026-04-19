<template lang="pug">
#app
  .container
    AppHeader(
      @navigate="handleNavigation"
      :current-page="currentPage"
      :isPrivacyMode="isPrivacyMode"
      @toggle-privacy="togglePrivacyMode"
      @show-upload-manager="showUploadManager = true"
    )
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

  UploadManager(
    v-if="showUploadManager"
    @close="showUploadManager = false"
    @data-updated="handleDataUpdated"
  )
</template>

<script>
import { ref, computed, KeepAlive } from 'vue'
import AppHeader from './components/AppHeader.vue'
import AppFooter from './components/AppFooter.vue'
import HomePage from './components/HomePage.vue'
import AnalyticsPage from './components/AnalyticsPage.vue'
import CategoryRulesPage from './components/CategoryRulesPage.vue'
import UploadManager from './components/UploadManager.vue'

export default {
  name: 'App',
  components: { AppHeader, AppFooter, HomePage, AnalyticsPage, CategoryRulesPage, UploadManager, KeepAlive },
  setup() {
    const currentPage = ref('home')
    const isPrivacyMode = ref(false)
    const showUploadManager = ref(false)
    const chartNavigationState = ref({
      canGoPrevious: false, canGoNext: false, totalMonths: 0, currentOffset: 0, availableMonths: []
    })

    const currentPageComponent = computed(() => {
      switch (currentPage.value) {
        case 'analytics': return 'AnalyticsPage'
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
      chartNavigationState, handleNavigation, togglePrivacyMode,
      handleDataUpdated, handleChartNavigationUpdated
    }
  }
}
</script>

<style lang="scss">
@import './styles/main.scss';

#app {
  min-height: 100vh;
  background: #f0f2f5;
  padding: 20px;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.06), 0 2px 4px rgba(0,0,0,0.04);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 40px);
}

.content {
  flex: 1;
  padding: 32px;
}

@media (max-width: 768px) {
  #app { padding: 0; }
  .container { border-radius: 0; min-height: 100vh; }
  .content { padding: 16px; }
}
</style>
