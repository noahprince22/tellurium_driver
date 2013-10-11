require "bundler"
Bundler.require(:default)

require 'cucumber/rake/task'
require 'parallel'
require 'psych'
#takes all browsers from inside of browser_full, stores them in redis for easy-access, then runs them in parallel across multiple VMs
#by running cucumber inside each app's feature file. Note - each feature is run several times for to hit each browser. The 
#feature files must distinguish, through redis, which browser they will be run with. 

browser_file = "#{ENV['APP']}/browser_full.yml"

@browsers = Psych.load_file(browser_file)[:browsers]

@redis = Redis.new(:port => 6379)

#ip =`cd /home/nprince/chef_messaround/chef-repo/ && vagrant ssh default --command "ifconfig eth1 | grep inet | grep -v inet6                                                                                     
#1515" | awk '{print $2}' | tr -d "addr:" | tr -d "\n"`

#ENV['URL'] = "http://#{ip}:3000"
#puts "#{ENV['URL']}" 

desc "Run all features against all browsers in parallel"
task :cucumber do

  Parallel.map(@browsers, :in_threads => @browsers.size) do |browser|
    begin
      @redis.rpush "browser", [browser[:name],browser[:version]].to_json

      puts "Running with: #{browser.inspect}"

      exit_code = Rake::Task[ :run_browser_tests].execute({ :browser_name => browser[:name],
                                                 :browser_version => browser[:version]})
      `exit 1` if exit_code == 1
    rescue RuntimeError
      puts "Error while running task"
    end

  end

end

Cucumber::Rake::Task.new(:'run_browser_tests') do |t|
  ENV['TAGS'] = "--tags #{ENV['TAGS']}" if ENV['TAGS']
  t.cucumber_opts = "#{ENV['APP']}/features/*.feature #{ENV['TAGS']}"
end

task :default => [:cucumber]
