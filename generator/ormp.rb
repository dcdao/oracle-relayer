require 'thor'
require 'dry/inflector'

class Ormp < Thor
  include Thor::Actions

  def initialize(*args)
    super
    @inflector = Dry::Inflector.new
  end

  # Implement the exit_on_failure? method to return true
  def self.exit_on_failure?
    true
  end

  def self.source_root
    File.dirname(__FILE__)
  end

  desc 'new CONTRACT_NAME',
       'Create oracle and relayer contracts, `new hello` will generate `HelloOracle.sol` and `HelloRelayer.sol`'
  def new(name)
    # oracle and relayer name
    @name = name
    if @name.empty? || !@name.match(/^[a-zA-Z0-9]{3,28}$/)
      say 'You must provide an valid name(/^[a-zA-Z0-9]{3,28}$/)!'
      return
    end
    @name = camelize(name)

    # check if the generated files with the same name exist
    if File.exist? File.expand_path("../src/#{@name}Oracle.sol", __dir__)
      ask = ask 'The contracts with the same name already exist, do you want to overwrite them?(y/n): '

      return unless ask == 'y'
    end

    # check if the generated files without the same name exist
    files_with_different_name_exist =
      Dir.glob(File.expand_path('../src/*Oracle.sol', __dir__)).any? do |filename|
        filename = File.basename(filename)
        filename.gsub('Oracle.sol', '') != @name
      end
    if files_with_different_name_exist
      say 'The contracts with the different name already exist! You should run `ormp clear` to clear all generated files first!'
      return
    end

    # ormp endpoint address
    # TODO: validate ormp address
    @ormp_address = ask 'What is the ormp endpoint address?: ', default: '0x0000000000BD9dcFDa5C60697039E2b3B28b079b'
    unless @ormp_address.match(/^0x[a-fA-F0-9]{40}$/)
      say 'You must provide an valid ormp endpoint address!'
      return
    end

    # generate oracle and relayer contracts
    output = File.expand_path('../src', __dir__)
    template('./templates/Constants.sol.erb', File.join(output, 'Constants.sol'))
    template('./templates/Oracle.sol.erb', File.join(output, "#{@name}Oracle.sol"))
    template('./templates/Relayer.sol.erb', File.join(output, "#{@name}Relayer.sol"))

    # replace oracle and relayer name in scripts
    script = File.expand_path('../script', __dir__)
    gsub_file(File.join(script, 'Deploy.s.sol'), /DcdaoOracle/, "#{@name}Oracle")
    gsub_file(File.join(script, 'Deploy.s.sol'), /DcdaoRelayer/, "#{@name}Relayer")
  end

  desc 'clear', 'Clear all generated files and reset to the initial state'
  def clear
    # get the name from generated oracle file
    filename = Dir.glob(File.expand_path('../src/*Oracle.sol', __dir__)).first
    filename = File.basename(filename)
    name = filename.gsub('Oracle.sol', '')

    say('Clearing all generated files...')
    output = File.expand_path('../src', __dir__)
    # remove all files in src, but keep .keep
    Dir.glob(File.join(output, '*')).each do |filename|
      next if File.basename(filename) == '.keep'

      remove_file(filename, force: true)
    end

    say 'Resetting scripts to the initial state...'
    script = File.expand_path('../script', __dir__)
    gsub_file(File.join(script, 'Deploy.s.sol'), /#{name}Oracle/, 'DcdaoOracle')
    gsub_file(File.join(script, 'Deploy.s.sol'), /#{name}Relayer/, 'DcdaoRelayer')
  end

  desc 'deploy', 'Deploy oracle and relayer contracts'
  def deploy
    # check if the generated files exist
    unless File.exist? File.expand_path('../src/Constants.sol', __dir__)
      say 'You should run `ormp new` to prepare the contracts first!'
      return
    end

    # check if there is a .env file, then source it
    say 'checking .env file...'
    if File.exist? File.expand_path('../.env', __dir__)
      say 'load .env file...'
      require 'dotenv/load'

      # check if the .env file has the PRIVATE_KEY and RELAY_ADDRESS
      unless ENV['PRIVATE_KEY'] && ENV['RELAY_ADDRESS']
        say 'You must provide the PRIVATE_KEY and RELAY_ADDRESS in .env file!'

        return
      end

      # call deploy script
      bin = File.expand_path('../bin', __dir__)
      system("#{bin}/deploy.sh #{ENV['RELAY_ADDRESS']}")
    else
      say 'no .env file found'

      # prepare private key and relay address
      private_key = nil
      loop do
        private_key = ask('Enter your private key(send deploy transactions): ', echo: false)
        break unless private_key.empty? || !private_key.match(/^[a-fA-F0-9]{64}$/)

        say "\nYou must provide an valid private key!"
      end
      ENV['PRIVATE_KEY'] = private_key

      relay_address = nil
      loop do
        relay_address = ask "\nEnter your relay address: "
        break unless relay_address.empty? || !relay_address.match(/^0x[a-fA-F0-9]{40}$/)

        say "\nYou must provide an valid relay address!"
      end

      # call deploy script
      bin = File.expand_path('../bin', __dir__)
      system("#{bin}/deploy.sh #{relay_address}")
    end
  end

  private

  def camelize(name)
    @inflector.camelize(name)
  end

  def underscore(name)
    @inflector.underscore(name)
  end
end

Ormp.start(ARGV)
