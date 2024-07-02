process PRIMER_CHECK {
    tag "${meta.id}"
    label 'process_single'

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e:d3fff24ee1297b4c3bcef48354c2a30f0c82007a-0' :
        'biocontainers/mulled-v2-344874846f44224e5f0b7b741eacdddffe895d1e' }"

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