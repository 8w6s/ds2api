package client

import (
	"compress/gzip"
	"crypto/sha256"
	"io"
	"math/rand"
	"net/http"
	"strings"

	"github.com/andybalholm/brotli"
)

var userAgentPool = []string{
	"DeepSeek/2.1.2 Android/35 (Google; Pixel 9 Pro)",
	"DeepSeek/2.1.2 Android/34 (Samsung; SM-S928B)",
	"DeepSeek/2.1.2 Android/33 (Xiaomi; 23127PN0CC)",
	"DeepSeek/2.1.2 Android/35 (Nothing; A065)",
	"DeepSeek/2.1.2 Android/34 (OnePlus; CPH2581)",
}

func (c *Client) randomUserAgent(identifier string) string {
	if identifier == "" {
		return userAgentPool[rand.Intn(len(userAgentPool))]
	}
	// Sinh UA ổn định theo account để tránh đổi máy liên tục trong 1 session
	sum := sha256.Sum256([]byte(identifier + "_ua_salt"))
	idx := int(sum[0]) % len(userAgentPool)
	return userAgentPool[idx]
}

func readResponseBody(resp *http.Response) ([]byte, error) {
	encoding := strings.ToLower(strings.TrimSpace(resp.Header.Get("Content-Encoding")))
	var reader io.Reader = resp.Body
	switch encoding {
	case "gzip":
		gz, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, err
		}
		defer func() { _ = gz.Close() }()
		reader = gz
	case "br":
		reader = brotli.NewReader(resp.Body)
	}
	return io.ReadAll(reader)
}

func preview(b []byte) string {
	s := strings.TrimSpace(string(b))
	if len(s) > 160 {
		return s[:160]
	}
	return s
}

func (c *Client) jsonHeaders(headers map[string]string) map[string]string {
	out := cloneStringMap(headers)
	out["Content-Type"] = "application/json"
	return out
}

func cloneStringMap(in map[string]string) map[string]string {
	out := make(map[string]string, len(in))
	for k, v := range in {
		out[k] = v
	}
	return out
}
