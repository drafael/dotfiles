# Make your own custom AI code assistant

## Prerequisites

* [Ollama](https://ollama.com) and/or [LM Studio](https://lmstudio.ai) installed
* [Continue](https://www.continue.dev) plugin installed

**Note: You should have at least 8 GB of RAM available to run the 7B models,
16 GB to run the 13B models, and 32 GB to run the 33B models.**

## Pull models for chat

```sh
ollama pull llama3.1:8b-instruct-q4_K_M
```

```sh
ollama pull codellama:7b-instruct-q4_0
```

```sh
ollama pull codeqwen:7b-chat-v1.5-q4_0
```

```sh
ollama pull codegemma:7b-instruct-v1.1-q4_0
```

```sh
ollama pull qwen2.5-coder:7b-instruct
ollama pull qwen2.5-coder:7b-instruct-q4_K_M
```

```sh
ollama pull deepseek-coder:6.7b-instruct-q4_0
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
ollama pull deepseek-coder:1.3b-base
```

```sh
ollama pull deepseek-coder:6.7b-base-q4_0
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
    "model": "llama3.1:8b-instruct-q4_K_M"
  },
  {
    "title": "CodeLlama 7B",
    "provider": "ollama",
    "model": "codellama:7b-instruct-q4_0"
  },
  {
    "title": "CodeQwen1.5 7B",
    "provider": "ollama",
    "model": "codeqwen:7b-chat-v1.5-q4_0"
  },
  {
    "title": "CodeGemma 7B",
    "provider": "ollama",
    "model": "codegemma:7b-instruct-v1.1-q4_0"
  },
  {
    "title": "Qwen2.5 Coder 7B",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b-instruct-q4_K_M"
  },
  {
    "title": "DeepSeek Coder 6.7B",
    "provider": "ollama",
    "model": "deepseek-coder:6.7b-instruct-q4_0"
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
"tabAutocompleteOptions": {
  "debounceDelay": 100,
  "maxPromptTokens": 8192
},
```

or

```json
"tabAutocompleteModel": {
  "title": "Autocomplete Model",
  "provider": "ollama",
  "model": "deepseek-coder:1.3b-base"
},
"tabAutocompleteOptions": {
  "debounceDelay": 100,
  "maxPromptTokens": 8192
},
```

### [Embeddings to power @codebase](https://docs.continue.dev/customize/model-types/embeddings/)

```json
"embeddingsProvider": {
  "provider": "ollama",
  "model": "nomic-embed-text:v1.5"
},
```

### [Slash commands](https://docs.continue.dev/customize/slash-commands)

```json
"slashCommands": [
    {
      "name": "edit",
      "description": "Edit selected code"
    },
    {
      "name": "explain",
      "description": "Explain the selected code"
    },
    {
      "name": "comment",
      "description": "Write comments for the selected code"
    },
    {
      "name": "commit",
      "description": "Generate a git commit message"
    },
    {
      "name": "share",
      "description": "Export the current chat session to markdown"
    }
  ],
```

### TBD

## [Examples](https://github.com/drafael/dotfiles/tree/master/.continue)
