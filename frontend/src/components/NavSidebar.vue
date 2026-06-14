<template lang="pug">
nav.nav-sidebar
  .nav-logo
    .logo-icon 💰
    .logo-text 家計簿

  .nav-items
    .nav-item(
      v-for="item in navItems"
      :key="item.id"
      :class="{ active: currentPage === item.id }"
      @click="handleClick(item)"
    )
      .nav-item-icon {{ item.icon }}
      .nav-item-body
        .nav-item-label {{ item.label }}
        .nav-item-desc {{ item.desc }}

  .nav-footer
    .nav-item(
      :class="{ 'privacy-active': isPrivacyMode }"
      @click="$emit('toggle-privacy')"
    )
      .nav-item-icon {{ isPrivacyMode ? '👁️' : '🙈' }}
      .nav-item-body
        .nav-item-label {{ isPrivacyMode ? '金額表示' : '金額非表示' }}
        .nav-item-desc {{ isPrivacyMode ? '金額を表示します' : '金額を隠します' }}

    .nav-item(@click="$emit('show-upload-manager')")
      .nav-item-icon 🗑️
      .nav-item-body
        .nav-item-label CSV削除管理
        .nav-item-desc アップロードデータの管理
</template>

<script>
export default {
  name: 'NavSidebar',
  props: {
    currentPage: { type: String, default: 'home' },
    isPrivacyMode: { type: Boolean, default: false }
  },
  emits: ['navigate', 'toggle-privacy', 'show-upload-manager'],
  data() {
    return {
      navItems: [
        { id: 'home', icon: '🏠', label: 'ホーム', desc: 'CSV取込・月次グラフ' },
        { id: 'analytics', icon: '📊', label: '詳細分析', desc: 'カテゴリ別・日別分析' },
        { id: 'assets', icon: '💰', label: '資産管理', desc: '残高推移・純資産' },
        { id: 'category-rules', icon: '🏷️', label: 'キーワード管理', desc: '自動分類ルール設定' },
      ]
    }
  },
  methods: {
    handleClick(item) { this.$emit('navigate', item.id) }
  }
}
</script>

<style lang="scss" scoped>
.nav-sidebar {
  width: 200px;
  min-width: 200px;
  height: calc(100vh - 40px);
  background: $color-text-primary;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: sticky;
  top: 20px;

  @media (max-width: $bp-lg) { width: 64px; min-width: 64px; }
  @media (max-width: $bp-md) { display: none; }
}

.nav-logo {
  display: flex;
  align-items: center;
  gap: $sp-3;
  padding: $sp-5 $sp-4;
  border-bottom: 1px solid rgba(255,255,255,0.1);
  flex-shrink: 0;

  @media (max-width: $bp-lg) { justify-content: center; padding: $sp-4; }
}

.logo-icon { font-size: 1.4rem; }

.logo-text {
  font-size: $font-size-md;
  font-weight: $font-weight-bold;
  color: #fff;
  white-space: nowrap;

  @media (max-width: $bp-lg) { display: none; }
}

.nav-items {
  flex: 1;
  padding: $sp-3 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow-y: auto;
}

.nav-footer {
  padding: $sp-3 0;
  border-top: 1px solid rgba(255,255,255,0.1);
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: $sp-3;
  padding: $sp-3 $sp-4;
  cursor: pointer;
  border-radius: 0;
  transition: $transition-fast;
  border-left: 3px solid transparent;
  margin: 0 $sp-2;
  border-radius: $radius-sm;

  &:hover {
    background: rgba(255,255,255,0.1);
  }

  &.active {
    background: rgba(99, 102, 241, 0.3);
    border-left-color: $color-accent;

    .nav-item-label { color: #fff; }
  }

  &.privacy-active {
    background: rgba(255,255,255,0.08);
  }

  @media (max-width: $bp-lg) {
    justify-content: center;
    padding: $sp-3;
    margin: 0 $sp-1;
  }
}

.nav-item-icon {
  font-size: 1.15rem;
  width: 24px;
  text-align: center;
  flex-shrink: 0;
}

.nav-item-body {
  min-width: 0;

  @media (max-width: $bp-lg) { display: none; }
}

.nav-item-label {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: rgba(255,255,255,0.85);
  white-space: nowrap;
}

.nav-item-desc {
  font-size: $font-size-xs;
  color: rgba(255,255,255,0.4);
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
