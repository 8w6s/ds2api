package claude

import "neutronapi/internal/prompt"

func buildClaudePromptTokenText(messages []any, thinkingEnabled bool) string {
	return prompt.MessagesPrepareWithThinking(toMessageMaps(messages), thinkingEnabled)
}
