process FREYJA_CLEAN {
    tag "parse_all"
    label "process_low"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'staphb/pandas' :
        'quay.io/staphb/pandas' }"


    input:
    path("*")

    output:
    path "*.csv",         emit: csv
    path "versions.yml",  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir demix
    mv *.txt demix

    freyja_cleaning.py --input demix $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Python: \$(echo \$(python --version 2>&1) | cut -d ' ' -f 2)
    END_VERSIONS
    """

    stub:
    """
    touch empty.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Python: \$(echo \$(python --version 2>&1) | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
