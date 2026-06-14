<template lang="pug">
.ai-chat-floating
  transition(name="panel")
    .ai-panel(v-if="isOpen")
      .panel-header
        .panel-header-left
          .panel-avatar ✨
          .panel-header-info
            .panel-title AI家計アドバイザー
            .panel-subtitle powered by Claude
        button.panel-close(@click="isOpen = false") ✕

      .chat-messages(ref="messagesContainer")
        .chat-welcome(v-if="messages.length === 0")
          .welcome-icon 💬
          p.welcome-text こんにちは！家計に関することなら何でも相談してください。現金の支出も話しかけて記録できます。

        .message-group(v-for="(msg, i) in messages" :key="i")
          .message(:class="msg.role === 'user' ? 'message-user' : 'message-ai'")
            .message-bubble(v-if="msg.role === 'user'") {{ msg.content }}
            .message-bubble(v-else :class="{ 'message-bubble-success': msg.isToolResult }")
              span(v-if="msg.streaming && !msg.content")
                .typing-indicator
                  span
                  span
                  span
              span(v-else) {{ msg.content }}

      .chat-input-area
        .chat-input-wrapper
          textarea.chat-input(
            v-model="inputText"
            placeholder="メッセージを入力... (Enter で送信)"
            rows="1"
            @keydown.enter.exact.prevent="sendMessage"
            @input="autoResize"
            ref="inputRef"
            :disabled="isStreaming"
          )
          button.chat-send(:disabled="!inputText.trim() || isStreaming" @click="sendMessage")
            svg(viewBox="0 0 24 24" width="16" height="16" fill="currentColor")
              path(d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z")

  button.chat-toggle(@click="isOpen = !isOpen" :class="{ open: isOpen }")
    span(v-if="!isOpen") 💬
    span(v-else) ✕
</template>

<script>
import { ref, nextTick } from 'vue'

const API_BASE_URL = 'http://localhost:3001/api/v1'

export default {
  name: 'AiChatPanel',
  setup() {
    const isOpen = ref(false)
    const isStreaming = ref(false)
    const inputText = ref('')
    const messages = ref([])
    const messagesContainer = ref(null)
    const inputRef = ref(null)

    const scrollToBottom = () => {
      nextTick(() => {
        if (messagesContainer.value) {
          messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
        }
      })
    }

    const autoResize = () => {
      const el = inputRef.value
      if (!el) return
      el.style.height = 'auto'
      el.style.height = Math.min(el.scrollHeight, 120) + 'px'
    }

    const sendMessage = async () => {
      const text = inputText.value.trim()
      if (!text || isStreaming.value) return

      messages.value.push({ role: 'user', content: text })
      inputText.value = ''
      if (inputRef.value) { inputRef.value.style.height = 'auto' }
      scrollToBottom()

      const aiMsg = { role: 'assistant', content: '', streaming: true }
      messages.value.push(aiMsg)
      const aiIndex = messages.value.length - 1
      isStreaming.value = true
      scrollToBottom()

      const historyForApi = messages.value
        .slice(0, -1)
        .filter(m => m.role === 'user' || (m.role === 'assistant' && m.content))
        .map(m => ({ role: m.role, content: m.content }))

      try {
        const response = await fetch(`${API_BASE_URL}/ai/chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ messages: historyForApi })
        })

        if (!response.ok) throw new Error('チャットエラー')

        const reader = response.body.getReader()
        const decoder = new TextDecoder()
        let buffer = ''

        while (true) {
          const { done, value } = await reader.read()
          if (done) break

          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split('\n')
          buffer = lines.pop()

          for (const line of lines) {
            if (!line.startsWith('data: ')) continue
            const data = line.slice(6)
            if (data === '[DONE]') break
            try {
              const parsed = JSON.parse(data)
              if (parsed && typeof parsed === 'object' && parsed.type === 'tool_result') {
                messages.value[aiIndex].content = parsed.message
                messages.value[aiIndex].isToolResult = true
              } else {
                messages.value[aiIndex].content += parsed
              }
              scrollToBottom()
            } catch (_) {}
          }
        }
      } catch (e) {
        messages.value[aiIndex].content = 'エラーが発生しました。クレジット残高を確認してください。'
      } finally {
        messages.value[aiIndex].streaming = false
        isStreaming.value = false
        scrollToBottom()
      }
    }

    return {
      isOpen, isStreaming, inputText, messages,
      messagesContainer, inputRef,
      sendMessage, autoResize
    }
  }
}
</script>

<style lang="scss" scoped>
.ai-chat-floating {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: $sp-3;
}

.chat-toggle {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: linear-gradient(135deg, $color-accent 0%, #7c3aed 100%);
  border: none;
  color: #fff;
  font-size: 1.3rem;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.4);
  transition: $transition-base;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;

  &:hover { transform: scale(1.08); box-shadow: 0 6px 16px rgba(99, 102, 241, 0.5); }
}

.ai-panel {
  width: 340px;
  height: 520px;
  background: $color-surface;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.16), 0 2px 8px rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
  overflow: hidden;

  @media (max-width: $bp-md) {
    width: calc(100vw - 48px);
    height: 70vh;
  }
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: $sp-4 $sp-5;
  background: linear-gradient(135deg, $color-accent 0%, #7c3aed 100%);
  color: #fff;
  flex-shrink: 0;
  border-radius: 16px 16px 0 0;
}

.panel-header-left {
  display: flex;
  align-items: center;
  gap: $sp-3;
}

.panel-avatar {
  width: 32px;
  height: 32px;
  background: rgba(255,255,255,0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
}

.panel-title {
  font-size: $font-size-base;
  font-weight: $font-weight-semibold;
}

.panel-subtitle {
  font-size: $font-size-xs;
  opacity: 0.75;
  margin-top: 1px;
}

.panel-close {
  background: rgba(255,255,255,0.15);
  border: none;
  color: #fff;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: $transition-fast;

  &:hover { background: rgba(255,255,255,0.3); }
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: $sp-4;
  display: flex;
  flex-direction: column;
  gap: $sp-3;
  scroll-behavior: smooth;

  &::-webkit-scrollbar { width: 4px; }
  &::-webkit-scrollbar-thumb { background: $color-border; border-radius: $radius-full; }
}

.chat-welcome {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: $sp-3;
  padding: $sp-6 $sp-3;
  text-align: center;

  .welcome-icon { font-size: 1.8rem; }
  .welcome-text {
    font-size: $font-size-sm;
    color: $color-text-secondary;
    line-height: 1.65;
    margin: 0;
  }
}

.message { display: flex; }
.message-user { justify-content: flex-end; }
.message-ai { justify-content: flex-start; }

.message-bubble {
  max-width: 85%;
  padding: $sp-2 + 2 $sp-3;
  border-radius: $radius-lg;
  font-size: $font-size-sm;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;

  .message-user & {
    background: linear-gradient(135deg, $color-accent 0%, #7c3aed 100%);
    color: #fff;
    border-bottom-right-radius: $radius-sm;
  }

  .message-ai & {
    background: $color-surface-sub;
    color: $color-text-primary;
    border: 1px solid $color-border-light;
    border-bottom-left-radius: $radius-sm;

    &.message-bubble-success {
      background: #e8f5e9;
      border-color: #a5d6a7;
      color: #2e7d32;
    }
  }
}

.typing-indicator {
  display: flex;
  gap: 4px;
  padding: 2px 2px;

  span {
    width: 5px;
    height: 5px;
    background: $color-text-muted;
    border-radius: 50%;
    animation: typing-bounce 1.2s infinite ease-in-out;

    &:nth-child(1) { animation-delay: 0s; }
    &:nth-child(2) { animation-delay: 0.2s; }
    &:nth-child(3) { animation-delay: 0.4s; }
  }
}

@keyframes typing-bounce {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
  40% { transform: scale(1); opacity: 1; }
}

.chat-input-area {
  padding: $sp-3;
  border-top: 1px solid $color-border-light;
  flex-shrink: 0;
  background: $color-surface;
}

.chat-input-wrapper {
  display: flex;
  align-items: flex-end;
  gap: $sp-2;
  background: $color-surface-sub;
  border: 1px solid $color-border;
  border-radius: $radius-lg;
  padding: $sp-2 $sp-2 $sp-2 $sp-3;
  transition: $transition-fast;

  &:focus-within {
    border-color: $color-accent;
    box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.12);
  }
}

.chat-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: $font-size-sm;
  color: $color-text-primary;
  resize: none;
  line-height: 1.5;
  max-height: 100px;
  min-height: 20px;
  outline: none;
  font-family: $font-family;

  &::placeholder { color: $color-text-muted; }
  &:disabled { opacity: 0.5; }
}

.chat-send {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: $color-accent;
  border: none;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: $transition-fast;
  flex-shrink: 0;

  &:hover:not(:disabled) {
    background: $color-accent-hover;
    transform: scale(1.05);
  }

  &:disabled {
    background: $color-border;
    cursor: not-allowed;
    transform: none;
  }
}

.panel-enter-active, .panel-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.panel-enter-from, .panel-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.97);
}
</style>
