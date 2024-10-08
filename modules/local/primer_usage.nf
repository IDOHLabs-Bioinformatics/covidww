process PRIMER_USAGE {
    tag "primer_usage"
    label "process_single"

    input:
    val(samples)

    output:
    path("primer_usage.csv"), emit: failed
    path("versions.yml"),     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    python ${projectDir}/bin/primer_usage.py -s "${samples}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Python: \$(echo \$(python --version 2>&1) | cut -d ' ' -f 2)
    END_VERSIONS
    """

    stub:
    """
    touch primer_usage.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Python: \$(echo \$(python --version 2>&1) | cut -d ' ' -f 2)
    END_VERSIONS
    """
}