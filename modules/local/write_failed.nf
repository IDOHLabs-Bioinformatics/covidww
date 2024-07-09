process WRITE_FAILED {
    tag "${meta.id}"
    label "process_single"

    input:
    tuple val(meta), path(bam)

    output:
    path("primer_failed.csv"), emit: failed

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo ${prefix} >> primer_failed.csv
    """

    stub:
    """
    touch failed.csv
    """
}