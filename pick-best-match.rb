#!/usr/bin/env ruby

# ----------------------------------------------------------------------

# pick-best-match.rb
#
# Gets the best word match from the arguments
#
# Usage: pick-best-match [--] matchee matchable ...
#                        -h|--help|-V|--version
#
# Copyright (c) 2023 konsolebox
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files
# (the “Software”), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# ----------------------------------------------------------------------

require 'amatch'

VERSION = "2023.10.01"

def usage(**opts)
  io = opts[:io] || $stdout
  io.puts "Usage: pick-best-match [--] matchee matchable ..."
  io.puts "                       -h|--help|-V|--version"
  exit 2
end

def die(message, **opts)
  $stderr.puts message
  usage(io: $stderr) if opts[:show_usage]
  exit opts[:exit_code] || 1
end

matchee = nil
matchables = []
null_delim = false

until ARGV.empty?
  arg = ARGV.shift

  case arg
  when "-0"
    null_delim = true
  when "-h", "--help"
    usage
  when "-V", "--version"
    puts VERSION
    exit 2
  when "--"
    matchee = ARGV.shift if matchee.nil? && !ARGV.empty?
    matchables.unshift *ARGV unless ARGV.empty?
  when /^-[^-][^-]/
    ARGV.unshift arg[..1], "-#{arg[2..]}"
  when /^-./
    die("Invalid option: #{arg}", show_usage: true, exit_code: 2)
  else
    if matchee.nil?
      matchee = arg
    else
      matchables.unshift arg
    end
  end
end

die("No matchee specified.", show_usage: true, exit_code: 2) if matchee.nil?
die("No matchables specified.", show_usage: true, exit_code: 2) if matchables.empty?
matcher = Amatch::DamerauLevenshtein.new(matchee)
best_match = matchables.map{ |m| [matcher.match(m), m] }.sort_by{ |d, m| d }.first[1]
printf(null_delim ? "%s\0" : "%s\n", best_match)
