<template lang="pug">
footer.footer
  p.footer-text created by Onishi
</template>

<script>
export default { name: 'AppFooter' }
</script>

<style lang="scss" scoped>

.footer {
  padding: $sp-4 $sp-6;
  border-top: 1px solid $color-border;
  text-align: center;
}

.footer-text {
  font-size: $font-size-sm;
  color: $color-text-muted;
}
</style>
