process PRIMER_USAGE {
    tag "primer_usage"
    label "process_single"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'staphb/pandas' :
        'quay.io/staphb/pandas' }"


    input:
    val(samples)

    output:
    path("primer_usage.csv"), emit: failed
    path("versions.yml"),     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    primer_usage.py -s "${samples}"

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