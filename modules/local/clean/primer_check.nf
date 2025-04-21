process PRIMER_CHECK {
    tag "${meta.id}"
    label 'process_single'

    if (workflow.profile.contains('conda')) {
        conda "${moduleDir}/environment.yml"
    } else {
        conda null
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-2076f4a3fb468a04063c9e6b7747a630abb457f6:fccb0c41a243c639e11dd1be7b74f563e624fcca-0' :
        'biocontainers/mulled-v2-2076f4a3fb468a04063c9e6b7747a630abb457f6:fccb0c41a243c639e11dd1be7b74f563e624fcca-0' }"

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