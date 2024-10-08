process SUBSAMPLE {
    tag "${meta.id}"
    label "process_low"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_2' :
        'biocontainers/seqtk:1.4--he4a0461_2' }"

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
    RANDOM=\$(date +%s%N | cut -b10-19)
    seed=\$(echo \$RANDOM)

    seqtk sample -s \$seed ${reads[0]} ${count} | pigz > ${prefix}_subsampled_R1.fastq.gz
    seqtk sample -s \$seed ${reads[1]} ${count} | pigz > ${prefix}_subsampled_R2.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(seqtk) |& head -n 3 | tail -n 1 | cut -d ' ' -f 2)
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
        ivar: \$(echo \$(seqtk) |& head -n 3 | tail -n 1 | cut -d ' ' -f 2)
    END_VERSIONS
    """

}
