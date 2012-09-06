
desc "create indexes with parameters, which is dependent on mongoid.
Params:

MODEL || M: model name. Actually, model class name.
FIELDS || F: fields of index.
OPTIONS || O: index 's options. Default is {unique: false, background: true}.

more info about OPTIONS in http://www.mongodb.org/display/DOCS/Indexes#Indexes-CreationOptions

Example: 

> rake build_index MODEL=User, FIELDS={name: 1}
it will create index which increase with name for user collection. 
1 means increase, -1 means decrease.

> rake build_index MODEL=User, FIELDS=\\{name: 1, age: -1\\}, O=\\{unique: true, background: true\\}
because of console command, multi-fields index should add \'\\', so is OPTIONS.

"
task :build_index => :environment do
	model 	= ENV["MODEL"] 	|| ENV["M"]
	fields 	= ENV["FIELDS"] 	|| ENV["F"]
	options	= ENV["OPTIONS"]	|| ENV["O"] || "{unique: false, background: true}"

	unless model
		puts "Must provide model name."
		exit		
	end

	unless fields
		puts "Must provide fields of index."
		exit		
	end

	_model = Kernel.const_get(model) if Kernel.const_get(model)
	unless _model
		puts "Cannot find model:#{model}"
		exit
	end

	_fields 	= eval(fields) 
	_options = eval(options)

	_model.index_options = {}
	# _spec store fields which are format to array.
	_spec = []
	_fields.each do |k,v|
		_field = [] << k.to_s << v.to_i
		_spec << _field
	end
	# verify _options
	_options[:background] = true unless _options[:background]

	puts "_spec: #{_spec}, _options: #{_options}"	

	_model.index_options = {_spec => _options}
	_model.create_indexes
	
end

