---
title: Cookies
layout: default
parent: Developer Documentation
---

# Customizing EditorJS in Panda CMS

Panda CMS uses [EditorJS](https://editorjs.io/) as its rich text editor. You can customize the editor in several ways to add new tools, modify existing ones, or extend its functionality.

## Default Configuration

By default, Panda CMS includes these EditorJS tools:

- Paragraph (with inline toolbar)
- Header (with levels 2-3)
- List (with inline toolbar)
- Quote
- Table (with inline toolbar)
- Simple Image
- Embed (supports YouTube, Instagram, Miro, Vimeo, Pinterest, GitHub)
- Alert (with types: primary, secondary, success, danger, warning, info)

## Adding Custom Tools

There are three ways to customize EditorJS in your application:

### 1. Using Ruby Configuration

Create an initializer in your application to configure EditorJS tools:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  # Add additional EditorJS tools
  config.editor_js_tools = [
    { url: "https://cdn.jsdelivr.net/npm/@editorjs/code@2.8.0" }
  ]

  # Configure the tools
  config.editor_js_tool_config = {
    code: {
      class: 'CodeTool',
      config: {
        placeholder: 'Enter code here...'
      }
    }
  }
end
```

### 2. Using JavaScript Global Variables

You can add custom tools and resources using global variables:

```javascript
// app/javascript/panda_cms_customizations.js

// Add custom tool scripts
window.PANDA_CMS_EDITOR_JS_RESOURCES = [
  "https://cdn.jsdelivr.net/npm/@editorjs/code@2.8.0"
];

// Add custom tool constructors
window.PANDA_CMS_EDITOR_JS_TOOLS = {
  code: CodeTool
};

// Add custom tool configurations
window.PANDA_CMS_EDITOR_JS_CONFIG = {
  code: {
    class: 'CodeTool',
    config: {
      placeholder: 'Enter code here...'
    }
  }
};
```

### 3. Using JavaScript Hooks

You can also customize the editor using JavaScript hooks:

```javascript
// app/javascript/panda_cms_customizations.js

// Customize editor configuration before initialization
window.customizeEditorJS = function(config) {
  // Modify existing tools
  config.tools.header.config.levels = [1, 2, 3, 4];

  // Add custom tools
  config.tools.myCustomTool = {
    class: MyCustomTool,
    config: {
      // tool-specific configuration
    }
  };

  // Add global editor settings
  config.placeholder = 'Start writing your content...';
  config.autofocus = true;
};

// Add functionality after editor initialization
window.onEditorJSReady = function(editor) {
  // Add custom event listeners
  editor.on('change', () => {
    console.log('Content changed');
  });

  // Add custom methods
  editor.customMethod = function() {
    // Custom functionality
  };
};
```

Make sure to include your customization file in your application's JavaScript bundle.

## Configuration Order

The editor configuration is built in this order:

1. Default tools and configurations
2. Additional resources from `PANDA_CMS_EDITOR_JS_RESOURCES`
3. Custom tools from `PANDA_CMS_EDITOR_JS_TOOLS`
4. Tool configurations from `PANDA_CMS_EDITOR_JS_CONFIG`
5. JavaScript modifications via `customizeEditorJS`
6. Post-initialization hooks via `onEditorJSReady`

Later configurations can override earlier ones.

## Common Examples

### Adding an Image Upload Tool

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.editor_js_tools = [
    { url: "https://cdn.jsdelivr.net/npm/@editorjs/image@2.8.1" }
  ]

  config.editor_js_tool_config = {
    image: {
      class: 'ImageTool',
      config: {
        endpoints: {
          byFile: '/upload/image',
          byUrl: '/fetch/image'
        },
        types: '.jpg, .png, .gif, .webp'
      }
    }
  }
end
```

### Adding a Code Block Tool with Syntax Highlighting

```javascript
// app/javascript/panda_cms_customizations.js

// Add Prism.js for syntax highlighting
window.PANDA_CMS_EDITOR_JS_RESOURCES = [
  "https://cdn.jsdelivr.net/npm/@editorjs/code@2.8.0",
  "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.min.js",
  "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.css"
];

window.PANDA_CMS_EDITOR_JS_TOOLS = {
  code: CodeTool
};

window.customizeEditorJS = function(config) {
  config.tools.code = {
    class: CodeTool,
    config: {
      placeholder: 'Enter code here...',
      prism: {
        theme: 'default',
        languages: ['javascript', 'ruby', 'python']
      }
    }
  };
};

window.onEditorJSReady = function(editor) {
  // Initialize Prism.js after each code block is added
  editor.on('block-rendered', (block) => {
    if (block.name === 'code') {
      Prism.highlightAll();
    }
  });
};
```

### Custom Save Handling

```javascript
window.onEditorJSReady = function(editor) {
  editor.on('save', async () => {
    const data = await editor.save();

    // Send to custom endpoint
    try {
      const response = await fetch('/api/content', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) throw new Error('Save failed');

      console.log('Content saved successfully');
    } catch (error) {
      console.error('Failed to save:', error);
    }
  });
};
```

## Available Tools

EditorJS has many official and community tools available. Here are some popular ones:

- [Image Tool](https://github.com/editor-js/image)
- [Embed Tool](https://github.com/editor-js/embed)
- [Table Tool](https://github.com/editor-js/table)
- [Code Tool](https://github.com/editor-js/code)
- [Link Tool](https://github.com/editor-js/link)
- [Raw HTML Tool](https://github.com/editor-js/raw)
- [Checklist Tool](https://github.com/editor-js/checklist)

For a complete list, visit the [EditorJS Tools Directory](https://github.com/editor-js/awesome-editorjs).

## Best Practices

1. Always specify exact versions for EditorJS tools to ensure consistency
2. Test your custom tools thoroughly in development before deploying
3. Consider implementing error handling for tool initialization
4. Use the `onReady` hook to ensure your customizations are applied after the editor is fully initialized
5. Keep tool configurations modular and maintainable
6. Document any custom tools or configurations specific to your application
