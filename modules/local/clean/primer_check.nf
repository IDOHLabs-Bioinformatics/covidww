process PRIMER_CHECK {
    tag "${meta.id}"
    label 'process_single'

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        ' https://depot.galaxyproject.org/singularity/bioframe:0.7.0--pyhdfd78af_0' :
        'biocontainers/bioframe:0.8.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(primer_data)
    path bed

    output:
    tuple val(meta), env(ratio), emit: ratio
    path "versions.yml",         emit: versions

    script:
    """
    total_primers=\$(wc -l ${bed} | cut -d ' ' -f 1)
    used_primers=\$(tail -n +9 ${primer_data} | awk -F '\t' '\$2 != 0 {print}' | wc -l)
    ratio=\$(awk "BEGIN {print \$used_primers/\$total_primers }")

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BASH: \$(echo \$BASH_VERSION)
    END_VERSIONS
    """

    stub:
    """
    ratio=\$(echo 0.70)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BASH: \$(echo \$BASH_VERSION)
    END_VERSIONS
    """
}