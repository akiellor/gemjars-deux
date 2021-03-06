require 'gemjars/deux/streams'

module Gemjars
  module Deux
    class ZipEntry
      CHUNK_SIZE = 2024
      
      attr_reader :name, :channel
      
      def initialize name, channel
        @name = name
        @channel = channel
      end

      def read
        Streams.read_channel @channel
      end
    end

    class ZipReader
      CHUNK_SIZE = 2048
      
      include Enumerable

      def initialize channel
        @stream = Java::JavaUtilZip::ZipInputStream.new(Streams.to_input_stream(channel))
      end

      def each &block
        while entry = @stream.next_entry
          yield ZipEntry.new(entry.name, read(entry))
        end
      end

      private

      def read entry
        Streams.to_channel(@stream)
      end
    end

    class ZipWriter
      CHUNK_SIZE = 2048
      
      def initialize channel
        @stream = Java::JavaUtilZip::ZipOutputStream.new(Streams.to_output_stream(channel))
        @directories = []
      end

      def add_entry name, channel = nil
        Pathname.new(name).parent.descend do |path|
          unless path.to_s == "."
            add_directory path.to_s
          end
        end

        @stream.put_next_entry Java::JavaUtilZip::ZipEntry.new(name)
        if channel
          Streams.copy_channel channel, Streams.to_channel(@stream)
        end
        @stream.close_entry
      end

      def add_directory name
        unless name =~ /\/$/
          name += "/"
        end
        unless @directories.include?(name)
          @stream.put_next_entry Java::JavaUtilZip::ZipEntry.new(name)
          @stream.close_entry
        end
        @directories << name
      end

      def close
        @stream.finish
        @stream.flush
        @stream.close
      end
    end
  end
end
