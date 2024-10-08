/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                      } from '../modules/nf-core/multiqc/main'
include { SUBSAMPLE                    } from '../modules/local/seqtk/subsample'
include { FASTP                        } from '../modules/nf-core/fastp/main'
include { BWAMEM2_INDEX		           } from '../modules/nf-core/bwamem2/index/main'
include { BWAMEM2_MEM		           } from '../modules/nf-core/bwamem2/mem/main'
include { SAMTOOLS_INDEX               } from '../modules/nf-core/samtools/index'
include { IVAR_TRIM                    } from '../modules/local/ivar/main'
include { PRIMER_CHECK                 } from '../modules/local/clean/primer_check.nf'
include { PRIMER_USAGE                 } from '../modules/local/primer_usage.nf'
include { SAMTOOLS_SORT                } from '../modules/nf-core/samtools/sort'
include { SAMTOOLS_STATS               } from '../modules/nf-core/samtools/stats'
include { FREYJA_VARIANTS              } from '../modules/nf-core/freyja/variants/main'
include { FREYJA_DEMIX                 } from '../modules/local/freyja/demix/main'
include { FREYJA_CLEAN                 } from '../modules/local/clean/freyja_clean'
include { SUMMARY                      } from '../modules/local/summary/summary'
include { MAP_PLOT                     } from '../modules/local/map_plot/map_plot'
include { paramsSummaryMap             } from 'plugin/nf-schema'
include { paramsSummaryMultiqc         } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML       } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText       } from '../subworkflows/local/utils_nfcore_covidww_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COVIDWW {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_reference   // channel: reference genome read in from --reference_genome
    ch_adapters    // channel: fasta file with additional adapters to trim read in from --adapter_fasta
    ch_primers     // channel: bed file with primers read in from --primers
    ch_metadata    // channel: metadata file read in from --metadata

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: Run BWAmem2 index
    //
    BWAMEM2_INDEX (
        Channel.of('reference_genome').combine(ch_reference)
    )

    //
    // MODULE: Run Seqtk
    //
    SUBSAMPLE(
        ch_samplesheet,
        params.subsampled_reads
    )

    //
    // MODULE: Run Fastp
    //
    FASTP (
        SUBSAMPLE.out.subsampled,
        ch_adapters.first(),
        params.save_trim_fail,
        params.save_merged
    )

    //
    // MODULE: Run BWAmem2 mem
    //
    BWAMEM2_MEM (
        FASTP.out.reads,
        BWAMEM2_INDEX.out.index.first(),
        params.sort_bam
    )

    //
    // MODULE: Index the bam file
    //
    SAMTOOLS_INDEX (
        BWAMEM2_MEM.out.bam
    )

    //
    // MODULE: Samtools stats
    //
    SAMTOOLS_STATS(
        BWAMEM2_MEM.out.bam.join(SAMTOOLS_INDEX.out.bai),
        Channel.of('reference_genome').combine(ch_reference).first()
    )

    //
    // MODULE: trim primers with iVar
    //
    IVAR_TRIM (
        BWAMEM2_MEM.out.bam.join(SAMTOOLS_INDEX.out.bai),
        ch_primers.first()
    )

    //
    // MODULE: primer check
    //
    PRIMER_CHECK (
        IVAR_TRIM.out.log,
        ch_primers.first()
    )

    // filter primer check by the threshold parameter
    PRIMER_CHECK.out.ratio.filter{it[1]
        .toFloat() >= params.primer_ratio}
        .set{ filtered } // this is the meta and ratio

    // collect samples that passed the primer check
    filtered.join(IVAR_TRIM.out.bam)
        .multiMap{ it ->
            meta: it[0]
            path: it[2]}
        .set { joined }
    joined.meta.merge(joined.path)
        .set { passed }

    //
    // MODULE: write failed
    //
    PRIMER_USAGE (
        PRIMER_CHECK.out.ratio.collect()
    )

    //
    // MODULE: samtools sort
    //
    SAMTOOLS_SORT (
        passed,
        Channel.of('reference_genome').combine(ch_reference).first()
    )

    //
    // MODULE: Freyja find variants
    //
    FREYJA_VARIANTS (
        SAMTOOLS_SORT.out.bam,
        ch_reference.first()
    )

    //
    // MODULE: Freyja demixing
    //
    FREYJA_DEMIX (
        FREYJA_VARIANTS.out.variants
    )

    //
    // MODULE: Freyja results cleaning
    //
    FREYJA_CLEAN (
        FREYJA_DEMIX.out.demix.collect()
    )

    //
    // MODULE: summary pie chart
    //
    SUMMARY (
        FREYJA_CLEAN.out.csv
    )

    //
    // MODULE: Plot results on a state map
    //
    if (params.metadata) {
        MAP_PLOT (
            FREYJA_CLEAN.out.csv,
            ch_metadata,
            params.radius
        )
    }

    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]}, SAMTOOLS_STATS.out.stats.collect{it[1]})
    if (params.metadata == '') {
        ch_versions = ch_versions.mix(SUBSAMPLE.out.versions, FASTP.out.versions, BWAMEM2_INDEX.out.versions,
                                  PRIMER_CHECK.out.versions, BWAMEM2_MEM.out.versions, SAMTOOLS_INDEX.out.versions,
                                  SAMTOOLS_STATS.out.versions, IVAR_TRIM.out.versions, SAMTOOLS_SORT.out.versions,
                                  FREYJA_VARIANTS.out.versions, FREYJA_DEMIX.out.versions, FREYJA_CLEAN.out.versions,
                                  SUMMARY.out.versions, MAP_PLOT.out.versions, PRIMER_USAGE.out.versions)
    } else {
        ch_versions = ch_versions.mix(SUBSAMPLE.out.versions, FASTP.out.versions, BWAMEM2_INDEX.out.versions,
                                  PRIMER_CHECK.out.versions, BWAMEM2_MEM.out.versions, SAMTOOLS_INDEX.out.versions,
                                  SAMTOOLS_STATS.out.versions, IVAR_TRIM.out.versions, SAMTOOLS_SORT.out.versions,
                                  FREYJA_VARIANTS.out.versions, FREYJA_DEMIX.out.versions, FREYJA_CLEAN.out.versions,
                                  SUMMARY.out.versions, MAP_PLOT.out.versions, PRIMER_USAGE.out.versions)
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'covidww_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
