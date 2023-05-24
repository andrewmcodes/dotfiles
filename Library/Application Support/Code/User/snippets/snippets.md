# Snippets

## Example

`$SCOPES $PREFIXES $NAME $DESCRIPTION`

Snippet parts can be omitted by using underscore sign `_`

`_$PREFIXES_ $DESCRIPTION`

Autocomplete for variables inside the code block is not shown when you type `$`, but it's there

```javascript,typescript prefix1,prefix2 name description
console.log($0);
```

## Ruby

```ruby pry,binding pry Add binding.pry to the code
binding.pry
```

## ERB

```erb pry binding.pry Add pry to ERB
<% binding.pry %>
```

```erb vc view_component Add Component
<%= render $1Component.new %>$0
```

```erb vcd view_component_block Add Multiline Component
<%= render $1Component.new($2) do %>
  $0
<% end %>
```

```erb vcwc view_component_with_content Add Component with content
<%= render $1.new${2:()}${3:.with_content($4)} %>
```

```erb tft turbo_frame_tag Add Turbo Frame Tag
<%= turbo_frame_tag :$1 do %>
  $0
<% end %>
```

## JavaScript

```javascript log console.log Add console.log to the code
console.log($0);
```

```javascript stimc stimulus-controller Add Stimulus Controller Boilerplate
import { Controller } from "stimulus";

export default class extends Controller {
  static values = {};

  static classes = [];
  static targets = [];

  connect() {}
}
```

## shellscript

```sh,shellscript #!bash #!bash Bash Shebang Comment
#!/usr/bin/env bash
```

```sh,shellscript #!node #!node Node Shebang Comment
#!/usr/bin/env node
```

```sh,shellscript #!php #!php PHP Shebang Comment
#!/usr/bin/env php
```

```sh,shellscript #!python #!python Python Shebang Comment
#!/usr/bin/env python
```

```sh,shellscript #!ruby #!ruby Ruby Shebang Comment
#!/usr/bin/env ruby
```

```sh,shellscript #!zsh #!zsh ZSH Shebang Comment
#!/usr/bin/env zsh
```

```sh,shellscript #!sh #!sh Shell Shebang Comment
#!/usr/bin/env sh
```
