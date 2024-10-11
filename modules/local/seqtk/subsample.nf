process SUBSAMPLE {
    tag "${meta.id}"
    label "process_low"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-b8f6f9860663fb4ab74531715c96bb5f4fe84284:c0bd71897f9383127c88ddaa39ef2a259985c28a-0' :
        'quay.io/biocontainers/mulled-v2-b8f6f9860663fb4ab74531715c96bb5f4fe84284:c0bd71897f9383127c88ddaa39ef2a259985c28a-0' }"

    input:
    tuple val(meta), path(reads)
    val count

    output:
    tuple val(meta), path("*_subsampled*"), emit: subsampled
    path "versions.yml",                    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seed=\$(echo \$RANDOM)

    seqtk sample -s \$seed ${reads[0]} ${count} | pigz > ${prefix}_subsampled_R1.fastq.gz
    seqtk sample -s \$seed ${reads[1]} ${count} | pigz > ${prefix}_subsampled_R2.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(seqtk |& head -n 3 | tail -n 1 | cut -d ' ' -f 2)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_subsampled_R1.fastq.gz
    touch ${prefix}_subsampled_R2.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(seqtk |& head -n 3 | tail -n 1 | cut -d ' ' -f 2)
    END_VERSIONS
    """

}
