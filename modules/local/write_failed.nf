process WRITE_FAILED {
    tag "primer_content_failed"
    label "process_single"

    input:
    val(samples)

    output:
    path("primer_failed.csv"), emit: failed

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cleaned=\$(echo ${samples} | sed 's/\\[//g' | sed 's/\\]//g' | sed 's/,//g' )
    for variable in \$cleaned; do
      echo \$variable >> primer_failed.csv
    done


    """

    stub:
    """
    touch primer_failed.csv
    """
}