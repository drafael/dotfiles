# Make your own custom AI code assistant

## Prerequisites

* [Ollama](https://ollama.com) and/or [LM Studio](https://lmstudio.ai) installed
* [Continue](https://www.continue.dev) plugin installed

**Note: You should have at least 8 GB of RAM available to run the 7B models,
16 GB to run the 13B models, and 32 GB to run the 33B models.**

## Pull models for chat

```sh
ollama pull llama3.1:8b
```

```sh
ollama pull qwen2.5:7b
```

```sh
ollama pull qwen2.5:14b
```

```sh
ollama pull qwen2.5-coder:7b
```

```sh
ollama pull qwen2.5-coder:14b
```

```sh
ollama pull deepseek-r1:14b
```

## Pull models for code completion

```sh
ollama pull qwen2.5-coder:1.5b-base
```

```sh
ollama pull qwen2.5-coder:3b-base
```

```sh
ollama pull qwen2.5-coder:7b-base
```

```sh
ollama pull qwen2.5-coder:14b-base
```

## Pull embeddings to power @codebase

```sh
ollama pull nomic-embed-text:v1.5
```

## [Configure Continue plugin](https://docs.continue.dev/customize/overview#editing-configjson)

Click on the gear icon in the bottom right corner of Continue to open your `~/.continue/config.json`

### Configure models for chat

```json
"models": [
    {
      "title": "Llama 3.1 8B",
      "provider": "ollama",
      "model": "llama3.1:8b"
    },
    {
      "title": "Qwen2.5 7b",
      "provider": "ollama",
      "model": "qwen2.5:7b"
    },
    {
      "title": "Qwen2.5 14b",
      "provider": "ollama",
      "model": "qwen2.5:14b"
    },
    {
      "title": "Qwen2.5 Coder 7B",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b"
    },
    {
      "title": "Qwen2.5 Coder 14B",
      "provider": "ollama",
      "model": "qwen2.5-coder:14b"
    },
    {
      "title": "DeepSeek R1 14b",
      "provider": "ollama",
      "model": "deepseek-r1:14b"
    }
],
```
or

```json
"models": [
    {
      "title": "Autodetect",
      "provider": "ollama",
      "model": "AUTODETECT"
    },
    {
      "title": "Autodetect",
      "provider": "lmstudio",
      "model": "AUTODETECT"
    }
  ],
  ```

### [Autocomplete](https://docs.continue.dev/customize/deep-dives/autocomplete#setting-up-with-ollama-default)

```json
"tabAutocompleteModel": {
  "title": "Autocomplete Model",
  "provider": "ollama",
  "model": "qwen2.5-coder:1.5b-base"
},
```

or

```json
"tabAutocompleteModel": {
  "title": "Autocomplete Model",
  "provider": "ollama",
  "model": "deepseek-coder:1.3b-base"
},
```

### [Embeddings to power @codebase](https://docs.continue.dev/customize/model-types/embeddings/)

```json
"embeddingsProvider": {
  "provider": "ollama",
  "model": "nomic-embed-text:v1.5"
},
```


### TBD

## [Examples](https://github.com/drafael/dotfiles/tree/master/.continue)
