#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'ruby-progressbar'
# require 'byebug'

class MusicSyncParser

  def self.parse(args)

    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = <<HEREDOC
Usage: sync.rb [source] [destination] [options]
Copies over a folder of music while flattening out the directory structure
Intended for use formatting flash drives for automotive USB systems (which
commonly have limits on the number of folders, which are far more restrictive
than their limits on file count or file size
HEREDOC

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on_tail('-h', '--help', 'Display this screen.') do
        puts opts
        exit
      end

      # opts.on('-d', '--depth [DEPTH]', String, 'Depth to flatten from. Default is 1 (preserve top-level folders, typically artist names, but not sublevel, typically albums)') do |v|
      #   options[:depth] = v
      # end

      opts.on('-m', '--merge', 'Merge on the copy - leave all existing files in place, but overwrite any of the same name. Defaults to true.') do |v|
        options[:merge] = true
      end

      opts.on('-c', '--clear', 'Clear out destination folder before copying. Defaults to false. Compatible with --merge, insofar as --merge is pointless and does nothing if --clear is passed.') do |v|
        options[:clear] = true
      end

    end
    parser.parse!(args)

    options
  end
end

class MusicSyncer
  attr_accessor :source, :dest, :depth, :options

  def initialize(source, dest, options = {})
    @source = source
    @dest = dest
    @depth = options[:depth] || 1
    @options = options
  end

  def copy
    source_dir = Dir.open(@source)
    dest_dir = Dir.open(@dest)

    if options[:clear]
      FileUtils.rm_r(dest_dir, secure: true)
    end

    FileUtils.cd(source_dir)
    dest_dir = File.join(dest_dir, 'music')
    Dir.glob("*") do  |dirname|
      FileUtils.mkdir_p(File.join(dest_dir, dirname))
    end
    FileUtils.mkdir_p(File.join(dest_dir, 'Various'))

    file_count = Dir.glob('**/**.mp3').size
    progress_inc = file_count / 100
    puts "Copying #{file_count} files"
    n = 0
    progress_bar = ProgressBar.create(
      title: 'Tracks',
      starting_at: 0,
      total: file_count,
      format: '%e | %c/%C %t: %b'
    )
    Dir.glob('**/**.mp3').each do |filename|
      progress_bar.increment

      parts = filename.split('/')
      if parts.size <= 3
        dir = parts.first
        name = parts.last
      end
      path = File.join(@source, filename)
      dest_dir = File.join(@dest, dir)
      dest_path = File.join(dest_dir, name)

      unless File.exists?(dest_path) && FileUtils.identical?(path, dest_path)
        FileUtils.mkdir(dest_dir) unless File.exists?(dest_dir)
        FileUtils.copy(path, dest_path)
      end
    end

  end


end

source, dest = ARGV[0], ARGV[1]
options = MusicSyncParser.parse(ARGV)
raise ArgumentError.new("Incorrect arguments passed: #{ARGV}") if source.nil? || dest.nil?
syncer = MusicSyncer.new(source, dest, options)
syncer.copy

