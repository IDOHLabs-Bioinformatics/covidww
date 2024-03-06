process BWA_INDEX {
	tag "$meta.id"
	label 'process_low'

	# the containers and everything

	input:
	tuple vla(meta), path(reference)

	output:
	tuple val(meta), 


}
