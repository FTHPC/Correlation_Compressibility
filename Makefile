script=compression_mpi

run:
	sh scripts/run.sh -c config.json -d $(d) -p

local:
	sh scripts/run.sh -c config.json -d $(d)
	
test: 
	sh scripts/run.sh -c config.json -d TEST -p

images:
	tar -cvzf ./"images_$(shell date +'%Y-%h-%d-%H%M').tgz" image_results 

output:
	tar -cvzf ./"outputs_$(shell date +'%Y-%h-%d-%H%M').tgz" $(shell find -name "*.csv" | sed 's|^./||') 

rmcsv: 
	-rm *.csv
	-rm -rf *_outputs
	
clean:
	-rm -rf $(shell pwd)/compress_package/__pycache__
	-rm -rf $(shell pwd)/compress_package/convert/__pycache__
	-rm -rf $(shell pwd)/datasets/temp
	-rm $(shell pwd)/$(addprefix , $(shell find -name "$(script).o*"))
	-rm $(shell pwd)/$(addprefix , $(shell find -name "$(script).e*"))