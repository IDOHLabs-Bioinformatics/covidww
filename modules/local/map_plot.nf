process MAP_PLOT {
    tag "plot_all"
    label "process_low"

    input:
    path(deconvolution)
    path(metadata)

    output:
    path("*.png"),        emit: plot
    path("versions.yml"), emit: versions

    when:
    !(metadata.ifEmpty())

    script:
    """
    Rscript ${projectDir}/bin/map.R \\
        ${deconvolution} \\
        ${metadata}

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
