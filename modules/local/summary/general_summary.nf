process GENERAL_SUMMARY {
    tag "general_summary"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path deconvolution

    output:
    path "*.png",        emit: general_summary
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
