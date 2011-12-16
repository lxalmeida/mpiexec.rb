require './Parameter'
require './constant/ParameterType'

def parse_exec_arguments(command_args)
  index = 0
  
  parameters = Array.new
  
  command_args.each do |arg|
    if arg.match(/^[rR|cC]\[\d+,\d+(,\d+)?\]$/)
      parameter = Parameter.new
      
      bounds = arg.gsub(/(\[|\])/, '').gsub(/[rR|cC]/, '').split(",")
      
      parameter.lower_bound = bounds[0].to_i
      parameter.upper_bound = bounds[1].to_i
      
      
      parameter.type = ParameterType::NROWS_PARAM if arg.match(/^[rR]/)
      parameter.type = ParameterType::NCOLS_PARAM if arg.match(/^[cC]/)
      
      if bounds.size == 3
        parameter.increment = bounds[2].to_i
      else
        parameter.increment = 1
      end
    elsif arg.match(/^[tT]\[(\d+,\d+(,\d+)?)?\]$/)
      parameter = Parameter.new
      parameter.type = ParameterType::NTHREAD_PARAM
      parameter.increment = 2
      
      if arg.match(/\[\d+,\d+(,\d+)?\]/)
        arg_values = arg.match(/\[\d+,\d+(,\d+)?\]/)[0].gsub!(/[\[\]]/, "").split(",")
        
        parameter.lower_bound = arg_values[0].to_i
        parameter.upper_bound = arg_values[1].to_i
        parameter.increment = arg_values[2].to_i if not arg_values[2].nil?
      else
        parameter.lower_bound = 2
        parameter.upper_bound = 8
      end
    elsif arg.match(/^[pP]\[(\d+,)*\d+\]$/)
      parameter = Parameter.new
      parameter.type = ParameterType::NPROCS_PARAM
      parameter.list = arg.gsub(/([pP]|\[|\])/, "").split(",")
    elsif arg.match(/^ngz\[(\d+,\d+(,\d+)?)?\]$/)
      parameter = Parameter.new
      parameter.type = ParameterType::NGHOSTZONES_PARAM
      parameter.increment = 2
      
	  if arg.match(/\[\d+,\d+(,\d+)?\]/)
        arg_values = arg.match(/\[\d+,\d+(,\d+)?\]/)[0].gsub!(/[\[\]]/, "").split(",")
        
        parameter.lower_bound = arg_values[0].to_i
        parameter.upper_bound = arg_values[1].to_i
        parameter.increment = arg_values[2].to_i if not arg_values[2].nil?
      else
        parameter.lower_bound = 1
        parameter.upper_bound = 1
      end
    end
    
    if parameter != nil
      parameters.push({parameter => index})
    end
    
    index += 1
  end
  
  parameters
end