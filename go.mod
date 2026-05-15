module neutronapi

go 1.24.0

require (
	github.com/andybalholm/brotli v1.2.1
	github.com/go-chi/chi/v5 v5.2.5
	github.com/google/uuid v1.6.0
	github.com/hupe1980/go-tiktoken v0.0.10
	github.com/refraction-networking/utls v1.8.2
)

require github.com/dlclark/regexp2 v1.11.5 // indirect

require (
	github.com/klauspost/compress v1.18.5 // indirect
	github.com/router-for-me/CLIProxyAPI/v6 v6.6.109
	github.com/sirupsen/logrus v1.9.4 // indirect
	github.com/tidwall/gjson v1.18.0 // indirect
	github.com/tidwall/match v1.2.0 // indirect
	github.com/tidwall/pretty v1.2.1 // indirect
	github.com/tidwall/sjson v1.2.5 // indirect
	golang.org/x/crypto v0.49.0 // indirect
	golang.org/x/net v0.47.0
	golang.org/x/sys v0.42.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace golang.org/x/net => golang.org/x/net v0.33.0

replace golang.org/x/crypto => golang.org/x/crypto v0.31.0

replace golang.org/x/sys => golang.org/x/sys v0.28.0
