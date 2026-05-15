package toolcall

import (
	"strings"
	"testing"
)

// Nested backticks: 4 backticks nesting 3 backticks
func TestStripFencedCodeBlocks_NestedFourBackticks(t *testing.T) {
	text := "Before\n\x60\x60\x60\x60markdown\nHere is \x60\x60\x60 nested \x60\x60\x60 example\n\x60\x60\x60\x60\nAfter"
	got := stripFencedCodeBlocks(text)
	if !strings.Contains(got, "Before") || !strings.Contains(got, "After") {
		t.Fatalf("expected Before and After preserved, got %q", got)
	}
	if strings.Contains(got, "nested") {
		t.Fatalf("expected nested content stripped, got %q", got)
	}
}

// Tilde fence
func TestStripFencedCodeBlocks_TildeFence(t *testing.T) {
	text := "Before\n~~~python\ncode here\n~~~\nAfter"
	got := stripFencedCodeBlocks(text)
	if !strings.Contains(got, "Before") || !strings.Contains(got, "After") {
		t.Fatalf("expected Before/After, got %q", got)
	}
	if strings.Contains(got, "code here") {
		t.Fatalf("expected code stripped, got %q", got)
	}
}

// Unclosed fence + real tool call following: should not return empty string
func TestStripFencedCodeBlocks_UnclosedFencePreservesToolCall(t *testing.T) {
	text := "Example:\n\x60\x60\x60xml\n<tool_calls><invoke name=\"read_file\"><parameter name=\"path\">README.md</parameter></invoke></tool_calls>\n\n<tool_calls><invoke name=\"search\"><parameter name=\"q\">go</parameter></invoke></tool_calls>"
	got := stripFencedCodeBlocks(text)
	if got == "" {
		t.Fatalf("unclosed fence should not truncate everything — real tool call after the fence is lost")
	}
}

// Fences inside CDATA should not be stripped
func TestStripFencedCodeBlocks_FenceInsideCDATA(t *testing.T) {
	text := "<tool_calls><invoke name=\"write\">\n<parameter name=\"content\"><![CDATA[\n\x60\x60\x60python\nprint('hello')\n\x60\x60\x60\n]]></parameter>\n</invoke></tool_calls>"
	got := stripFencedCodeBlocks(text)
	if !strings.Contains(got, "\x60\x60\x60python") {
		t.Fatalf("fenced code inside CDATA should be preserved, got %q", got)
	}
}

// Multiple consecutive fences
func TestStripFencedCodeBlocks_MultipleFences(t *testing.T) {
	text := "Before\n\x60\x60\x60\nfence1\n\x60\x60\x60\nMiddle\n\x60\x60\x60\nfence2\n\x60\x60\x60\nAfter"
	got := stripFencedCodeBlocks(text)
	if !strings.Contains(got, "Before") || !strings.Contains(got, "Middle") || !strings.Contains(got, "After") {
		t.Fatalf("expected non-fenced content preserved, got %q", got)
	}
}

// Fence contains inline backticks but not on its own line
func TestStripFencedCodeBlocks_InlineBackticksNotFence(t *testing.T) {
	text := "Before\n\x60\x60\x60go\nfmt.Println(\x60\x60\x60hello\x60\x60\x60)\n\x60\x60\x60\nAfter"
	got := stripFencedCodeBlocks(text)
	if !strings.Contains(got, "Before") || !strings.Contains(got, "After") {
		t.Fatalf("expected Before/After, got %q", got)
	}
}

func TestParseToolCalls_IgnoresMarkdownDocumentationExamples(t *testing.T) {
	text := "The parser supports multiple tool call formats.\n\n" +
		"The entry function `ParseToolCalls(text, availableToolNames)` returns a list of calls.\n\n" +
		"The core process parses XML-formatted `<tool_calls>` / `<invoke>` tags.\n\n" +
		"### Standard XML Structure\n" +
		"```xml\n" +
		"<tool_calls>\n" +
		"  <invoke name=\"read_file\">\n" +
		"    <parameter name=\"path\">config.json</parameter>\n" +
		"  </invoke>\n" +
		"</tool_calls>\n" +
		"```\n\n" +
		"DSML style is like `<invoke name=\"tool\">...</invoke>`, and may mention `<tool_calls>` wrapper.\n"

	got := ParseToolCallsDetailed(text, []string{"read_file"})
	if len(got.Calls) != 0 {
		t.Fatalf("markdown documentation examples should not parse as tool calls, got %#v", got.Calls)
	}
}

func TestParseToolCalls_IgnoresInlineMarkdownToolCallExample(t *testing.T) {
	text := "Example: `<tool_calls><invoke name=\"read_file\"><parameter name=\"path\">README.md</parameter></invoke></tool_calls>`"

	got := ParseToolCallsDetailed(text, []string{"read_file"})
	if len(got.Calls) != 0 {
		t.Fatalf("inline markdown tool example should not parse as tool calls, got %#v", got.Calls)
	}
}

func TestParseToolCalls_PreservesBackticksInsideToolParameters(t *testing.T) {
	text := "<tool_calls><invoke name=\"Bash\"><parameter name=\"command\">echo `date`</parameter></invoke></tool_calls>"

	got := ParseToolCallsDetailed(text, []string{"Bash"})
	if len(got.Calls) != 1 {
		t.Fatalf("expected one tool call, got %#v", got.Calls)
	}
	if got.Calls[0].Input["command"] != "echo `date`" {
		t.Fatalf("expected command backticks preserved, got %#v", got.Calls[0].Input["command"])
	}
}
