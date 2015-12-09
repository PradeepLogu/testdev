require 'erb'

class FuzzyMatch
  class Result #:nodoc: all
    EXPLANATION = <<-ERB
You looked for <%= needle.render.inspect %>

<% if winner %>It was matched with "<%= winner %>"<% else %>No match was found<% end %>

# THE HAYSTACK

The haystack reader was <%= read.inspect %>.

The haystack contained <%= haystack.length %> records like <%= haystack[0, 3].map(&:render).map(&:inspect).join(', ') %>

# HOW IT WAS MATCHED
<% timeline.each_with_index do |event, index| %>
(<%= index+1 %>) <%= event %>
<% end %>
ERB

    attr_accessor :needle
    attr_accessor :read
    attr_accessor :haystack
    attr_accessor :options
    attr_accessor :normalizers
    attr_accessor :groupings
    attr_accessor :identities
    attr_accessor :stop_words
    attr_accessor :winner
    attr_accessor :score
    attr_reader :timeline

    def initialize
      @timeline = []
    end
    
    def explain
      $stdout.puts ::ERB.new(EXPLANATION, 0, '%<').result(binding)
    end
  end
end
