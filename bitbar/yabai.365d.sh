#!/usr/bin/env zsh
# <xbar.title>Yabai status</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Albert Groothedde</xbar.author>
# <xbar.author.github>alber70g</xbar.author.github>
# <xbar.desc>
# Shows the status of Yabai. Current space, and whether window is floating, sticky, on top and fullscreen.echo "setting up signals"
# ```
# yabai -m signal --add event=space_changed \
#   action="set SHELL=/bin/sh && open -g \"bitbar://refreshPlugin?name=yabai.*?.sh\""
# yabai -m signal --add event=window_resized \
#   action="set SHELL=/bin/sh && open -g \"bitbar://refreshPlugin?name=yabai.*?.sh\""
# yabai -m signal --add event=window_focused \
#   action="set SHELL=/bin/sh && open -g \"bitbar://refreshPlugin?name=yabai-window-info.*?.sh\""
# yabai -m signal --add event=application_activated \
#   action="set SHELL=/bin/sh && open -g \"bitbar://refreshPlugin?name=yabai-window-info.*?.sh\""
# echo "signals ready"
# ```
# </xbar.desc>
# <xbar.dependencies>yabai,jq</xbar.dependencies>
PATH=$PATH:/opt/homebrew/bin
if [[ "$1" = "stop" ]]; then
  brew services stop yabai
  brew services stop skhd
fi

if [[ "$1" = "restart" ]]; then
  brew services restart yabai
  brew services restart skhd
fi

echo "$(yabai -m query --spaces --display | jq 'map(select(."has-focus"))[-1].index'):$(yabai -m query --spaces --display | jq -r 'map(select(."has-focus"))[-1].type') | length=5"
echo "---"
echo "Restart yabai & skhd | bash='$0' param1=restart terminal=false"
echo "Stop yabai & skhd | bash='$0' param1=stop terminal=false"