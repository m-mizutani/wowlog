# Wowlog

Wowlog is Parser Library for World of Warcraft Combat Log to analyze your combat.

## Installation

Add this line to your application's Gemfile:

    gem 'wowlog'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wowlog

## Usage

    require 'wowlog'
    psr = Wowlog::Parser.new
    File.open('/path/to/WowCombatLog.txt', 'r') do |fd|
      fd.each do |line|
        ev = psr.parse_line(line)
        puts ev
        # => {"event"=>"SPELL_HEAL", "sourceGUID"=>"0x0300000007F97AFF", "sourceName"=>"Muret", ...}
      end
    end



## Contributing

1. Fork it ( https://github.com/[my-github-username]/wowlog/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
