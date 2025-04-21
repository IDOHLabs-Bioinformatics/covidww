process SUMMARY {
    tag "summary"
    label "process_low"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-28790ac237c42b0eb0766a9c8c8f2232e355052a:6c44bb031cb466096171291cf8427fb7411a71c9-0' :
        'biocontainers/mulled-v2-28790ac237c42b0eb0766a9c8c8f2232e355052a:6c44bb031cb466096171291cf8427fb7411a71c9-0' }"

    input:
    path deconvolution

    output:
    path "*.pdf",        emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    Rscript ${projectDir}/bin/summary.R \\
        ${deconvolution}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(echo \$(Rscript --version 2>&1) | cut -d ' ' -f 4)
    END_VERSIONS
    """

    stub:
    """
    touch empty.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(echo \$(Rscript --version 2>&1) | cut -d ' ' -f 4)
    END_VERSIONS
    """
}
