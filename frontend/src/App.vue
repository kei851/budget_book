<template lang="pug">
#app
  .container
    AppHeader(
      @navigate="handleNavigation" 
      :current-page="currentPage"
    )
    main.content
      component(
        :is="currentPageComponent"
        @navigate="handleNavigation"
      )
    AppFooter
</template>

<script>
import { ref, computed } from 'vue'
import AppHeader from './components/AppHeader.vue'
import AppFooter from './components/AppFooter.vue'
import HomePage from './components/HomePage.vue'
import AnalyticsPage from './components/AnalyticsPage.vue'

export default {
  name: 'App',
  components: {
    AppHeader,
    AppFooter,
    HomePage,
    AnalyticsPage
  },
  setup() {
    const currentPage = ref('home')
    
    const currentPageComponent = computed(() => {
      return currentPage.value === 'analytics' ? 'AnalyticsPage' : 'HomePage'
    })
    
    const handleNavigation = (page) => {
      currentPage.value = page
    }
    
    return {
      currentPage,
      currentPageComponent,
      handleNavigation
    }
  }
}
</script>

<style lang="scss">
@import './styles/main.scss';

#app {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  padding: 20px;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  background: white;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.3);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 40px);
}

.content {
  flex: 1;
  padding: 30px;
}
</style>