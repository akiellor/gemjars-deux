require 'clamp'
require 'gemjars/deux/file_store'
require 'gemjars/deux/aws_store'
require 'gemjars/deux/commands/dsl'

AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)

module Gemjars
  module Deux
    module Commands
      class Yank < ::Clamp::Command
        include Commands::Dsl

        option ["--out"], "OUTPUT_DIRECTORY", "output directory", :attribute_name => :output_directory

        option ["--s3"], "S3_CONFIG_FILE", "s3 config file", :attribute_name => :s3_config_file

        parameter "GEMS ...", "gemjars to remove from mirror", :required => true, :attribute_name => :gems

        def store
          if output_directory
            @store ||= FileStore.new(output_directory)
          elsif s3_config_file
            @store ||= AWSStore.from_file(s3_config_file)
          else
            raise "Either --out or --s3 must be specified."
          end
        end

        def repo
          @repo ||= MavenRepository.new(store)
        end

        def index
          @index ||= Deux::Index.new(store)
        end

        def predicate
          YankPredicate.new(gems)
        end

        def execute
          to_delete = index.select &predicate

          puts "Yanking #{to_delete.size} gemjars..."

          repo.delete_all to_delete
          index.delete_all to_delete
        end
      end
    end
  end
end
