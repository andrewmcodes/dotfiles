# Editor
Pry.editor = "code-insiders --wait"

# Config
Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :gray

# Aliases
Pry.commands.alias_command "wai", "whereami"
Pry.commands.alias_command "e", "edit"

# Default Commands
default_command_set = Pry::CommandSet.new do
  command "copy", "Copy argument to the clipboard" do |str|
    IO.popen("pbcopy", "w") { |f| f << str.to_s }
  end

  command "clear" do
    system "clear"
    output.puts("Rails Environment: " + ENV["RAILS_ENV"]) if ENV["RAILS_ENV"]
  end

  command "caller_method" do |depth|
    depth = depth.to_i || 1
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller(depth + 1).first
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      output.puts [file, line, method]
    end
  end
end

Pry.config.commands.import default_command_set
