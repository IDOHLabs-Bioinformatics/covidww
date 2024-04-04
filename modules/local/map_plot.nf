process MAP_PLOT {
    tag "plot_all"
    label "process_low"

    input:
    path deconvolution
    path metadata
    val size

    output:
    path "*.png",                             emit: plot
    path "metadata_merged_demix_result.csv",  emit: dataframe
    path "versions.yml",                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    Rscript ${projectDir}/bin/map.R \\
        ${deconvolution} \\
        ${metadata} \\
        ${size}

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
