process SUMMARY {
    tag "summary"
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container null

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
