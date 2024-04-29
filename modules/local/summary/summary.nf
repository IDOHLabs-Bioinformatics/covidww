process SUMMARY {
    tag "general_summary"
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container null

    input:
    path deconvolution

    output:
    path "*.pdf",        emit: general_summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    Rscript ${projectDir}/bin/general_summary.R \\
        ${deconvolution}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(echo \$(Rscript --version 2>&1) | cut -d ' ' -f 4)
    END_VERSIONS
    """

    stub:
    """
    touch empty.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(echo \$(Rscript --version 2>&1) | cut -d ' ' -f 4)
    END_VERSIONS
    """
}
