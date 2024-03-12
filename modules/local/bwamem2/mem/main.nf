process BWAMEM2_MEM {
    tag "$meta"
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:2d15960ccea84e249a150b7f5d4db3a42fc2d6c3-0' :
        'biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:2d15960ccea84e249a150b7f5d4db3a42fc2d6c3-0' }"

    input:
    tuple val(meta), path(reads)
    each path(reference)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa-mem2 \\
        mem \\
        ${args} \\
        -t ${task.cpus} \\
        \$INDEX \\
        ${reads} \\
        | samtools view -b \\
        | samtools sort -o ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
