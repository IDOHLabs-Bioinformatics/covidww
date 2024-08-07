process FREYJA_DEMIX {
    tag "${meta.id}"
    label "process_medium"

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/freyja:1.5.1--pyhdfd78af_1':
        'biocontainers/freyja:1.5.1--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(variants), path(depths)

    output:
    path("*demix.txt"),   emit: demix
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    freyja demix \\
        $args \\
        $variants \\
        $depths \\
        --output ${prefix}_demix.txt \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_demix.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
    END_VERSIONS
    """

}
