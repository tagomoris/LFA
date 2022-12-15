require 'LFA'
run LFA.ignition!('config.yaml')

# current = Dir.pwd
# mod1 = Module.new
# env = {
#   "KEY1" => "yaaaaay",
#   "KEY2" => "foooooo",
# }
# mod1.const_set(:ENV, env)
# load(File.join(current, 'func.rb'), mod1)
# p mod1.const_get(:Countries).process

# mod2 = Module.new
# env = {
#   "KEY2" => "f",
#   "OUTPUT_DATA_TYPE" => "csv",
# }
# mod2.const_set(:ENV, env)

# load(File.join(current, 'data.rb'), mod2)
# p mod2.const_get(:Data).process

# p mod1.const_get(:Countries).process

# p Data # definition leak by require in the loaded file.
