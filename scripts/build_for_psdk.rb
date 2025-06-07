# Script to build the FLUtil for PSDK
#
# To use this script, you must clone this repository into the scripts folder of a PSDK project.  
# Then, from this directory run: ruby build_for_psdk.rb

REPOSITORY_DIRECTORY = File.join(File.dirname(__FILE__), '..')

def compile_psdk_plugin
  Dir.chdir(REPOSITORY_DIRECTORY) do
    setup_output_directory
    write_plugin_config
    copy_scripts
    run_plugin_compilation
  end
end

def setup_output_directory
  Dir.mkdir('dist') unless Dir.exist?('dist')
  Dir.mkdir('dist/scripts') unless Dir.exist?('dist/scripts')
end

def write_plugin_config
  File.write('dist/config.yml', <<~EOCONFIG)
    --- !ruby/object:PluginManager::Config
    name: FLUtil
    authors:
    - FL
    version: 1.0.0.0
    deps: []
    added_files: []
  EOCONFIG
end

def copy_scripts
  compatible_scripts = ['002_RandomHelper.rb', '003_Variables Switches Alias.rb', '005_Tweener.rb']
  # Reason for not including 006_EsBridge: No need to bridge with Essentials, adding a compatibility module
  # Reason for not including 004_MyAlias: Might not be relevant, people can write this script themselves
  # Reason for not including 007_Misc Util: None of the method are used and most is for bridging old version of Ruby with newer methods
  # Reason for not including 008_Test: It's a test file
  # Reason for not including 001_Main Notes: It's not containing code
  
  compatible_scripts.each { |s| File.copy_stream("Content/Plugins/FLUtil/#{s}", "dist/scripts/#{s}") }

  File.write('dist/scripts/006_EsBridge.rb', <<~EOESBridge)
    module EsBridge
      MAJOR_VERSION = -1
      IS_ESSENTIALS = false
      IS_MKXP = false

      module_function

      # Test if a data entity exists
      # @param game_data_method [Symbol] name of the data function, eg. :data_creature
      # @param db_symbol [Symbol] db_symbol of the entity
      # @return [Boolean]
      def game_data_exists?(game_data_method, db_symbol)
        return send(game_data_method, db_symbol) != send(game_data_method, :__undef__)
      end

      # Get the sell item price
      # @param item_db_symbol [Symbol] db_symbol of the item
      # @return [Integer]
      def item_sell_price(item_db_symbol)
        # Note: there's currently no way to define the sell weight
        data_item(item_id).price / 2
      end

      # Get the buy item price
      # @param item_db_symbol [Symbol] db_symbol of the item
      # @return [Integer]
      def item_buy_price(item_db_symbol)
        # Note: it is not taking into account custom shops that define their own prices
        data_item(item_id).price
      end
    end
  EOESBridge

  File.write('dist/scripts/009_RandomHelperFixes.rb', <<~EORHFIxes)
    class PokemonRandomHelper
      def initialize
        @game_data = :data_creature
        super
      end
    end
    class ItemRandomHelper 
      def initialize
        @game_data = :data_item
        super
      end
    end
  EORHFIxes
end

def run_plugin_compilation
  scripts = %w[./game-linux.sh ./game-mac.sh psdk.bat]
  Dir.chdir('../..') do
    script = scripts.find { |s| File.exist?(s) }
    raise 'Failed to locate PSDK start script' unless script

    puts "Using '#{script}' to build plugin"
    system("#{script} --util=plugin build RMXP-FLUtil/dist")
  end
end

compile_psdk_plugin
