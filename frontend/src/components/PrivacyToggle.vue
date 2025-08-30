<template lang="pug">
button.privacy-btn(@click="togglePrivacy" :class="{ active: isPrivacyMode }")
  i.fas.fa-eye-slash(v-if="isPrivacyMode")
  i.fas.fa-eye(v-else)
  span.privacy-text {{ isPrivacyMode ? '金額表示' : '金額非表示' }}
</template>

<script>
export default {
  name: 'PrivacyToggle',
  props: {
    isPrivacyMode: {
      type: Boolean,
      default: false
    }
  },
  emits: ['toggle'],
  methods: {
    togglePrivacy() {
      this.$emit('toggle')
    }
  }
}
</script>

<style lang="scss" scoped>
.privacy-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 18px;
  border: 2px solid rgba(255,255,255,0.4);
  border-radius: 25px;
  background: linear-gradient(135deg, rgba(255,255,255,0.9) 0%, rgba(255,255,255,0.7) 100%);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  font-size: 14px;
  font-weight: 600;
  color: #2c3e50;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  
  &:hover {
    background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
    transform: translateY(-2px) scale(1.02);
    box-shadow: 0 8px 20px rgba(0,0,0,0.2);
    border-color: rgba(255,255,255,0.8);
  }
  
  &.active {
    background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%);
    border-color: #ff4757;
    color: white;
    box-shadow: 0 6px 16px rgba(255, 107, 107, 0.4);
    
    &:hover {
      background: linear-gradient(135deg, #ff8e53 0%, #ff6b6b 100%);
      box-shadow: 0 8px 20px rgba(255, 107, 107, 0.5);
    }
  }
  
  i {
    font-size: 16px;
  }
  
  .privacy-text {
    font-weight: 500;
  }
}

// モバイル対応
@media (max-width: 768px) {
  .privacy-btn {
    padding: 6px 12px;
    font-size: 12px;
    
    i {
      font-size: 14px;
    }
  }
}
</style>