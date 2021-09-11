script = compression_mpi

run:
	qsub $(script).pbs

images:
	tar -cvzf ./"images_$(shell date +'%Y-%h-%d-%H%M').tgz" image_results 

output:
	tar -cvzf ./"outputs_$(shell date +'%Y-%h-%d-%H%M').tgz" $(shell find -name "*.csv" | sed 's|^./||') 

clean:
	rm -rf $(shell pwd)/compress_package/__pycache__
	rm -rf $(shell pwd)/compress_package/convert/__pycache__
	rm -rf $(shell pwd)/datasets/temp
	rm $(shell pwd)/$(addprefix , $(shell find -name "$(script).o*"))
	rm $(shell pwd)/$(addprefix , $(shell find -name "$(script).e*"))