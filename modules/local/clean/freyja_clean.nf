process FREYJA_CLEAN {
    tag "parse_all"
    label "process_low"

    if (workflow.profile == 'conda') {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e:d3fff24ee1297b4c3bcef48354c2a30f0c82007a-0' :
        'biocontainers/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e' }"

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

    python ${projectDir}/bin/freyja_cleaning.py --input demix $args

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
